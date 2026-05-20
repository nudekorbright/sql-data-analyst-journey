
-- TASK 9: DATE AND TIME FUNCTIONS
-- Business Scenario: Marketing team needs time-based
-- analysis to understand trends and seasonality
-- ============================================================
 
-- Q1: Extract year, month and day from order dates
SELECT
  order_id,
  order_date,
  YEAR(order_date)                            AS order_year,
  MONTH(order_date)                           AS order_month,
  MONTHNAME(order_date)                       AS month_name,
  DAY(order_date)                             AS order_day,
  DAYNAME(order_date)                         AS day_of_week
FROM orders
ORDER BY order_date;
 
-- Q2: Count orders per month per year
SELECT
  YEAR(order_date)                            AS year,
  MONTH(order_date)                           AS month,
  MONTHNAME(order_date)                       AS month_name,
  COUNT(*)                                    AS total_orders,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS monthly_revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY
  YEAR(order_date),
  MONTH(order_date),
  MONTHNAME(order_date)
ORDER BY year, month;
 
-- Q3: How many days since each customer signed up
SELECT
  customer_id,
  first_name,
  last_name,
  signup_date,
  DATEDIFF(NOW(), signup_date)                AS days_since_signup,
  FLOOR(DATEDIFF(NOW(), signup_date) / 30)    AS months_since_signup,
  FLOOR(DATEDIFF(NOW(), signup_date) / 365)   AS years_since_signup
FROM customers
ORDER BY days_since_signup DESC;
 
-- Q4: Find customers who signed up in 2023
SELECT
  customer_id,
  first_name,
  last_name,
  country,
  signup_date
FROM customers
WHERE YEAR(signup_date) = 2023
ORDER BY signup_date;
 
-- Q5: Days between order date and delivery date
SELECT
  order_id,
  order_date,
  delivery_date,
  DATEDIFF(delivery_date, order_date)         AS delivery_days,
  CASE
    WHEN DATEDIFF(delivery_date, order_date) <= 5
      THEN 'Fast Delivery'
    WHEN DATEDIFF(delivery_date, order_date) <= 8
      THEN 'Standard Delivery'
    ELSE 'Slow Delivery'
  END                                         AS delivery_speed
FROM orders
WHERE delivery_date IS NOT NULL
ORDER BY delivery_days DESC;
 
-- BONUS: Monthly revenue trend with YoY comparison
SELECT
  YEAR(o.order_date)                          AS year,
  MONTHNAME(o.order_date)                     AS month,
  MONTH(o.order_date)                         AS month_num,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS revenue,
  COUNT(DISTINCT o.order_id)                  AS total_orders,
  COUNT(DISTINCT o.customer_id)               AS unique_customers
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY
  YEAR(o.order_date),
  MONTHNAME(o.order_date),
  MONTH(o.order_date)
ORDER BY year, month_num;
 
