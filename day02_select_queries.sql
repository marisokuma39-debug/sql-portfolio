-- =============================================
-- DAY 2: SELECT Queries
-- Dataset: E-Commerce (ecommerce_db)
-- =============================================

-- Get all columns
SELECT * FROM customers;

-- Get specific columns only
SELECT first_name, last_name, city
FROM customers;

-- Rename columns with AS
SELECT 
  first_name AS 'First Name',
  last_name  AS 'Last Name',
  city       AS 'Customer City'
FROM customers;

-- Calculate discounted and tax prices
SELECT 
  product_name,
  price,
  price * 0.9  AS discounted_price,
  price * 1.2  AS price_with_tax
FROM products;

-- Unique countries only
SELECT DISTINCT country
FROM customers;

-- Combine first and last name
SELECT 
  CONCAT(first_name, ' ', last_name) AS full_name,
  email
FROM customers;

-- Unique order statuses
SELECT DISTINCT status
FROM orders;
```

Also update your **README.md** — change Day 2 from `[ ]` to `[x]`:
```
- [x] Day 2 — SELECT queries
