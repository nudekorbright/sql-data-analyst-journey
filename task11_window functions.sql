-- TASK 11: WINDOW FUNCTIONS
-- Business Scenario: Advanced analysis requiring row level
-- calculations while keeping all data visible
-- ============================================================
 
-- Q1: RANK customers by total spending overall
SELECT
  CONCAT(c.first_name, ' ', c.last_name)      AS customer_name,
  c.country,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS total_spent,
  RANK() OVER (
    ORDER BY SUM(oi.unit_price * oi.quantity) DESC
  )                                           AS spending_rank,
  DENSE_RANK() OVER (
    ORDER BY SUM(oi.unit_price * oi.quantity) DESC
  )                                           AS spending_dense_rank,
  ROW_NUMBER() OVER (
    ORDER BY SUM(oi.unit_price * oi.quantity) DESC
  )                                           AS row_number
FROM customers c
JOIN orders o       ON o.customer_id  = c.customer_id
JOIN order_items oi ON oi.order_id    = o.order_id
GROUP BY
  c.customer_id,
  c.first_name,
  c.last_name,
  c.country;
 
-- Q2: RANK customers within each country
SELECT
  CONCAT(c.first_name, ' ', c.last_name)      AS customer_name,
  c.country,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS total_spent,
  RANK() OVER (
    PARTITION BY c.country
    ORDER BY SUM(oi.unit_price * oi.quantity) DESC
  )                                           AS country_rank
FROM customers c
JOIN orders o       ON o.customer_id  = c.customer_id
JOIN order_items oi ON oi.order_id    = o.order_id
GROUP BY
  c.customer_id,
  c.first_name,
  c.last_name,
  c.country
ORDER BY c.country, country_rank;
 
-- Q3: Running total of revenue over time
SELECT
  DATE_FORMAT(o.order_date, '%Y-%m')          AS month,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS monthly_revenue,
  SUM(ROUND(SUM(oi.unit_price * oi.quantity),2))
    OVER (
      ORDER BY DATE_FORMAT(o.order_date, '%Y-%m')
      ROWS BETWEEN UNBOUNDED PRECEDING
      AND CURRENT ROW
    )                                         AS running_total
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
ORDER BY month;
 
-- Q4: LAG and LEAD — Month over month revenue change
WITH monthly AS (
  SELECT
    DATE_FORMAT(o.order_date, '%Y-%m')        AS month,
    ROUND(SUM(oi.unit_price * oi.quantity),2) AS revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
  month,
  revenue,
  LAG(revenue) OVER (ORDER BY month)          AS prev_month_revenue,
  LEAD(revenue) OVER (ORDER BY month)         AS next_month_revenue,
  ROUND(
    (revenue - LAG(revenue) OVER (ORDER BY month))
    * 100.0
    / NULLIF(LAG(revenue) OVER (ORDER BY month), 0)
  , 2)                                        AS MoM_growth_pct
FROM monthly
ORDER BY month;
 
-- Q5: Rolling 3 month average revenue
WITH monthly_revenue AS (
  SELECT
    DATE_FORMAT(o.order_date, '%Y-%m')        AS month,
    ROUND(SUM(oi.unit_price * oi.quantity),2) AS revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
  month,
  revenue,
  ROUND(AVG(revenue) OVER (
    ORDER BY month
    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
  ), 2)                                       AS rolling_3month_avg,
  SUM(revenue) OVER (
    ORDER BY month
    ROWS BETWEEN UNBOUNDED PRECEDING
    AND CURRENT ROW
  )                                           AS cumulative_revenue
FROM monthly_revenue
ORDER BY month;
 
-- BONUS: Top 3 customers per country using window functions
WITH ranked_customers AS (
  SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)    AS customer_name,
    c.country,
    ROUND(SUM(oi.unit_price * oi.quantity),2) AS total_spent,
    RANK() OVER (
      PARTITION BY c.country
      ORDER BY SUM(oi.unit_price * oi.quantity) DESC
    )                                         AS country_rank
  FROM customers c
  JOIN orders o       ON o.customer_id  = c.customer_id
  JOIN order_items oi ON oi.order_id    = o.order_id
  GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name,
    c.country
)
SELECT
  customer_name,
  country,
  total_spent,
  country_rank
FROM ranked_customers
WHERE country_rank <= 3
ORDER BY country, country_rank;
