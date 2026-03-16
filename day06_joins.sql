-- =============================================
-- DAY 6: JOINs — Combining Tables
-- Dataset: E-Commerce (ecommerce_db)
-- =============================================

-- INNER JOIN: customers with their orders
SELECT 
  c.first_name,
  c.last_name,
  o.order_id,
  o.status
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id;

-- LEFT JOIN: all customers including those with no orders
SELECT 
  c.first_name,
  c.last_name,
  o.order_id,
  o.status
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;

-- Find customers with NO orders
SELECT 
  c.first_name,
  c.last_name,
  o.order_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- Three table JOIN: complete order report
SELECT 
  c.first_name,
  c.last_name,
  p.product_name,
  o.quantity,
  p.price,
  o.order_date,
  o.status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p  ON o.product_id  = p.product_id;

-- Three table JOIN with total amount
SELECT 
  c.first_name,
  c.last_name,
  p.product_name,
  o.quantity,
  p.price,
  o.quantity * p.price AS total_amount,
  o.order_date,
  o.status
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN products p  ON o.product_id  = p.product_id
ORDER BY total_amount DESC;

-- Total spent per customer
SELECT 
  c.first_name,
  c.last_name,
  COUNT(o.order_id)         AS total_orders,
  SUM(o.quantity * p.price) AS total_spent
FROM customers c
JOIN orders o  ON c.customer_id = o.customer_id
JOIN products p ON o.product_id = p.product_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC;
