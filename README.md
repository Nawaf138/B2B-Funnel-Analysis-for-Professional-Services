# B2B Funnel Analysis for Professional Services

## Executive Summary

This project analyzes the sales funnel of a B2B professional services company to identify conversion issues, measure funnel performance, and highlight opportunities for improvement. Using SQL and Power BI, the data was extracted, cleaned, modeled, and visualized to track lead progression across seven funnel stages. The analysis revealed a major drop-off between Contacted → Engaged and a final win rate of only 0.40%, indicating significant room for optimization.
Note: All data used in this project is synthetic and created solely for learning and demonstration purposes.


## Business Problem

Despite high lead volume, the company struggled to convert prospects into closed deals. Stakeholders needed clarity on where leads were dropping off and which stages or industries offered the highest potential for improvement. The goal was to build a transparent, data-driven view of the funnel to support better decision-making.

## Methodology

- SQL used to extract, clean, and transform CRM journey data
- Power BI used to model the funnel and build an executive dashboard
- DAX measures created to calculate KPIs such as win rate, pipeline value, and drop-off
- Industry segmentation added to identify high-performing sectors

## Skills

SQL: View, CTEs, joins, CASE logic, aggregation
Power BI: DAX, data modeling, ETL, KPI design, funnel visualization
Business Analysis: Funnel diagnostics, conversion modeling, drop-off analysis

### Why I Used Both a View and a CTE?
The View is used to store the business logic that assigns each company to the correct funnel stage. It’s reusable, consistent, and acts as a clean data layer for the dashboard.

The CTE is used for temporary calculations like counting leads per stage and computing conversion rates. These metrics don’t need to be stored permanently, so a CTE keeps the query simple and efficient.

## Results & Recommendations

### Key findings from the dashboard:

- Largest drop-off: Contacted → Engaged (310 leads lost, 39%)
- Final win rate: 0.40%
- Pipeline value: 857K
- Highest win potential in Healthcare, Retail, and Software sectors

  
### Recommended actions:

- Improve lead quality and filtering
- Automate follow-ups to reduce early-stage drop-off
- Focus sales efforts on industries with higher conversion potential
- Use weighted forecasting to avoid inflated revenue expectations

## Next Steps

- Implement lead scoring
- A/B test engagement messaging
- Track conversion rates monthly
