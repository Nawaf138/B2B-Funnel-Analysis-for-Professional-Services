CREATE OR REPLACE VIEW funnel_view AS
WITH company_features AS (
    SELECT
        c.company_id,
        c.company_name,
        c.industry,
        c.country,
        c.created_at,
        MAX(CASE WHEN ct.last_contact_date IS NOT NULL THEN 1 ELSE 0 END) AS has_contact,
        MAX(CASE WHEN ct.is_decision_maker = TRUE THEN 1 ELSE 0 END) AS has_decision_maker,
        MAX(ct.influence_score) AS max_influence_score,
        MAX(CASE WHEN e.engagement_id IS NOT NULL THEN 1 ELSE 0 END) AS has_engagement,
        MAX(CASE WHEN d.deal_id IS NOT NULL THEN 1 ELSE 0 END) AS has_deal,
        MAX(d.stage) AS deal_stage
    FROM companies c
    LEFT JOIN contacts ct ON ct.company_id = c.company_id
    LEFT JOIN engagements e ON e.company_id = c.company_id
    LEFT JOIN deals d ON d.company_id = c.company_id
    GROUP BY c.company_id
),
company_stage AS (
    SELECT
        *,
        CASE
            WHEN COALESCE(deal_stage, '') = 'Won' THEN 'Won'
            WHEN COALESCE(deal_stage, '') = 'Lost' THEN 'Lost'
            WHEN COALESCE(deal_stage, '') = 'Negotiation' THEN 'Negotiation'
            WHEN COALESCE(deal_stage, '') = 'Opportunity' THEN 'Opportunity'
            WHEN has_deal = 1 THEN 'Qualified'
            WHEN has_decision_maker = 1 AND has_engagement = 1 THEN 'Qualified'
            WHEN has_engagement = 1 THEN 'Engaged'
            WHEN has_contact = 1 THEN 'Contacted'
            ELSE 'Lead'
        END AS stage
    FROM company_features
)
SELECT
    company_id,
    company_name,
    industry,
    country,
    stage
FROM company_stage;

--________________________CTE_____________________________--

WITH base AS (
    SELECT
        COUNT(*) AS total_leads,

        COUNT(*) FILTER (
            WHERE to_contacted
        ) AS contacted,

        COUNT(*) FILTER (
            WHERE to_contacted
              AND to_engaged
        ) AS engaged,

        COUNT(*) FILTER (
            WHERE to_contacted
              AND to_engaged
              AND to_qualified
        ) AS qualified,

        COUNT(*) FILTER (
            WHERE to_contacted
              AND to_engaged
              AND to_qualified
              AND to_opportunity
        ) AS opportunity,

        COUNT(*) FILTER (
            WHERE to_contacted
              AND to_engaged
              AND to_qualified
              AND to_opportunity
              AND to_negotiation
        ) AS negotiation,

        COUNT(*) FILTER (
            WHERE to_contacted
              AND to_engaged
              AND to_qualified
              AND to_opportunity
              AND to_negotiation
              AND to_won
        ) AS won
    FROM journey
)
SELECT
    step,
    reached,
    ROUND(reached::numeric / total_leads * 100, 2) AS cumulative_conversion
FROM base,
LATERAL (
    VALUES
        ('Lead', total_leads),
        ('Contacted', contacted),
        ('Engaged', engaged),
        ('Qualified', qualified),
        ('Opportunity', opportunity),
        ('Negotiation', negotiation),
        ('Won', won)

) AS funnel(step, reached);
