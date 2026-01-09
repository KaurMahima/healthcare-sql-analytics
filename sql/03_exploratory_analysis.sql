-- =====================================================================
-- 03_EXPLORATORY_ANALYSIS.SQL
-- =====================================================================

-- Let's first explore and answer questions related to patient behaviour and risk and gain some clinical insights 

-- RESEARCH QUESTION 1: Demographic health patterns
-- How do conditions vary by age and gender?

-- RESEARCH QUESTION 1: Demographic health patterns
-- How do conditions vary by age and gender and find the top condition required treatment for each age group?

WITH condition_stats AS (
        SELECT 
                age_group,
                gender,
                medical_condition,
                COUNT(*) as cases,
                COUNT(DISTINCT patient_id) AS patients,
                ROUND(AVG(billing_amount),2) as avg_cost,
                ROUND(AVG(DATEDIFF('day', date_of_admission, discharge_date)),1) AS avg_los_days,
                DENSE_RANK() OVER (PARTITION BY age_group, gender ORDER BY COUNT(*) DESC) AS condition_rank
        FROM healthcare_data
        GROUP BY  age_group, gender, medical_condition
)
SELECT 
        age_group,
        gender,
        medical_condition,
        cases,
        patients,
        avg_cost,
        avg_los_days
FROM condition_stats
WHERE condition_rank = 1
ORDER BY age_group, gender, cases DESC;

-- INSIGHTS:
-- PEDIATRIC (0-17): Minimal volume (4-7 cases per gender). Diabetes/Cancer dominate.
-- WORKING-AGE (18-44): High-volume cohort (700+ cases per gender per condition). Diabetes & Arthritis 
--   lead for females; Asthma/Obesity/Arthritis for males. Cost per case ~$25-26k, LOS ~15.2 days.
--   Opportunity: Preventive programs for arthritis (avoid future escalation) and diabetes management.
-- MIDDLE-AGE (45-59): 900+ cases per condition. Obesity dominates females; Hypertension for males.
--   Cost-per-LOS stable (~$1,660/day). Business implication: Volume-driven revenue; standardized 
--   care protocols essential for margin improvement.
-- SENIOR (60-74): 900-950 cases. Arthritis/Hypertension/Cancer prominent. At risk for high readmission
--   (chronic conditions). Recommend geriatric care coordination programs to reduce repeat admissions.
-- ELDERLY (75+): 700+ cases. Hypertension (F) and Arthritis (M) as primary. Avg cost $25-26k but 
--   needs investigation: LOS ~15.7 days suggests high acuity. Resource planning: Dedicated geriatric 
--   units, fall-prevention protocols, and post-discharge outreach critical.


-- RESEARCH QUESTION 2: Insurance provider breakdown 
-- Which insurers drive the most revenue and what are their claim patterns?
SELECT 
        insurance_provider,
        COUNT(*) as claims_processed,
        ROUND(AVG(billing_amount),2) AS avg_billing_amount,
        ROUND(SUM(billing_amount),2) AS total_billing_amount,
        ROUND(MIN(billing_amount),2) AS min_billing_amount,
        ROUND(MAX(billing_amount),2) AS max_billing_amount
FROM healthcare_data
GROUP BY insurance_provider
ORDER BY total_billing_amount DESC;

-- INSIGHTS:
-- MARKET CONCENTRATION: Top 3 payers (Medicare, Cigna, Blue Cross) = ~$771.9M (~90% of total revenue).
--   Risk exposure: Over-reliance on 3 payers; losing one could impact revenue by ~$85-258M.
--   Mitigation: Diversify payer contracts; strengthen relationships with secondary payers (Aetna, UnitedHealthcare).
-- BILLING UNIFORMITY: Avg claim tightly clustered ($25.5-25.7k) across all payers—suggests standardized 
--   case mix and reimbursement rates. Zero pricing power detected; negotiate from volume/quality angle.
-- EXTREME OUTLIERS: Min $9-91 (billing errors?) and max $52k+ (high-acuity cases) indicate:
--   (a) Data quality issues—investigate sub-$100 claims for denials/write-offs
--   (b) Complex cases—analyze $50k+ claims for cost drivers (condition, LOS, complications)
-- VOLUME PARITY: Claims distributed evenly (9,826-10,069 per payer). No payer concentrates high-value cases,
--   suggesting fair/equitable case distribution. Opportunity: Negotiate volume discounts with smaller payers.
-- FINANCIAL IMPACT: $1.28B total billing across ~50k claims = $25.6k avg. Focus on:
--   • Claim denial analysis (min claims)
--   • High-acuity case management ($50k+)
--   • Payer-specific contract optimization (Medicare margin vs. Cigna margin)
