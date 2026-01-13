-- =====================================================================
-- 02_DATA_CLEANING.SQL
-- =====================================================================

-- Create backup data before any modifications 
CREATE TABLE IF NOT EXISTS healthcare_data_backup AS
SELECT * FROM healthcare_data;

PRAGMA table_info(healthcare_data_backup);
SELECT count(*) as backup_row_count FROM healthcare_data_backup;

-- critical issue found:
-- improper name casing 
-- white spaces in the variables name 
-- duplicate patient record 
-- the dataset does not contain patient id 
-- negative billing amount (108 records)
-- add event/visit id information 

-- ============================================
-- STEP 2: DATA CLEANING OPERATIONS
-- ============================================

-- Rename all columns to snake_case
ALTER TABLE healthcare_data RENAME COLUMN "Name" TO name;
ALTER TABLE healthcare_data RENAME COLUMN "Age" TO age;
ALTER TABLE healthcare_data RENAME COLUMN "Gender" TO gender;
ALTER TABLE healthcare_data RENAME COLUMN "Blood Type" TO blood_type;
ALTER TABLE healthcare_data RENAME COLUMN "Medical Condition" TO medical_condition;
ALTER TABLE healthcare_data RENAME COLUMN "Date of Admission" TO date_of_admission;
ALTER TABLE healthcare_data RENAME COLUMN "Doctor" TO doctor;
ALTER TABLE healthcare_data RENAME COLUMN "Hospital" TO hospital;
ALTER TABLE healthcare_data RENAME COLUMN "Insurance Provider" TO insurance_provider;
ALTER TABLE healthcare_data RENAME COLUMN "Billing Amount" TO billing_amount;
ALTER TABLE healthcare_data RENAME COLUMN "Room Number" TO room_number;
ALTER TABLE healthcare_data RENAME COLUMN "Admission Type" TO admission_type;
ALTER TABLE healthcare_data RENAME COLUMN "Discharge Date" TO discharge_date;
ALTER TABLE healthcare_data RENAME COLUMN "Medication" TO medication;
ALTER TABLE healthcare_data RENAME COLUMN "Test Results" TO test_results;

-- Trim white spaces if any 
UPDATE healthcare_data
SET name = TRIM(name),
    gender = TRIM(gender),
    blood_type = TRIM(blood_type),
    medical_condition = TRIM(medical_condition),
    doctor = TRIM(doctor),
    hospital = TRIM(hospital),
    insurance_provider = TRIM(insurance_provider),
    admission_type = TRIM(admission_type),
    medication = TRIM(medication),
    test_results = TRIM(test_results);

-- Update the name column to Proper case (just the first given name in caps)
UPDATE healthcare_data 
SET name = UPPER(LEFT(name, 1)) || LOWER(SUBSTRING(name, 2));

-- Validate the proper name casing cleaning query 
SELECT name
FROM healthcare_data 
LIMIT 10;

-- Duplicates count check 
SELECT COUNT(*) AS dup_count
FROM (
        SELECT COUNT(*) as cnt
        FROM healthcare_data 
        GROUP BY name, age, gender, blood_type, medical_condition, date_of_admission,
    doctor, hospital, insurance_provider, billing_amount, room_number,
    admission_type, discharge_date, medication, test_results
    HAVING COUNT(*) > 1) d ;

-- Another query to check the duplicate rows 
WITH total AS (
        SELECT count(*) as total_rows FROM healthcare_data
),
distincts AS (
        SELECT count(*) as distinct_rows FROM (SELECT distinct * FROM healthcare_data) t
)
SELECT total_rows, distinct_rows, total_rows - distinct_rows as  duplicate_rows 
FROM total, distincts; 

-- Drop duplicate rows 

BEGIN TRANSACTION;

CREATE TABLE healthcare_data_dedup AS 
SELECT DISTINCT *       
FROM healthcare_data;

DROP TABLE IF EXISTS healthcare_data;
ALTER TABLE healthcare_data_dedup RENAME TO healthcare_data;

COMMIT;

-- Drop rows where the billing amount is negative 
DELETE FROM healthcare_data 
WHERE billing_amount < 0;

-- Health data sometimes have same records but the identifiers like gender and age might be different 
WITH grp AS (
        SELECT 
        name, gender, blood_type, medical_condition, date_of_admission,
        doctor, hospital, insurance_provider, billing_amount, room_number,
        admission_type, discharge_date, medication, test_results,
        COUNT(DISTINCT age ) AS age_variations,
        MIN(age) AS min_age,
        MAX(age) AS max_age,
        COUNT(*) AS n_rows 
    FROM healthcare_data  
    GROUP BY ALL 
)
SELECT * 
FROM grp 
WHERE age_variations > 1
ORDER BY age_variations DESC, n_rows;

-- check for gender as well 
WITH grp AS (
        SELECT 
        name, age, blood_type, medical_condition, date_of_admission,
        doctor, hospital, insurance_provider, billing_amount, room_number,
        admission_type, discharge_date, medication, test_results,
        COUNT(DISTINCT gender) AS gender_variations,
        COUNT(*) AS n_rows 
    FROM healthcare_data  
    GROUP BY ALL 
)
SELECT * 
FROM grp 
WHERE gender_variations > 1
ORDER BY gender_variations DESC, n_rows;

