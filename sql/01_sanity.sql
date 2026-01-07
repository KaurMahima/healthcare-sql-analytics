-- See what we have 
SHOW TABLES;

-- Check schema of a table
DESCRIBE healthcare_data;

-- Preview data 
SELECT * FROM healthcare_data LIMIT 10;

-- Quick min/max of dates 
SELECT MIN("Date of Admission") AS min_admission,
       MAX("Date of Admission") AS max_admission, 
       MIN("Discharge Date") AS min_discharge, 
       MAX("Discharge Date") AS max_discharge
FROM healthcare_data;

-- Distinct value counts for key categorical variables 
-- Gender 
SELECT "Gender", count(*) as n 
FROM healthcare_data 
GROUP BY 1 
ORDER BY n DESC; 

-- Admission type 
SELECT "Admission Type", count(*) as n 
FROM healthcare_data
GROUP BY 1
ORDER BY n desc;

-- Blood Type 
SELECT "Blood Type", COUNT(*) AS n
FROM healthcare_data
GROUP BY 1
ORDER BY n DESC;

--Test results 
SELECT "Test Results", COUNT(*) AS n
FROM healthcare_data
GROUP BY 1
ORDER BY n DESC;

-- Null and blank checks 
SELECT 
        SUM("Name" IS NULL OR TRIM("Name") = '') AS null_name,
        SUM("Age" IS NULL) AS null_age,
        SUM("Gender" IS NULL OR TRIM("Gender")='') AS null_or_blank_gender,
        SUM("Hospital" IS NULL OR TRIM("Hospital")='') AS null_or_blank_hospital,
        SUM("Billing Amount" IS NULL)            AS null_billing,
        SUM("Date of Admission" IS NULL)         AS null_admit,
        SUM("Discharge Date" IS NULL)            AS null_discharge
FROM healthcare_data;

