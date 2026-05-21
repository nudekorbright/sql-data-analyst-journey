TASK 12: FULL BUSINESS CHALLENGE 
-- Business Scenario: Management requests a complete
-- Product Analytics Overview Dashboard
-- Requirements:
-- 1. Revenue by Country
-- 2. Revenue by Date and Year
-- 3. Profit and Unit Sales Year over Year
-- 4. Revenue by Discount Band
-- 5. Detailed Table View by Country and Year
-- + Additional insights from the analyst
-- ============================================================
 
-- REPORT 1: Revenue by Country
-- "Top performing regions with corresponding revenue"
SELECT
  c.country,
  r.region_name,
  COUNT(DISTINCT o.order_id)                  AS total_orders,
  COUNT(DISTINCT c.customer_id)               AS total_customers,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS total_revenue,
  ROUND(AVG(oi.unit_price * oi.quantity), 2)  AS avg_order_value,
  ROUND(SUM(oi.unit_price * oi.quantity)
    * 100.0 /
    SUM(SUM(oi.unit_price * oi.quantity))
    OVER (), 2)                               AS pct_of_total_revenue,
  RANK() OVER (
    ORDER BY SUM(oi.unit_price * oi.quantity) DESC
  )                                           AS revenue_rank
FROM customers c
JOIN regions r      ON r.region_id    = c.region_id
JOIN orders o       ON o.customer_id  = c.customer_id
JOIN order_items oi ON oi.order_id    = o.order_id
GROUP BY c.country, r.region_name
ORDER BY total_revenue DESC;
 
 
-- REPORT 2: Revenue by Date and Year
-- "Comparative trends over time"
SELECT
  YEAR(o.order_date)                          AS year,
  MONTH(o.order_date)                         AS month_num,
  MONTHNAME(o.order_date)                     AS month_name,
  COUNT(DISTINCT o.order_id)                  AS total_orders,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS monthly_revenue,
  ROUND(AVG(oi.unit_price * oi.quantity), 2)  AS avg_order_value,
  LAG(ROUND(SUM(oi.unit_price * oi.quantity),2))
    OVER (ORDER BY YEAR(o.order_date),
                   MONTH(o.order_date))       AS prev_month_revenue,
  SUM(ROUND(SUM(oi.unit_price * oi.quantity),2))
    OVER (
      PARTITION BY YEAR(o.order_date)
      ORDER BY MONTH(o.order_date)
      ROWS BETWEEN UNBOUNDED PRECEDING
      AND CURRENT ROW
    )                                         AS yearly_running_total
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY
  YEAR(o.order_date),
  MONTH(o.order_date),
  MONTHNAME(o.order_date)
ORDER BY year, month_num;
 
 
-- REPORT 3: Profit and Unit Sales Year over Year
-- "High level summary of YoY growth"
WITH yearly_stats AS (
  SELECT
    YEAR(o.order_date)                        AS year,
    SUM(oi.quantity)                          AS total_units_sold,
    ROUND(SUM(oi.unit_price * oi.quantity),2) AS total_revenue,
    ROUND(SUM((oi.unit_price - p.cost)
      * oi.quantity), 2)                      AS total_profit,
    COUNT(DISTINCT o.order_id)                AS total_orders,
    COUNT(DISTINCT o.customer_id)             AS unique_customers
  FROM orders o
  JOIN order_items oi ON oi.order_id   = o.order_id
  JOIN products p     ON p.product_id  = oi.product_id
  GROUP BY YEAR(o.order_date)
)
SELECT
  year,
  total_units_sold,
  total_revenue,
  total_profit,
  total_orders,
  unique_customers,
  ROUND(total_profit / total_revenue * 100, 2) AS profit_margin_pct,
  LAG(total_revenue) OVER (ORDER BY year)      AS prev_year_revenue,
  LAG(total_profit) OVER (ORDER BY year)       AS prev_year_profit,
  ROUND(
    (total_revenue -
      LAG(total_revenue) OVER (ORDER BY year))
    * 100.0
    / NULLIF(LAG(total_revenue) OVER (ORDER BY year), 0)
  , 2)                                         AS revenue_YoY_pct,
  ROUND(
    (total_profit -
      LAG(total_profit) OVER (ORDER BY year))
    * 100.0
    / NULLIF(LAG(total_profit) OVER (ORDER BY year), 0)
  , 2)                                         AS profit_YoY_pct
