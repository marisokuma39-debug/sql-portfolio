-- =============================================
-- DAY 7: Week 1 Project — E-Commerce Analytics
-- Dataset: E-Commerce (ecommerce_db)
-- =============================================

-- Report 1: Total revenue by category
SELECT 
  p.category,
  SUM(o.quantity * p.price) AS total_revenue
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Report 2: Top 5 customers by total spending
SELECT 
  c.first_name,
  c.last_name,
  SUM(o.quantity * p.price) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN products p ON o.product_id = p.product_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 5;

-- Report 3: Best selling products by quantity
SELECT 
  p.product_name,
  SUM(o.quantity) AS total_units_sold
FROM orders o
JOIN products p ON o.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_units_sold DESC;

-- Report 4: Orders by status
SELECT 
  status,
  COUNT(*) AS total_orders
FROM orders
GROUP BY status
ORDER BY total_orders DESC;

-- Report 5: Revenue by country
SELECT 
  c.country,
  SUM(o.quantity * p.price) AS total_revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN products p ON o.product_id = p.product_id
GROUP BY c.country
ORDER BY total_revenue DESC;

-- Report 6: Monthly order trend 2024
SELECT 
  DATE_FORMAT(order_date, '%M %Y') AS month,
  COUNT(*) AS total_orders
FROM orders
WHERE YEAR(order_date) = 2024
GROUP BY DATE_FORMAT(order_date, '%M %Y')
ORDER BY MIN(order_date) ASC;

-- Report 7: Products never ordered (dead stock check)
SELECT 
  p.product_name,
  p.category,
  p.stock_qty
FROM products p
LEFT JOIN orders o ON p.product_id = o.product_id
WHERE o.order_id IS NULL;

-- Report 8: Average order value per customer
SELECT 
  c.first_name,
  c.last_name,
  COUNT(o.order_id)         AS total_orders,
  SUM(o.quantity * p.price) AS total_spent,
  AVG(o.quantity * p.price) AS avg_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN products p ON o.product_id = p.product_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY avg_order_value DESC;
