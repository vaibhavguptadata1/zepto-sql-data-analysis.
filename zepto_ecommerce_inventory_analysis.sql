/*
Project: Zepto E-commerce Inventory Analysis
Database: SQL Server
Description:
End-to-end SQL data analysis project covering data ingestion,
validation, cleaning, and business-driven insights for an
e-commerce inventory dataset.
*/


-- Create database only if it does not exist
IF DB_ID('zepto_analysis') IS NULL
    CREATE DATABASE zepto_analysis;
GO

USE zepto_analysis;
GO

-- Drop table if it already exists (safe re-run)
IF OBJECT_ID('zepto', 'U') IS NOT NULL
    DROP TABLE zepto;
GO

-- Create final analysis table

CREATE TABLE zepto (
    sku_id INT IDENTITY(1,1) PRIMARY KEY,
    category VARCHAR(120),
    name VARCHAR(150) NOT NULL,
    mrp DECIMAL(10,2),
    discountPercent DECIMAL(5,2),
    availableQuantity INT,
    discountedSellingPrice DECIMAL(10,2),
    weightInGms INT,
    outOfStock BIT,
    quantity INT
);
-- Verify Table Creation

EXEC sp_help zepto;

-- Data move into zepto

INSERT INTO zepto (
    category,
    name,
    mrp,
    discountPercent,
    availableQuantity,
    discountedSellingPrice,
    weightInGms,
    outOfStock,
    quantity
)
SELECT
    category,
    name,
    mrp,
    discountPercent,
    availableQuantity,
    discountedSellingPrice,
    weightInGms,
    outOfStock,
    quantity
FROM zepto_v2;

--confirm Data is in Zepto
SELECT COUNT(*) AS total_rows
FROM zepto;

SELECT TOP 10 * 
FROM zepto;

--Drop zepto_v2
DROP TABLE zepto_v2;

-- Convert price values from paise to rupees
-- Purpose: Standardize pricing units for accurate business analysis
UPDATE zepto
SET
    mrp = mrp / 100.0,
    discountedSellingPrice = discountedSellingPrice / 100.0;

--Verify total number of records in final table
-- Purpose: Ensure data has been successfully moved into the final analysis table
SELECT COUNT(*) AS total_records
FROM zepto;

-- Preview sample records to validate column mapping and data readability
-- Purpose: Confirm that values are correctly populated in each column
SELECT TOP 10 *
FROM zepto;

-- Check for NULL values in critical business columns
-- Purpose: Identify missing data that could impact pricing and inventory analysis
SELECT *
FROM zepto
WHERE
    category IS NULL
    OR name IS NULL
    OR mrp IS NULL
    OR discountPercent IS NULL
    OR discountedSellingPrice IS NULL
    OR availableQuantity IS NULL;

-- Check for NULL values in inventory-related columns
-- Purpose: Ensure inventory, stock status, and quantity data are complete
SELECT *
FROM zepto
WHERE
    weightInGms IS NULL
    OR outOfStock IS NULL
    OR quantity IS NULL;

-- Check stock status consistency with available quantity
-- Purpose: Ensure out-of-stock flag aligns with inventory quantity
SELECT *
FROM zepto
WHERE
    (outOfStock = 1 AND availableQuantity > 0)
    OR (outOfStock = 0 AND availableQuantity = 0);

-- Check for invalid pricing logic
-- Purpose: Ensure discounted selling price is not greater than MRP
SELECT *
FROM zepto
WHERE discountedSellingPrice > mrp;

-- Check for zero or negative price values
-- Purpose: Identify invalid pricing records that must be cleaned before analysis
SELECT *
FROM zepto
WHERE
    mrp <= 0
    OR discountedSellingPrice <= 0;

-- Remove records with invalid pricing
-- Purpose: Eliminate zero-priced products that distort analysis
DELETE FROM zepto
WHERE mrp <= 0
   OR discountedSellingPrice <= 0;

-- Re-check for zero or negative price values after cleaning
SELECT *
FROM zepto
WHERE
    mrp <= 0
    OR discountedSellingPrice <= 0;

-- Check for products appearing multiple times (multiple SKUs)
-- Purpose: Identify duplicate product names listed under different SKUs
SELECT
    name,
    COUNT(*) AS sku_count
FROM zepto
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY sku_count DESC;

-- Check distribution of products across categories
-- Purpose: Understand which categories have the highest number of SKUs
SELECT
    category,
    COUNT(*) AS product_count
FROM zepto
GROUP BY category
ORDER BY product_count DESC;

-- Check in-stock vs out-of-stock product distribution
-- Purpose: Understand overall inventory availability status
SELECT
    outOfStock,
    COUNT(*) AS product_count
FROM zepto
GROUP BY outOfStock;

-- Identify high-priced products that are currently out of stock
-- Purpose: Highlight potential revenue loss opportunities
SELECT
    name,
    mrp
FROM zepto
WHERE outOfStock = 1
  AND mrp > 300
ORDER BY mrp DESC;


