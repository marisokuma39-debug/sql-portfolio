-- =============================================
-- DAY 4: ORDER BY, LIMIT & OFFSET
-- Dataset: E-Commerce (ecommerce_db)
-- =============================================

-- Sort products cheapest first
SELECT product_name, price
FROM products
ORDER BY price ASC;

-- Sort products most expensive first
SELECT product_name, price
FROM products
ORDER BY price DESC;

-- Top 3 most expensive products
SELECT product_name, price
FROM products
ORDER BY price DESC
LIMIT 3;

-- Sort by category A-Z
SELECT product_name, category, price
FROM products
ORDER BY category ASC;

-- Sort by category A-Z, then price high-low within each category
SELECT product_name, category, price
FROM products
ORDER BY category ASC, price DESC;

-- Cheapest product in Electronics only
SELECT product_name, category, price
FROM products
WHERE category = 'Electronics'
ORDER BY price ASC
LIMIT 1;

-- Pagination: Page 1 (products 1-3)
SELECT product_name, price
FROM products
ORDER BY product_id ASC
LIMIT 3 OFFSET 0;

-- Pagination: Page 2 (products 4-6)
SELECT product_name, price
FROM products
ORDER BY product_id ASC
LIMIT 3 OFFSET 3 ;
