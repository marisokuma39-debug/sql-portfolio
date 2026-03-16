-- =============================================
-- DAY 5: Aggregate Functions & GROUP BY
-- Dataset: E-Commerce (ecommerce_db)
-- =============================================

-- COUNT: total customers
SELECT COUNT(*) AS total_customers
FROM customers;

-- SUM: total stock value
SELECT SUM(price * stock_qty) AS total_stock_value
FROM products;

-- AVG: average product price
SELECT AVG(price) AS average_price
FROM products;

-- MIN and MAX together
SELECT 
  MIN(price) AS cheapest_price,
  MAX(price) AS most_expensive_price
FROM products;

-- GROUP BY: products per category
SELECT 
  category,
  COUNT(*) AS num_products,
  AVG(price) AS avg_price
FROM products
GROUP BY category;

-- GROUP BY with ORDER BY
SELECT 
  category,
  COUNT(*) AS num_products
FROM products
GROUP BY category
ORDER BY num_products DESC;

-- HAVING: categories with avg price above $100
SELECT 
  category,
  AVG(price) AS avg_price
FROM products
GROUP BY category
HAVING AVG(price) > 100;

-- HAVING: customers with more than 1 order
SELECT 
  customer_id,
  COUNT(*) AS order_count
FROM orders
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Full business analysis query
SELECT 
  category,
  COUNT(*)       AS num_products,
  MIN(price)     AS cheapest,
  MAX(price)     AS most_expensive,
  AVG(price)     AS avg_price,
  SUM(stock_qty) AS total_stock
FROM products
GROUP BY category
ORDER BY avg_price DESC;