FROM yearly_stats
ORDER BY year;
 
 
-- REPORT 4: Revenue by Discount Band
-- "Distribution of revenue across discount categories"
SELECT
  CASE
    WHEN oi.discount_pct = 0          THEN 'No Discount (0%)'
    WHEN oi.discount_pct BETWEEN 1
      AND 10                          THEN 'Low Discount (1-10%)'
    WHEN oi.discount_pct BETWEEN 11
      AND 20                          THEN 'Medium Discount (11-20%)'
    WHEN oi.discount_pct > 20         THEN 'High Discount (20%+)'
  END                                         AS discount_band,
  COUNT(DISTINCT o.order_id)                  AS total_orders,
  SUM(oi.quantity)                            AS total_units,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS revenue_before_discount,
  ROUND(SUM(oi.unit_price * oi.quantity
    * (1 - oi.discount_pct / 100)), 2)        AS revenue_after_discount,
  ROUND(SUM(oi.unit_price * oi.quantity
    * (oi.discount_pct / 100)), 2)            AS total_discount_given,
  ROUND(COUNT(DISTINCT o.order_id) * 100.0
    / SUM(COUNT(DISTINCT o.order_id))
    OVER (), 2)                               AS pct_of_orders
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY discount_band
ORDER BY revenue_after_discount DESC;
 
 
-- REPORT 5: Detailed Table View by Country and Year
-- "Revenue and profit details by country and year"
SELECT
  c.country,
  YEAR(o.order_date)                          AS year,
  COUNT(DISTINCT o.order_id)                  AS total_orders,
  COUNT(DISTINCT c.customer_id)               AS total_customers,
  SUM(oi.quantity)                            AS units_sold,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS total_revenue,
  ROUND(SUM((oi.unit_price - p.cost)
    * oi.quantity), 2)                        AS total_profit,
  ROUND(SUM((oi.unit_price - p.cost)
    * oi.quantity)
    / SUM(oi.unit_price * oi.quantity)
    * 100, 2)                                 AS profit_margin_pct,
  ROUND(SUM(oi.unit_price * oi.quantity)
    / COUNT(DISTINCT o.order_id), 2)          AS avg_order_value
FROM customers c
JOIN orders o       ON o.customer_id  = c.customer_id
JOIN order_items oi ON oi.order_id    = o.order_id
JOIN products p     ON p.product_id   = oi.product_id
GROUP BY c.country, YEAR(o.order_date)
ORDER BY c.country, year;
 
 
-- ANALYST ADDITIONS 
-- "Whatever else you feel is necessary"
 
-- ADDITION 1: Campaign ROAS Dashboard
-- Which campaigns are profitable?
WITH campaign_performance AS (
  SELECT
    camp.campaign_name,
    camp.channel,
    camp.budget,
    COUNT(DISTINCT o.order_id)                AS orders,
    COUNT(DISTINCT o.customer_id)             AS customers,
    SUM(ws.converted)                         AS conversions,
    COUNT(DISTINCT ws.session_id)             AS total_sessions,
    ROUND(SUM(oi.unit_price * oi.quantity),2) AS revenue
  FROM campaigns camp
  LEFT JOIN orders o       ON o.campaign_id   = camp.campaign_id
  LEFT JOIN order_items oi ON oi.order_id     = o.order_id
  LEFT JOIN website_sessions ws
    ON ws.campaign_id = camp.campaign_id
  GROUP BY
    camp.campaign_name,
    camp.channel,
    camp.budget
)
SELECT
  campaign_name,
  channel,
  budget                                      AS spent,
  orders,
  customers,
  total_sessions,
  conversions,
  revenue,
  ROUND(revenue / NULLIF(budget, 0), 2)       AS ROAS,
  ROUND(budget / NULLIF(customers, 0), 2)     AS CAC,
  ROUND(revenue / NULLIF(orders, 0), 2)       AS AOV,
  ROUND(conversions * 100.0
    / NULLIF(total_sessions, 0), 2)           AS CVR_pct,
  CASE
    WHEN ROUND(revenue / NULLIF(budget,0),2)
      >= 3 THEN 'Profitable'
    WHEN ROUND(revenue / NULLIF(budget,0),2)
      >= 1 THEN 'Breaking Even'
    ELSE 'Losing Money'
  END                                         AS campaign_status
FROM campaign_performance
ORDER BY ROAS DESC;
 
 
-- ADDITION 2: Customer Health Dashboard
-- Who needs immediate attention?
WITH customer_value AS (
  SELECT
    o.customer_id,
    COUNT(DISTINCT o.order_id)                AS total_orders,
    MAX(o.order_date)                         AS last_order_date,
    ROUND(SUM(oi.unit_price * oi.quantity),2) AS lifetime_value
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY o.customer_id
)
SELECT
  c.customer_id,
  CONCAT(c.first_name, ' ', c.last_name)      AS customer_name,
  c.country,
  c.email,
  cv.total_orders,
  cv.last_order_date,
  DATEDIFF(NOW(), cv.last_order_date)         AS days_inactive,
  cv.lifetime_value,
  CASE
    WHEN cv.lifetime_value >= 500 THEN 'VIP'
    WHEN cv.lifetime_value >= 200 THEN 'Loyal'
    WHEN cv.lifetime_value >= 100 THEN 'Regular'
    ELSE 'New'
  END                                         AS value_tier,
  CASE
    WHEN DATEDIFF(NOW(), cv.last_order_date)
      > 365 THEN 'Churned'
    WHEN DATEDIFF(NOW(), cv.last_order_date)
      > 180 THEN 'At Risk'
    WHEN DATEDIFF(NOW(), cv.last_order_date)
      > 90  THEN 'Needs Attention'
    ELSE 'Active'
  END                                         AS health_status
