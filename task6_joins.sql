 TASK 6: JOINS
-- Business Scenario: The analyst needs to combine multiple
-- tables to answer real business questions
-- ============================================================
 
-- Q1: Show all orders with the customer first name
-- and last name next to each order
SELECT
  o.order_id,
  o.order_date,
  o.status,
  c.first_name,
  c.last_name,
  c.country
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
ORDER BY o.order_date DESC;
 
-- Q2: Show all orders with the customer name AND
-- the campaign name that brought them in
SELECT
  o.order_id,
  o.order_date,
  c.first_name,
  c.last_name,
  camp.campaign_name,
  camp.channel
FROM orders o
JOIN customers c   ON c.customer_id   = o.customer_id
JOIN campaigns camp ON camp.campaign_id = o.campaign_id
ORDER BY o.order_date;
 
-- Q3: Show all customers and their orders —
-- include customers who have NO orders at all
SELECT
  c.customer_id,
  c.first_name,
  c.last_name,
  c.country,
  o.order_id,
  o.order_date,
  o.status
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
ORDER BY c.customer_id;
 
-- Q4: Show each order with customer name,
-- product name and quantity ordered
SELECT
  o.order_id,
  c.first_name,
  c.last_name,
  p.product_name,
  p.category,
  oi.quantity,
  oi.unit_price
FROM orders o
JOIN customers c    ON c.customer_id  = o.customer_id
JOIN order_items oi ON oi.order_id    = o.order_id
JOIN products p     ON p.product_id   = oi.product_id
ORDER BY o.order_id;
 
-- Q5: Show total revenue per customer
-- ordered by highest spender first
SELECT
  c.customer_id,
  c.first_name,
  c.last_name,
  c.country,
  COUNT(DISTINCT o.order_id)                    AS total_orders,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)    AS total_spent
FROM customers c
JOIN orders o       ON o.customer_id  = c.customer_id
JOIN order_items oi ON oi.order_id    = o.order_id
GROUP BY
  c.customer_id,
  c.first_name,
  c.last_name,
  c.country
ORDER BY total_spent DESC;
 
-- BONUS: Full order details — joining all 4 tables
SELECT
  o.order_id,
  o.order_date,
  o.status,
  o.payment_method,
  CONCAT(c.first_name, ' ', c.last_name)        AS customer_name,
  c.country,
  p.product_name,
  p.category,
  oi.quantity,
  oi.unit_price,
  oi.discount_pct,
  ROUND(oi.unit_price * oi.quantity, 2)         AS line_total,
  ROUND(oi.unit_price * oi.quantity *
    (1 - oi.discount_pct / 100), 2)             AS discounted_total,
  camp.campaign_name,
  camp.channel
FROM orders o
JOIN customers c     ON c.customer_id   = o.customer_id
JOIN order_items oi  ON oi.order_id     = o.order_id
JOIN products p      ON p.product_id    = oi.product_id
JOIN campaigns camp  ON camp.campaign_id = o.campaign_id
ORDER BY o.order_date, o.order_id;
 
