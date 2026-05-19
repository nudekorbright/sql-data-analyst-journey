-- TASK 7: CASE STATEMENTS
-- Business Scenario: Marketing team needs to segment and
-- categorize customers and orders for targeted campaigns
-- ============================================================
 
-- Q1: Segment customers by age group
SELECT
  customer_id,
  first_name,
  last_name,
  age,
  CASE
    WHEN age BETWEEN 18 AND 25 THEN 'Gen Z (18-25)'
    WHEN age BETWEEN 26 AND 35 THEN 'Millennials (26-35)'
    WHEN age BETWEEN 36 AND 45 THEN 'Gen X (36-45)'
    WHEN age > 45              THEN 'Boomers (45+)'
    ELSE 'Unknown'
  END AS age_group
FROM customers
ORDER BY age;
 
-- Q2: Label each customer as active or inactive
-- with a friendly display label
SELECT
  customer_id,
  first_name,
  last_name,
  status,
  CASE
    WHEN status = 'active'   THEN ' Active Customer'
    WHEN status = 'inactive' THEN ' Inactive Customer'
    ELSE 'Unknown Status'
  END AS customer_label
FROM customers
ORDER BY status;
 
-- Q3: Classify orders by their delivery status
SELECT
  o.order_id,
  o.order_date,
  o.status,
  CASE
    WHEN o.status = 'delivered'  THEN 'Completed'
    WHEN o.status = 'processing' THEN 'In Progress'
    WHEN o.status = 'cancelled'  THEN 'Lost Sale'
    ELSE 'Unknown'
  END AS order_classification,
  ROUND(SUM(oi.unit_price * oi.quantity), 2) AS order_value
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY
  o.order_id,
  o.order_date,
  o.status
ORDER BY o.order_date;
 
-- Q4: Segment customers by total spending (LTV segments)
SELECT
  c.customer_id,
  CONCAT(c.first_name, ' ', c.last_name)      AS customer_name,
  c.country,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS total_spent,
  CASE
    WHEN SUM(oi.unit_price * oi.quantity) >= 1000
      THEN '💎 VIP Customer'
    WHEN SUM(oi.unit_price * oi.quantity) >= 500
      THEN '⭐ Loyal Customer'
    WHEN SUM(oi.unit_price * oi.quantity) >= 100
      THEN '🔄 Regular Customer'
    ELSE '🆕 New Customer'
  END AS customer_segment
FROM customers c
JOIN orders o       ON o.customer_id  = c.customer_id
JOIN order_items oi ON oi.order_id    = o.order_id
GROUP BY
  c.customer_id,
  c.first_name,
  c.last_name,
  c.country
ORDER BY total_spent DESC;
 
-- Q5: Count orders and revenue by order classification
SELECT
  CASE
    WHEN o.status = 'delivered'  THEN 'Completed'
    WHEN o.status = 'processing' THEN 'In Progress'
    WHEN o.status = 'cancelled'  THEN 'Lost Sale'
    ELSE 'Unknown'
  END                                         AS order_status,
  COUNT(*)                                    AS total_orders,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS total_value
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY order_status
ORDER BY total_value DESC;
 
-- BONUS: Full customer profile with all segments
SELECT
  c.customer_id,
  CONCAT(c.first_name, ' ', c.last_name)      AS customer_name,
  c.country,
  c.gender,
  c.age,
  CASE
    WHEN c.age BETWEEN 18 AND 25 THEN 'Gen Z'
    WHEN c.age BETWEEN 26 AND 35 THEN 'Millennial'
    WHEN c.age BETWEEN 36 AND 45 THEN 'Gen X'
    ELSE 'Boomer'
  END                                         AS age_group,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS total_spent,
  CASE
    WHEN SUM(oi.unit_price * oi.quantity) >= 1000
      THEN 'VIP'
    WHEN SUM(oi.unit_price * oi.quantity) >= 500
      THEN 'Loyal'
    WHEN SUM(oi.unit_price * oi.quantity) >= 100
      THEN 'Regular'
    ELSE 'New'
  END                                         AS value_segment,
  c.status
FROM customers c
JOIN orders o       ON o.customer_id  = c.customer_id
JOIN order_items oi ON oi.order_id    = o.order_id
GROUP BY
  c.customer_id,
  c.first_name,
  c.last_name,
  c.country,
  c.gender,
  c.age,
  c.status
ORDER BY total_spent DESC
