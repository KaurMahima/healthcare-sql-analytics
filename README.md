# Healthcare SQL Analytics

> End-to-end analytics pipeline for healthcare admissions data using DuckDB and SQL

---

## Project Overview

Comprehensive analysis of a healthcare dataset containing:
- 49,904 patient admissions across 5 years (2019-2024)
- 47,875 unique patients 
- 6 medical conditions: Arthritis, Asthma, Cancer, Diabetes, Hypertension, Obesity
- $1.28B total billing with 5 major insurance providers

**Tech Stack**: DuckDB • SQL • Python (data pipeline) • Kaggle API

---

## Analysis Overview

### 1. **Data Cleaning & Transformation**
- Column renaming (camelCase → snake_case)
- Text normalization (TRIM, UPPER, LOWER)
- Duplicate detection and removal (534 duplicates found)
- Data validation (negative billing, invalid dates)
- Age inconsistency correction using window functions
- Patient/visit ID generation (DENSE_RANK, ROW_NUMBER)

**Key Query**: [02_data_cleaning.sql](sql/02_data_cleaning.sql)

### 2. **Exploratory Analysis**
- **Demographic segmentation**: Top conditions by age/gender using `DENSE_RANK() OVER (PARTITION BY ... ORDER BY ...)`
- **Insurance payer analysis**: $771.9M concentrated in top 3 payers (90% of revenue)
- **Admission patterns**: 33% split across Emergency/Urgent/Elective types
- **Monthly trends**: 5-year time series with stable ~850 admissions/month
- **Comorbidity analysis**: 96.84% patients have single condition; 2.89% have 2 conditions

**Key Queries**: [03_exploratory_analysis.sql](sql/03_exploratory_analysis.sql)

### 3. **Advanced Analytics**
- **30-day readmission analysis**: 1.05% readmission rate using `LAG()` window function
- **Length of stay (LOS) patterns**: Avg 15.4-15.7 days across all conditions
- **Cost-per-day calculations**: ~$1,650/day across all admission types

**Key Queries**: [03_exploratory_analysis.sql](sql/03_exploratory_analysis.sql)


## Repository Structure

```
healthcare-sql-analytics/
├── scripts/
│   ├── download_data.py              # Kaggle API download script
│   └── create_db.py                  # DuckDB creation from CSV
├── sql/
│   ├── 01_sanity.sql                 # Initial data exploration
│   ├── 02_data_cleaning.sql          # Comprehensive data cleaning
│   └── 03_exploratory_analysis.sql   # 7 research questions with insights
├── environment.yml                   # Conda environment
└── README.md
```

---

## 🚀 Quick Start

### 1. **Setup Environment**
```bash
# Create conda environment
conda env create -f environment.yml
conda activate healthcare-analytics

# Configure Kaggle API
# Place kaggle.json in ~/.kaggle/ with your API credentials
```

### 2. **Download & Load Data**
```bash
# Download dataset from Kaggle
python scripts/download_data.py

# Create DuckDB database
python scripts/create_db.py
```

### 3. **Run SQL Queries**
```bash
# Sanity checks
duckdb data/processed/healthcare_data.duckdb < sql/01_sanity.sql

# Data cleaning pipeline
duckdb data/processed/healthcare_data.duckdb < sql/02_data_cleaning.sql

# Exploratory analysis
duckdb data/processed/healthcare_data.duckdb < sql/03_exploratory_analysis.sql
```

---

## 🔍 Key Findings

### 1. **Patient Demographics**
- **Working-age adults (18-44)**: 700+ cases per condition
  - Females: Diabetes & Arthritis dominate
  - Males: Asthma, Obesity, Arthritis lead
- **Seniors (75+)**: 
  - Females: Hypertension primary (726 cases)
  - Males: Arthritis primary (734 cases)

### 2. **Revenue Analysis**
- **Total billing**: $1.28B over 5 years
- **Average cost per admission**: $25,600
- **Payer concentration risk**: Top 3 insurers control 90% of revenue
- **Cost uniformity**: $25.5-25.7k avg across ALL payers

### 3. **Operational Metrics**
- **Balanced admission mix**: 33% Elective, 33% Urgent, 33% Emergency
- **Uniform LOS**: 15.4-15.6 days regardless of admission type
- **Low readmission rate**: 1.05% (501/47,875 patients) within 30 days
- **Monthly stability**: 789-911 admissions/month with zero seasonality

### 4. **Comorbidity Insights**
- **96.84%** of patients have **single condition**


## 📝 Dataset Details

**Source**: [Kaggle Healthcare Dataset](https://www.kaggle.com/datasets/prasad22/healthcare-dataset)

**Schema** (after cleaning):
- `patient_id` (INTEGER) - Unique patient identifier
- `visit_id` (INTEGER) - Sequential visit number per patient
- `age` (INTEGER) - Patient age
- `age_group` (VARCHAR) - Binned age (0-17, 18-29, ..., 75+)
- `gender` (VARCHAR) - Male/Female
- `blood_type` (VARCHAR) - A+, A-, B+, B-, AB+, AB-, O+, O-
- `medical_condition` (VARCHAR) - Primary diagnosis
- `date_of_admission` (DATE)
- `discharge_date` (DATE)
- `doctor` (VARCHAR)
- `hospital` (VARCHAR)
- `insurance_provider` (VARCHAR) - Medicare, Cigna, Blue Cross, UHC, Aetna
- `billing_amount` (DOUBLE) - Cost in USD
- `room_number` (VARCHAR)
- `admission_type` (VARCHAR) - Emergency, Urgent, Elective
- `medication` (VARCHAR)
- `test_results` (VARCHAR) - Normal, Abnormal, Inconclusive