-- Verify price conversion from paise to rupees
-- Purpose: Ensure pricing values are now in readable rupee format
SELECT
    name,
    mrp,
    discountedSellingPrice
FROM zepto
ORDER BY mrp DESC;

-- Validate discount percentage against MRP and discounted selling price
-- Purpose: Ensure discountPercent aligns with actual price difference
SELECT
    name,
    mrp,
    discountedSellingPrice,
    discountPercent,
    ROUND(((mrp - discountedSellingPrice) / mrp) * 100, 2) AS calculated_discount_percent
FROM zepto
WHERE mrp > 0
ORDER BY ABS(discountPercent - ((mrp - discountedSellingPrice) / mrp) * 100) DESC;

-- Data Analysis

-- Q1: Identify top 10 products offering the highest discounts
-- Purpose: Highlight products with maximum discount to understand value perception and promotion opportunities
SELECT TOP 10
    name,
    mrp,
    discountedSellingPrice,
    discountPercent
FROM zepto
GROUP BY name, mrp, discountedSellingPrice, discountPercent
ORDER BY discountPercent DESC;
-- Q2: Identify categories generating the highest estimated revenue
-- Purpose: Understand which product categories contribute most to overall revenue
WITH category_revenue AS (
    SELECT
        category,
        SUM(discountedSellingPrice * availableQuantity) AS total_revenue
    FROM zepto
    GROUP BY category
)
SELECT
    category,
    total_revenue
FROM category_revenue
ORDER BY total_revenue DESC;

-- Q3: Identify high-MRP products that are currently out of stock
-- Purpose: Highlight potential revenue loss opportunities due to unavailable expensive products
SELECT
    name,
    mrp
FROM zepto
WHERE outOfStock = 1
  AND mrp > 300
ORDER BY mrp DESC;

-- Q4: Calculate the average discount offered by each category
-- Purpose: Understand discounting strategy across different product categories
SELECT
    category,
    ROUND(AVG(discountPercent), 2) AS avg_discount_percent
FROM zepto
GROUP BY category
ORDER BY avg_discount_percent DESC;

-- Q5: Identify products offering better-than-average value for money
-- Purpose: Find products whose price per gram is lower than the overall average
SELECT
    name,
    weightInGms,
    discountedSellingPrice,
    ROUND(discountedSellingPrice / weightInGms, 4) AS price_per_gram
FROM zepto
WHERE weightInGms > 0
  AND (discountedSellingPrice / weightInGms) < (
        SELECT AVG(discountedSellingPrice * 1.0 / weightInGms)
        FROM zepto
        WHERE weightInGms > 0
      )
ORDER BY price_per_gram ASC;

-- Q6: Calculate total inventory weight by category
-- Purpose: Understand inventory volume distribution for logistics and supply planning
SELECT
    category,
    SUM(weightInGms * availableQuantity) AS total_inventory_weight_gms
FROM zepto
GROUP BY category
ORDER BY total_inventory_weight_gms DESC;

-- Q7: Identify categories with the highest out-of-stock rate
-- Purpose: Detect supply chain or demand-forecasting issues by category
WITH stock_status AS (
    SELECT
        category,
        COUNT(*) AS total_products,
        SUM(CASE WHEN outOfStock = 1 THEN 1 ELSE 0 END) AS out_of_stock_products
    FROM zepto
    GROUP BY category
)
SELECT
    category,
    total_products,
    out_of_stock_products,
    ROUND((out_of_stock_products * 100.0) / total_products, 2) AS out_of_stock_rate_percent
FROM stock_status
ORDER BY out_of_stock_rate_percent DESC;

-- Q8: Identify top revenue-generating products within each category
-- Purpose: Highlight key SKUs that drive maximum revenue using ranking logic
WITH ranked_products AS (
    SELECT
        category,
        name,
        discountedSellingPrice * availableQuantity AS revenue,
        DENSE_RANK() OVER (
            PARTITION BY category
            ORDER BY discountedSellingPrice * availableQuantity DESC
        ) AS revenue_rank
    FROM zepto
)
SELECT
    category,
    name,
    revenue,
    revenue_rank
FROM ranked_products
WHERE revenue_rank <= 3
ORDER BY category, revenue_rank;

-- Q9: Identify expensive products with minimal discounts
-- Purpose: Highlight pricing optimization opportunities for high-MRP products
SELECT
    name,
    mrp,
    discountPercent
FROM zepto
WHERE mrp > 500
  AND discountPercent < 10
ORDER BY mrp DESC;

-- Q10: Categorize products based on weight buckets
-- Purpose: Analyze product mix from a packaging and logistics perspective
SELECT
    name,
    weightInGms,
    CASE
        WHEN weightInGms < 1000 THEN 'Low Weight'
        WHEN weightInGms BETWEEN 1000 AND 5000 THEN 'Medium Weight'
        ELSE 'Bulk Weight'
    END AS weight_category
FROM zepto;

-- End of analysis
-- This project demonstrates SQL data cleaning, validation,
-- and business analysis skills using real-world e-commerce data.
