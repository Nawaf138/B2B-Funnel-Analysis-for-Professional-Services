-- جدول الشركات
CREATE TABLE companies (
    company_id      SERIAL PRIMARY KEY,
    company_name    TEXT,
    industry        TEXT,
    country         TEXT,
    created_at      DATE
);

-- جدول الأشخاص (contacts)
CREATE TABLE contacts (
    contact_id          SERIAL PRIMARY KEY,
    company_id          INT REFERENCES companies(company_id),
    name                TEXT,
    job_title           TEXT,
    is_decision_maker   BOOLEAN,
    influence_score     INT,
    last_contact_date   DATE
);

-- جدول التفاعلات (engagements)
CREATE TABLE engagements (
    engagement_id   SERIAL PRIMARY KEY,
    company_id      INT REFERENCES companies(company_id),
    engagement_type TEXT,
    engagement_date DATE
);

-- جدول الصفقات (deals)
CREATE TABLE deals (
    deal_id     SERIAL PRIMARY KEY,
    company_id  INT REFERENCES companies(company_id),
    stage       TEXT,
    amount      NUMERIC(12,2),
    updated_at  DATE
);

TRUNCATE companies, contacts, engagements, deals RESTART IDENTITY;

INSERT INTO companies (company_name, industry, country, created_at)
SELECT
    'Company ' || g,
    (ARRAY['Software','Logistics','Retail','Finance','Media','Healthcare'])[1 + (random()*5)::int],
    (ARRAY['Saudi Arabia','UAE','Kuwait','Qatar','Bahrain'])[1 + (random()*4)::int],
    DATE '2024-01-01' + (random()*90)::int
FROM generate_series(1, 1000) g;

INSERT INTO contacts (company_id, name, job_title, is_decision_maker, influence_score, last_contact_date)
SELECT
    c.company_id,
    'Contact ' || c.company_id,
    (ARRAY['CEO','CTO','Manager','Analyst','Engineer','Marketing Lead'])[1 + (random()*5)::int],
    (random() < 0.2),  -- 20% Decision Makers
    40 + (random()*60)::int,
    c.created_at + (random()*10)::int
FROM companies c;

DROP TABLE IF EXISTS journey;
select * from journey where to_won and to_contacted and to_engaged and to_qualified and to_negotiation and to_opportunity = TRUE
CREATE TABLE journey AS
SELECT
    company_id,
    created_at,
    (random() < 0.80) AS to_contacted,
    (random() < 0.60) AS to_engaged,
    (random() < 0.40) AS to_qualified,
    (random() < 0.15) AS to_opportunity,   -- التسريب الكبير هنا
    (random() < 0.10) AS to_negotiation,
    (random() < 0.8) AS to_won
FROM companies;

-- Contacted
INSERT INTO engagements (company_id, engagement_type, engagement_date)
SELECT company_id, 'contact', created_at + 2
FROM journey
WHERE to_contacted;

-- Engaged
INSERT INTO engagements (company_id, engagement_type, engagement_date)
SELECT company_id, 'meeting', created_at + 5
FROM journey
WHERE to_contacted AND to_engaged;

-- Qualified (demo)
INSERT INTO engagements (company_id, engagement_type, engagement_date)
SELECT company_id, 'demo', created_at + 10
FROM journey
WHERE to_contacted AND to_engaged AND to_qualified;

-- Deals
INSERT INTO deals (company_id, stage, amount, updated_at)
SELECT
    company_id,
    CASE
        WHEN to_won THEN 'Won'
        WHEN to_negotiation THEN 'Negotiation'
        WHEN to_opportunity THEN 'Opportunity'
        WHEN to_qualified THEN 'Qualified'
        ELSE NULL
    END,
    (5000 + random()*95000)::numeric(12,2),
    created_at + 20
FROM journey
WHERE to_qualified;

SELECT 
  (SELECT COUNT(*) FROM companies) AS companies,
  (SELECT COUNT(*) FROM contacts) AS contacts,
  (SELECT COUNT(*) FROM engagements) AS engagements,
  (SELECT COUNT(*) FROM deals) AS deals,
  (SELECT COUNT(*) FROM journey) AS journey;

--_______________________________AI DATASET______________________________________--

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

--_________________________________________________________________--

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