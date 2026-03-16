-- =============================================
-- DAY 3: WHERE Clause — Filtering Data
-- Dataset: E-Commerce (ecommerce_db)
-- =============================================

-- Filter by exact text match
SELECT * FROM customers
WHERE country = 'USA';

-- Filter by number
SELECT product_name, price
FROM products
WHERE price > 100;

-- AND — both conditions must be true
SELECT first_name, last_name, country, age
FROM customers
WHERE country = 'USA' AND age < 30;

-- OR — either condition can be true
SELECT first_name, last_name, country
FROM customers
WHERE country = 'USA' OR country = 'UK';

-- BETWEEN — range of values
SELECT product_name, price
FROM products
WHERE price BETWEEN 30 AND 150;

-- IN — multiple values
SELECT first_name, last_name, country
FROM customers
WHERE country IN ('USA', 'UK', 'Canada');

-- LIKE — pattern matching (ends with)
SELECT first_name, email
FROM customers
WHERE email LIKE '%@email.com';

-- LIKE — starts with A
SELECT first_name, email
FROM customers
WHERE first_name LIKE 'A%';

-- IS NULL — find missing data
SELECT product_name, supplier_id
FROM products
WHERE supplier_id IS NULL;

-- IS NOT NULL — find complete data
SELECT product_name, supplier_id
FROM products
WHERE supplier_id IS NOT NULL;

-- MY FIRST HEALTHCARE QUERY!
-- Find patients with diabetes or hypertension
-- SELECT first_name, last_name, diagnosis
-- FROM patients
-- WHERE diagnosis IN ('Diabetes', 'Hypertension');