-- AGE INCONSISTENCY CORRECTION 
-- ISSUE IDENTIFIED: 
-- - Same patient records (identical name, admission date, hospital, etc.) 
--   have different age values
-- - ~4,956 rows affected with age variations
--
-- DETECTION METHOD:
-- - Grouped records by all fields EXCEPT age
-- - Counted DISTINCT age values per group
-- - Found groups where COUNT(DISTINCT age) > 1
-- - This indicates the same record appears with multiple different ages
--
-- ROOT CAUSE:
-- - Likely data entry errors or system inconsistencies
-- - Same visit/record entered multiple times with different ages
--
-- SOLUTION IMPLEMENTED:
-- - Calculate baseline age from patient's first admission date
-- - For all visits: age = baseline_age + years_elapsed since first visit
-- - This standardizes ages chronologically across all patient visits
-- - Apply DISTINCT to remove exact duplicates created by standardization

-- Fix age query 

BEGIN TRANSACTION;

CREATE TABLE healthcare_data_age_fixed AS 
WITH ordered_visits AS (
        SELECT 
                *,
                FIRST_VALUE(age) OVER(PARTITION BY name ORDER BY date_of_admission) AS baseline_age,
                FIRST_VALUE(date_of_admission) OVER(PARTITION BY name ORDER BY date_of_admission) AS baseline_date,
                DATEDIFF('year',
                        FIRST_VALUE(date_of_admission) OVER(PARTITION BY name ORDER BY date_of_admission),
                        date_of_admission) AS years_elapsed
        FROM healthcare_data
),
age_corrected AS (
        SELECT 
                * EXCLUDE(baseline_age, baseline_date, years_elapsed, age),
                baseline_age + years_elapsed AS age
        FROM ordered_visits
)
SELECT DISTINCT * -- drop any duplicates after fixing age 
FROM age_corrected;

SELECT COUNT(*) AS rows_before FROM healthcare_data;
SELECT COUNT(*) AS rows_after FROM healthcare_data_age_fixed;

DROP TABLE healthcare_data;
ALTER TABLE healthcare_data_age_fixed RENAME TO healthcare_data;

COMMIT;

-- Confirm there is no backwards age 
WITH ordered_visits AS (
        SELECT 
                name, 
                date_of_admission,
                age,
                LAG(age) OVER (PARTITION BY name ORDER BY date_of_admission) AS previous_age
        FROM healthcare_data
)
SELECT COUNT(*) as backwards_age_count
FROM ordered_visits
WHERE previous_age IS NOT NULL AND age < previous_age;


-- CREATE PATIENT IDs AND VISIT IDs

-- RATIONALE:
-- - No existing patient identifiers in the dataset
-- - patient_id: Unique identifier for each patient
-- - visit_id: Sequential visit number per patient (chronological)
--
-- LOGIC:
-- - patient_id: Based on unique name + blood_type combination
-- - visit_id: ROW_NUMBER per patient ordered by admission date

-- Add columns 
ALTER TABLE healthcare_data ADD COLUMN patient_id INTEGER;
ALTER TABLE healthcare_data ADD COLUMN visit_id INTEGER;

-- Create patient ids 
WITH unique_patients AS (
        SELECT DISTINCT name, blood_type,
                DENSE_RANK() OVER (ORDER BY name, blood_type) as patient_id
        FROM healthcare_data 
)
UPDATE healthcare_data h
SET patient_id = up.patient_id 
FROM unique_patients up 
WHERE h.name = up.name AND h.blood_type = up.blood_type;

-- Create visit_ids 
WITH visit_numbers AS (
        SELECT name, blood_type, date_of_admission,
        ROW_NUMBER() OVER (PARTITION BY name, blood_type ORDER BY date_of_admission ASC) AS visit_num
        FROM healthcare_data
)
UPDATE healthcare_data h 
SET visit_id = vn.visit_num 
FROM visit_numbers vn 
WHERE h.name = vn.name
  AND h.blood_type = vn.blood_type
  AND h.date_of_admission = vn.date_of_admission;

-- Validate the results 
SELECT 
        COUNT(DISTINCT patient_id) AS unique_patients,
        COUNT(*) AS total_rows,
        ROUND(COUNT(*) * 1.0/COUNT(DISTINCT patient_id),2) AS avg_visits_per_patient,
        MAX(visit_id) AS max_visits_by_one_patient
FROM healthcare_data;

-- Create age_group column for downstream analysis
ALTER TABLE healthcare_data ADD COLUMN IF NOT EXISTS age_group VARCHAR;

UPDATE healthcare_data
SET age_group = CASE 
        WHEN age < 18 THEN '0-17'
        WHEN age < 30 THEN '18-29'
        WHEN age < 45 THEN '30-44'
        WHEN age < 60 THEN '45-59'
        WHEN age < 75 THEN '60-74'
        ELSE '75+' 
    END;

-- Preview results 
SELECT patient_id, visit_id, name, blood_type, date_of_admission, age_group
FROM healthcare_data
WHERE patient_id <= 5
ORDER BY patient_id, visit_id, age_group;









