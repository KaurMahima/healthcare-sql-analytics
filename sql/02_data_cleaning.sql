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
SET name = UPPER(LEFT(name, 1)) || LOWER(SUBSTRING("Name", 2));

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
WITh total AS (
        SELECT count(*) as total_rows FROM healthcare_data
),
distincts AS (
        SELECT count(*) as distinct_rows FROM (SELECT distinct * FROM healthcare_data) t
)
SELECT total_rows, distinct_rows, total_rows - distinct_rows as  duplicate_rows 
FROM total, distincts; 

-- Drop duplciate rows 

BEGIN TRANSACTION;

CREATE TABLE healthcare_data_dedup AS 
SELECT DISTINCT *       
FROM healthcare_data;

DROP TABLE IF EXISTS healthcare_data;
ALTER TABLE healthcare_data_dedup RENAME TO healthcare_data;

COMMIT;

-- Drop rows where the billing amount is negative 
DELETE FROM healthcare_data 
WHERE billing_amount < 0

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
FROm grp 
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
FROm grp 
WHERE gender_variations > 1
ORDER BY gender_variations DESC, n_rows;

-- AGE INCONSISTENCY CORRECTION
-- =====================================================================
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








