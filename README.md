# Zepto E-commerce Inventory SQL Analysis

This project is an end-to-end SQL data analysis project based on a real-world
e-commerce inventory dataset scraped from Zepto.

The objective of this project is to simulate how data analysts work with
raw inventory data — from data ingestion and validation to data cleaning
and business-driven analysis.

---

## Tools Used
- SQL Server
- SQL Server Management Studio (SSMS)

---

## Dataset
- Source: Kaggle (Zepto Inventory Dataset)
- Each row represents a unique SKU
- Same product names may appear multiple times due to different weights,
  package sizes, or pricing variations

---

## Project Workflow

### 1. Database & Table Setup
- Created a dedicated SQL Server database
- Designed a structured inventory table with appropriate data types
- Ensured the SQL script is safe to re-run

### 2. Data Ingestion
- Imported raw CSV data into a staging table
- Transferred data into a final analysis-ready table

### 3. Data Validation & Cleaning
Performed multiple data quality checks, including:
- NULL value checks
- Pricing logic validation
- Stock status consistency checks
- Removal of invalid price records
- Conversion of prices from paise to rupees

### 4. Exploratory Data Analysis (EDA)
- Category distribution analysis
- In-stock vs out-of-stock product analysis
- Identification of duplicate SKUs

### 5. Business Analysis
Answered key business questions using SQL, including:
- Top discounted products
- Revenue by category
- High-MRP out-of-stock products
- Average discount by category
- Best value-for-money products
- Inventory weight distribution
- Category-level out-of-stock rates
- Top revenue-generating products

---

## Key SQL Concepts Used
- Aggregations (`SUM`, `AVG`, `COUNT`)
- Common Table Expressions (CTEs)
- Subqueries
- Window Functions (`DENSE_RANK`)
- Conditional logic (`CASE` statements)

---

## Disclaimer
This project was completed as a learning and portfolio exercise using
publicly available data. It is not an official project by Zepto.