FROM customers c
JOIN customer_value cv ON cv.customer_id = c.customer_id
ORDER BY cv.lifetime_value DESC;
 
 
-- ADDITION 3: Top 5 Products by Revenue and Profit
SELECT
  p.product_name,
  p.category,
  p.sub_category,
  p.price,
  p.cost,
  ROUND(p.price - p.cost, 2)                  AS profit_per_unit,
  SUM(oi.quantity)                            AS units_sold,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS total_revenue,
  ROUND(SUM((oi.unit_price - p.cost)
    * oi.quantity), 2)                        AS total_profit,
  RANK() OVER (
    ORDER BY SUM(oi.unit_price * oi.quantity) DESC
  )                                           AS revenue_rank,
  RANK() OVER (
    ORDER BY SUM((oi.unit_price - p.cost)
      * oi.quantity) DESC
  )                                           AS profit_rank
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY
  p.product_id,
  p.product_name,
  p.category,
  p.sub_category,
  p.price,
  p.cost
ORDER BY total_revenue DESC
LIMIT 10;
 
 
-- ADDITION 4: Sales Rep Leaderboard
SELECT
  sr.rep_name,
  r.region_name,
  r.country                                   AS rep_region,
  COUNT(DISTINCT o.order_id)                  AS total_orders,
  COUNT(DISTINCT o.customer_id)               AS unique_customers,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS total_revenue,
  ROUND(AVG(oi.unit_price * oi.quantity), 2)  AS avg_order_value,
  RANK() OVER (
    ORDER BY SUM(oi.unit_price * oi.quantity) DESC
  )                                           AS revenue_rank,
  ROUND(SUM(oi.unit_price * oi.quantity)
    * 100.0
    / SUM(SUM(oi.unit_price * oi.quantity))
    OVER (), 2)                               AS pct_of_total_revenue
FROM sales_reps sr
JOIN regions r      ON r.region_id    = sr.region_id
JOIN orders o       ON o.rep_id       = sr.rep_id
JOIN order_items oi ON oi.order_id    = o.order_id
GROUP BY
  sr.rep_id,
  sr.rep_name,
  r.region_name,
  r.country
ORDER BY total_revenue DESC;
 
 
-- ADDITION 5: Executive Summary Dashboard
-- One query to rule them all 
SELECT 'Total Revenue' AS metric,
  CONCAT('$', FORMAT(
    (SELECT SUM(unit_price * quantity) FROM order_items), 2
  )) AS value
UNION ALL
SELECT 'Total Orders',
  FORMAT((SELECT COUNT(*) FROM orders), 0)
UNION ALL
SELECT 'Total Customers',
  FORMAT((SELECT COUNT(*) FROM customers), 0)
UNION ALL
SELECT 'Active Customers',
  FORMAT((SELECT COUNT(*) FROM customers
    WHERE status = 'active'), 0)
UNION ALL
SELECT 'Average Order Value',
  CONCAT('$', FORMAT(
    (SELECT AVG(unit_price * quantity) FROM order_items), 2
  ))
UNION ALL
SELECT 'Total Products',
  FORMAT((SELECT COUNT(*) FROM products), 0)
UNION ALL
SELECT 'Total Campaigns',
  FORMAT((SELECT COUNT(*) FROM campaigns), 0)
UNION ALL
SELECT 'Best Performing Country',
  (SELECT c.country
   FROM customers c
   JOIN orders o ON o.customer_id = c.customer_id
   JOIN order_items oi ON oi.order_id = o.order_id
   GROUP BY c.country
   ORDER BY SUM(oi.unit_price * oi.quantity) DESC
   LIMIT 1)
UNION ALL
SELECT 'Best Campaign',
  (SELECT camp.campaign_name
   FROM campaigns camp
   JOIN orders o ON o.campaign_id = camp.campaign_id
   JOIN order_items oi ON oi.order_id = o.order_id
   GROUP BY camp.campaign_name
   ORDER BY SUM(oi.unit_price * oi.quantity) DESC
   LIMIT 1)
UNION ALL
SELECT 'Top Product',
  (SELECT p.product_name
   FROM products p
   JOIN order_items oi ON oi.product_id = p.product_id
   GROUP BY p.product_name
   ORDER BY SUM(oi.unit_price * oi.quantity) DESC
   LIMIT 1);
 
 
