-- ============================================================
--   COMPLETE ANALYST FORMULA REFERENCE
--   Financial Reports | Profitability Analysis
--   Product Recommendations
--   Database: marketing_analytics
--   Every formula explained with real queries
-- ============================================================


-- ============================================================
-- SECTION 1: FINANCIAL REPORT FORMULAS
-- What finance teams ask analysts to calculate every month
-- ============================================================


-- ─────────────────────────────────────────────
-- FORMULA 1: TOTAL REVENUE
-- "How much money came in?"
-- ─────────────────────────────────────────────
/*
FORMULA:
Total Revenue = Unit Price × Quantity

Simple meaning:
If you sold 3 courses at $99.99 each
Revenue = $99.99 × 3 = $299.97
*/

SELECT
  ROUND(SUM(unit_price * quantity), 2)        AS total_revenue
FROM order_items;

-- With discount applied
SELECT
  ROUND(SUM(unit_price * quantity), 2)        AS revenue_before_discount,
  ROUND(SUM(unit_price * quantity
    * (1 - discount_pct / 100)), 2)           AS revenue_after_discount,
  ROUND(SUM(unit_price * quantity
    * (discount_pct / 100)), 2)               AS total_discount_given
FROM order_items;


-- ─────────────────────────────────────────────
-- FORMULA 2: TOTAL COST
-- "How much did it cost to deliver those sales?"
-- ─────────────────────────────────────────────
/*
FORMULA:
Total Cost = Product Cost × Quantity Sold

Simple meaning:
If course costs $10 to deliver
and you sold 50 courses:
Total Cost = $10 × 50 = $500
*/

SELECT
  p.product_name,
  SUM(oi.quantity)                            AS units_sold,
  ROUND(p.cost, 2)                            AS cost_per_unit,
  ROUND(p.cost * SUM(oi.quantity), 2)         AS total_cost
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.cost
ORDER BY total_cost DESC;


-- ─────────────────────────────────────────────
-- FORMULA 3: GROSS PROFIT
-- "How much money did we actually make?"
-- ─────────────────────────────────────────────
/*
FORMULA:
Gross Profit = Total Revenue - Total Cost

Simple meaning:
Revenue:     $5,000
Total Cost:  $1,000
Gross Profit: $4,000

This is the money left BEFORE
paying for ads, salaries etc
*/

SELECT
  ROUND(SUM(oi.unit_price * oi.quantity), 2)
    AS total_revenue,
  ROUND(SUM(p.cost * oi.quantity), 2)
    AS total_cost,
  ROUND(SUM(oi.unit_price * oi.quantity)
    - SUM(p.cost * oi.quantity), 2)           AS gross_profit
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id;


-- ─────────────────────────────────────────────
-- FORMULA 4: GROSS PROFIT MARGIN %
-- "What percentage of revenue is profit?"
-- ─────────────────────────────────────────────
/*
FORMULA:
Gross Margin % = (Gross Profit ÷ Revenue) × 100

Simple meaning:
Gross Profit: $4,000
Revenue:      $5,000
Margin: ($4,000 ÷ $5,000) × 100 = 80%

80% margin means for every $1 sold
the business keeps $0.80 as profit

Benchmarks:
Below 20%  → Very thin margin ❌
20% - 50%  → Acceptable       ⚠️
50% - 80%  → Good             ✅
Above 80%  → Excellent 🔥
(Digital products like courses
 typically have 80-95% margins)
*/

SELECT
  p.category,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)
    AS total_revenue,
  ROUND(SUM(p.cost * oi.quantity), 2)
    AS total_cost,
  ROUND(SUM(oi.unit_price * oi.quantity)
    - SUM(p.cost * oi.quantity), 2)           AS gross_profit,
  ROUND(
    (SUM(oi.unit_price * oi.quantity)
      - SUM(p.cost * oi.quantity))
    / SUM(oi.unit_price * oi.quantity)
    * 100, 2)                                 AS gross_margin_pct
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY gross_margin_pct DESC;


-- ─────────────────────────────────────────────
-- FORMULA 5: NET PROFIT
-- "What is left after ALL expenses?"
-- ─────────────────────────────────────────────
/*
FORMULA:
Net Profit = Gross Profit - Operating Expenses

Operating Expenses include:
→ Ad spend (campaigns budget)
→ Shipping costs
→ Salaries

Simple meaning:
Gross Profit:     $4,000
Ad Spend:         $1,000
Shipping:         $200
Net Profit:       $2,800

This is the REAL final profit
*/

WITH gross AS (
  SELECT
    ROUND(SUM(oi.unit_price * oi.quantity)
      - SUM(p.cost * oi.quantity), 2)         AS gross_profit
  FROM order_items oi
  JOIN products p ON p.product_id = oi.product_id
),
expenses AS (
  SELECT
    ROUND(SUM(c.budget), 2)                   AS total_ad_spend,
    ROUND(SUM(o.shipping_cost), 2)            AS total_shipping
  FROM campaigns c
  CROSS JOIN (
    SELECT SUM(shipping_cost) AS shipping_cost
    FROM orders
  ) o
  LIMIT 1
)
SELECT
  g.gross_profit,
  e.total_ad_spend,
  e.total_shipping,
  ROUND(g.gross_profit
    - e.total_ad_spend
    - e.total_shipping, 2)                    AS net_profit
FROM gross g, expenses e;


-- ─────────────────────────────────────────────
-- FORMULA 6: MONTH OVER MONTH REVENUE (MoM)
-- "Are we growing compared to last month?"
-- ─────────────────────────────────────────────
/*
FORMULA:
MoM Growth % = (This Month - Last Month)
               ÷ Last Month × 100

Simple meaning:
Last month:   $4,000
This month:   $5,000
MoM Growth: ($5,000 - $4,000) ÷ $4,000 × 100
           = 25% growth ✅

Negative = shrinking ❌
Positive = growing  ✅
*/

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
  revenue                                     AS this_month_revenue,
  LAG(revenue) OVER (ORDER BY month)          AS last_month_revenue,
  ROUND(
    (revenue - LAG(revenue) OVER (ORDER BY month))
    * 100.0
    / NULLIF(LAG(revenue) OVER (ORDER BY month), 0)
  , 2)                                        AS MoM_growth_pct,
  CASE
    WHEN revenue > LAG(revenue) OVER (ORDER BY month)
    THEN 'Growing ✅'
    WHEN revenue < LAG(revenue) OVER (ORDER BY month)
    THEN 'Declining ❌'
    ELSE 'Flat ⚠️'
  END                                         AS trend
FROM monthly
ORDER BY month;


-- ─────────────────────────────────────────────
-- FORMULA 7: YEAR OVER YEAR REVENUE (YoY)
-- "How does this year compare to last year?"
-- ─────────────────────────────────────────────
/*
FORMULA:
YoY Growth % = (This Year - Last Year)
               ÷ Last Year × 100

Simple meaning:
Last year:    $40,000
This year:    $55,000
YoY Growth: ($55,000 - $40,000) ÷ $40,000 × 100
           = 37.5% growth 🔥

Why YoY matters more than MoM:
→ Removes seasonal patterns
→ More reliable for strategy
→ Used in investor reports
*/

WITH yearly AS (
  SELECT
    YEAR(o.order_date)                        AS year,
    ROUND(SUM(oi.unit_price * oi.quantity),2) AS revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY YEAR(o.order_date)
)
SELECT
  year,
  revenue,
  LAG(revenue) OVER (ORDER BY year)           AS prev_year_revenue,
  ROUND(
    (revenue - LAG(revenue) OVER (ORDER BY year))
    * 100.0
    / NULLIF(LAG(revenue) OVER (ORDER BY year), 0)
  , 2)                                        AS YoY_growth_pct
FROM yearly
ORDER BY year;


-- ─────────────────────────────────────────────
-- FORMULA 8: RUNNING TOTAL (Cumulative Revenue)
-- "How much have we made from the start until now?"
-- ─────────────────────────────────────────────
/*
FORMULA:
Running Total = Sum of all revenue
                from first month
                up to current month

Simple meaning:
January:  $1,000  Running total: $1,000
February: $1,500  Running total: $2,500
March:    $1,200  Running total: $3,700

Used to track progress toward
annual revenue targets
*/

WITH monthly AS (
  SELECT
    DATE_FORMAT(o.order_date, '%Y-%m')        AS month,
    ROUND(SUM(oi.unit_price * oi.quantity),2) AS monthly_revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT
  month,
  monthly_revenue,
  SUM(monthly_revenue) OVER (
    ORDER BY month
    ROWS BETWEEN UNBOUNDED PRECEDING
    AND CURRENT ROW
  )                                           AS running_total,
  ROUND(monthly_revenue * 100.0
    / SUM(monthly_revenue) OVER (), 2)        AS pct_of_total_revenue
FROM monthly
ORDER BY month;


-- ============================================================
-- SECTION 2: PROFITABILITY ANALYSIS FORMULAS
-- Deeper analysis of WHERE profit comes from
-- ============================================================


-- ─────────────────────────────────────────────
-- FORMULA 9: PROFIT PER PRODUCT
-- "Which products make the most money?"
-- ─────────────────────────────────────────────
/*
FORMULA:
Profit per Unit = Price - Cost
Total Profit = (Price - Cost) × Quantity Sold
Profit Margin % = Profit ÷ Price × 100

Simple meaning:
Product: Power BI Dashboard Kit
Price:   $49.99
Cost:    $5.00
Profit per unit: $44.99
Margin: ($44.99 ÷ $49.99) × 100 = 90%
*/

SELECT
  p.product_name,
  p.category,
  p.price                                     AS selling_price,
  p.cost                                      AS product_cost,
  ROUND(p.price - p.cost, 2)                  AS profit_per_unit,
  ROUND((p.price - p.cost)
    / p.price * 100, 2)                       AS unit_margin_pct,
  SUM(oi.quantity)                            AS units_sold,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS total_revenue,
  ROUND(SUM((oi.unit_price - p.cost)
    * oi.quantity), 2)                        AS total_profit,
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
  p.price,
  p.cost
ORDER BY total_profit DESC;


-- ─────────────────────────────────────────────
-- FORMULA 10: PROFIT BY CATEGORY
-- "Which product category is most profitable?"
-- ─────────────────────────────────────────────
/*
FORMULA:
Category Profit = Sum of all product profits
                  within that category

Category Margin = Category Profit
                  ÷ Category Revenue × 100
*/

SELECT
  p.category,
  COUNT(DISTINCT p.product_id)                AS total_products,
  SUM(oi.quantity)                            AS units_sold,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS total_revenue,
  ROUND(SUM(p.cost * oi.quantity), 2)         AS total_cost,
  ROUND(SUM((oi.unit_price - p.cost)
    * oi.quantity), 2)                        AS total_profit,
  ROUND(SUM((oi.unit_price - p.cost)
    * oi.quantity)
    / SUM(oi.unit_price * oi.quantity)
    * 100, 2)                                 AS profit_margin_pct,
  RANK() OVER (
    ORDER BY SUM((oi.unit_price - p.cost)
      * oi.quantity) DESC
  )                                           AS profit_rank
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY total_profit DESC;


-- ─────────────────────────────────────────────
-- FORMULA 11: BREAK EVEN POINT
-- "How many units must we sell to cover costs?"
-- ─────────────────────────────────────────────
/*
FORMULA:
Break Even Units = Fixed Costs
                   ÷ (Price - Variable Cost)

Simple meaning:
Ad Spend (Fixed Cost): $1,000
Price per course:       $99.99
Cost per course:        $10.00
Contribution:          $89.99

Break Even = $1,000 ÷ $89.99 = 12 units

Meaning: Sell 12 courses to
cover your $1,000 ad spend
Every sale after that is profit
*/

SELECT
  c.campaign_name,
  c.budget                                    AS fixed_ad_cost,
  ROUND(AVG(p.price), 2)                      AS avg_product_price,
  ROUND(AVG(p.cost), 2)                       AS avg_product_cost,
  ROUND(AVG(p.price) - AVG(p.cost), 2)        AS contribution_per_unit,
  CEIL(c.budget
    / (AVG(p.price) - AVG(p.cost)))           AS break_even_units,
  COUNT(DISTINCT oi.item_id)                  AS actual_units_sold,
  COUNT(DISTINCT oi.item_id) -
  CEIL(c.budget
    / (AVG(p.price) - AVG(p.cost)))           AS units_above_break_even
FROM campaigns c
JOIN orders o       ON o.campaign_id  = c.campaign_id
JOIN order_items oi ON oi.order_id    = o.order_id
JOIN products p     ON p.product_id   = oi.product_id
GROUP BY c.campaign_id, c.campaign_name, c.budget
ORDER BY units_above_break_even DESC;


-- ─────────────────────────────────────────────
-- FORMULA 12: CUSTOMER LIFETIME VALUE (LTV/CLV)
-- "How much is each customer worth over time?"
-- ─────────────────────────────────────────────
/*
FORMULA:
LTV = Average Order Value (AOV)
      × Purchase Frequency
      × Customer Lifespan

Simple meaning:
AOV:       $150 per order
Frequency: 3 orders per year
Lifespan:  2 years
LTV = $150 × 3 × 2 = $900

Why it matters:
If LTV is $900 you can afford
to spend up to $900 to acquire
that customer and still break even

Golden rule:
LTV must be at least 3x CAC
LTV $900 + CAC $300 = Healthy ✅
LTV $100 + CAC $300 = Dying   ❌
*/

WITH customer_stats AS (
  SELECT
    o.customer_id,
    COUNT(DISTINCT o.order_id)                AS total_orders,
    ROUND(SUM(oi.unit_price * oi.quantity),2) AS total_spent,
    MIN(o.order_date)                         AS first_order,
    MAX(o.order_date)                         AS last_order,
    DATEDIFF(MAX(o.order_date),
             MIN(o.order_date)) / 30          AS customer_months
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY o.customer_id
)
SELECT
  c.first_name,
  c.last_name,
  c.country,
  cs.total_orders,
  cs.total_spent,
  ROUND(cs.total_spent
    / NULLIF(cs.total_orders, 0), 2)          AS AOV,
  ROUND(cs.customer_months, 1)                AS months_as_customer,
  cs.total_spent                              AS actual_LTV,
  CASE
    WHEN cs.total_spent >= 500  THEN 'High LTV 🔥'
    WHEN cs.total_spent >= 200  THEN 'Medium LTV ✅'
    WHEN cs.total_spent >= 100  THEN 'Low LTV ⚠️'
    ELSE 'Very Low LTV ❌'
  END                                         AS LTV_segment
FROM customer_stats cs
JOIN customers c ON c.customer_id = cs.customer_id
ORDER BY actual_LTV DESC;


-- ─────────────────────────────────────────────
-- FORMULA 13: RETURN ON INVESTMENT (ROI)
-- "Did this investment make money overall?"
-- ─────────────────────────────────────────────
/*
FORMULA:
ROI % = (Revenue - Cost) ÷ Cost × 100

Simple meaning:
You spent $1,000 on a campaign
You made $3,500 in revenue
ROI = ($3,500 - $1,000) ÷ $1,000 × 100
    = $2,500 ÷ $1,000 × 100
    = 250% ROI ✅

Positive ROI = Making money ✅
Negative ROI = Losing money ❌
0% ROI       = Breaking even ⚠️

Difference from ROAS:
ROAS = Revenue ÷ Spend (ratio)
ROI  = (Revenue - Spend) ÷ Spend × 100 (%)
ROAS 3.5 = ROI 250% — same campaign
*/

SELECT
  c.campaign_name,
  c.channel,
  c.budget                                    AS investment,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS revenue_generated,
  ROUND(SUM(oi.unit_price * oi.quantity)
    - c.budget, 2)                            AS net_gain,
  ROUND(
    (SUM(oi.unit_price * oi.quantity) - c.budget)
    / c.budget * 100, 2)                      AS ROI_pct,
  ROUND(SUM(oi.unit_price * oi.quantity)
    / c.budget, 2)                            AS ROAS,
  CASE
    WHEN (SUM(oi.unit_price * oi.quantity)
      - c.budget) / c.budget * 100 >= 200
    THEN 'Excellent ROI 🔥'
    WHEN (SUM(oi.unit_price * oi.quantity)
      - c.budget) / c.budget * 100 >= 100
    THEN 'Good ROI ✅'
    WHEN (SUM(oi.unit_price * oi.quantity)
      - c.budget) / c.budget * 100 >= 0
    THEN 'Break Even ⚠️'
    ELSE 'Negative ROI ❌'
  END                                         AS ROI_status
FROM campaigns c
JOIN orders o       ON o.campaign_id  = c.campaign_id
JOIN order_items oi ON oi.order_id    = o.order_id
GROUP BY c.campaign_id, c.campaign_name, c.channel, c.budget
ORDER BY ROI_pct DESC;


-- ─────────────────────────────────────────────
-- FORMULA 14: AVERAGE ORDER VALUE (AOV)
-- "How much does each customer spend per order?"
-- ─────────────────────────────────────────────
/*
FORMULA:
AOV = Total Revenue ÷ Total Orders

Simple meaning:
Total Revenue: $50,000
Total Orders:  500
AOV = $50,000 ÷ 500 = $100 per order

Why it matters:
Higher AOV = more revenue per customer
Easier to be profitable with high AOV

How to increase AOV:
→ Bundle products together
→ Offer upsells at checkout
→ Minimum spend for free shipping
→ Volume discounts
*/

-- Overall AOV
SELECT
  COUNT(DISTINCT o.order_id)                  AS total_orders,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS total_revenue,
  ROUND(SUM(oi.unit_price * oi.quantity)
    / COUNT(DISTINCT o.order_id), 2)          AS overall_AOV
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id;

-- AOV by channel
SELECT
  c.channel,
  COUNT(DISTINCT o.order_id)                  AS total_orders,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS total_revenue,
  ROUND(SUM(oi.unit_price * oi.quantity)
    / COUNT(DISTINCT o.order_id), 2)          AS channel_AOV
FROM campaigns c
JOIN orders o       ON o.campaign_id  = c.campaign_id
JOIN order_items oi ON oi.order_id    = o.order_id
GROUP BY c.channel
ORDER BY channel_AOV DESC;


-- ─────────────────────────────────────────────
-- FORMULA 15: CUSTOMER ACQUISITION COST (CAC)
-- "How much does it cost to get one customer?"
-- ─────────────────────────────────────────────
/*
FORMULA:
CAC = Total Marketing Spend
      ÷ Number of New Customers

Simple meaning:
Marketing Spend: $5,000
New Customers:   100
CAC = $5,000 ÷ 100 = $50 per customer

Golden Rule:
LTV ÷ CAC should be at least 3
LTV $300 ÷ CAC $50 = 6 → Excellent ✅
LTV $60  ÷ CAC $50 = 1.2 → Problem ❌
*/

SELECT
  c.campaign_name,
  c.channel,
  c.budget                                    AS total_spend,
  COUNT(DISTINCT o.customer_id)               AS new_customers,
  ROUND(c.budget
    / COUNT(DISTINCT o.customer_id), 2)       AS CAC,
  ROUND(SUM(oi.unit_price * oi.quantity)
    / COUNT(DISTINCT o.customer_id), 2)       AS avg_LTV_per_customer,
  ROUND(
    (SUM(oi.unit_price * oi.quantity)
      / COUNT(DISTINCT o.customer_id))
    / (c.budget
      / COUNT(DISTINCT o.customer_id))
  , 2)                                        AS LTV_to_CAC_ratio,
  CASE
    WHEN ROUND(
      (SUM(oi.unit_price * oi.quantity)
        / COUNT(DISTINCT o.customer_id))
      / (c.budget
        / COUNT(DISTINCT o.customer_id))
    , 2) >= 3 THEN 'Healthy ✅'
    WHEN ROUND(
      (SUM(oi.unit_price * oi.quantity)
        / COUNT(DISTINCT o.customer_id))
      / (c.budget
        / COUNT(DISTINCT o.customer_id))
    , 2) >= 1 THEN 'Acceptable ⚠️'
    ELSE 'Unsustainable ❌'
  END                                         AS business_health
FROM campaigns c
JOIN orders o       ON o.campaign_id  = c.campaign_id
JOIN order_items oi ON oi.order_id    = o.order_id
GROUP BY
  c.campaign_id,
  c.campaign_name,
  c.channel,
  c.budget
ORDER BY LTV_to_CAC_ratio DESC;


-- ============================================================
-- SECTION 3: PRODUCT RECOMMENDATION FORMULAS
-- Data driven analysis that tells you what to sell more of
-- stop selling or promote differently
-- ============================================================


-- ─────────────────────────────────────────────
-- FORMULA 16: PRODUCT PERFORMANCE SCORE
-- "Which products should we promote more?"
-- ─────────────────────────────────────────────
/*
FORMULA:
Performance Score considers:
→ Revenue contribution
→ Profit margin
→ Units sold volume

High score = Promote heavily 🔥
Low score  = Review or drop ❌
*/

SELECT
  p.product_name,
  p.category,
  SUM(oi.quantity)                            AS units_sold,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS total_revenue,
  ROUND(SUM((oi.unit_price - p.cost)
    * oi.quantity), 2)                        AS total_profit,
  ROUND(SUM((oi.unit_price - p.cost)
    * oi.quantity)
    / SUM(oi.unit_price * oi.quantity)
    * 100, 2)                                 AS profit_margin_pct,
  RANK() OVER (
    ORDER BY SUM(oi.unit_price * oi.quantity)
    DESC)                                     AS revenue_rank,
  RANK() OVER (
    ORDER BY SUM((oi.unit_price - p.cost)
      * oi.quantity) DESC)                    AS profit_rank,
  RANK() OVER (
    ORDER BY SUM(oi.quantity) DESC)           AS volume_rank,
  CASE
    WHEN SUM((oi.unit_price - p.cost)
      * oi.quantity)
      / SUM(oi.unit_price * oi.quantity)
      * 100 >= 70
    AND SUM(oi.quantity) >= 3
    THEN 'Star Product 🔥 — Promote More'
    WHEN SUM((oi.unit_price - p.cost)
      * oi.quantity)
      / SUM(oi.unit_price * oi.quantity)
      * 100 >= 50
    THEN 'Good Product ✅ — Maintain'
    WHEN SUM((oi.unit_price - p.cost)
      * oi.quantity)
      / SUM(oi.unit_price * oi.quantity)
      * 100 >= 30
    THEN 'Review Product ⚠️ — Improve'
    ELSE 'Poor Product ❌ — Consider Dropping'
  END                                         AS recommendation
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY
  p.product_id,
  p.product_name,
  p.category,
  p.price,
  p.cost
ORDER BY total_profit DESC;


-- ─────────────────────────────────────────────
-- FORMULA 17: ABC ANALYSIS
-- "Classify products by revenue contribution"
-- ─────────────────────────────────────────────
/*
ABC Classification:
A Products → Top 20% driving 80% revenue
             → VIP products — never run out
B Products → Middle 30% driving 15% revenue
             → Important — monitor closely
C Products → Bottom 50% driving 5% revenue
             → Review — consider dropping

This is based on the Pareto Principle:
80% of results come from 20% of products
*/

WITH product_revenue AS (
  SELECT
    p.product_name,
    p.category,
    ROUND(SUM(oi.unit_price * oi.quantity),2) AS revenue,
    SUM(oi.quantity)                          AS units_sold
  FROM products p
  JOIN order_items oi ON oi.product_id = p.product_id
  GROUP BY p.product_id, p.product_name, p.category
),
ranked AS (
  SELECT
    product_name,
    category,
    revenue,
    units_sold,
    SUM(revenue) OVER ()                      AS total_revenue,
    SUM(revenue) OVER (
      ORDER BY revenue DESC
      ROWS BETWEEN UNBOUNDED PRECEDING
      AND CURRENT ROW
    )                                         AS cumulative_revenue,
    ROUND(revenue
      / SUM(revenue) OVER () * 100, 2)        AS pct_of_revenue,
    ROUND(SUM(revenue) OVER (
      ORDER BY revenue DESC
      ROWS BETWEEN UNBOUNDED PRECEDING
      AND CURRENT ROW
    ) / SUM(revenue) OVER () * 100, 2)        AS cumulative_pct
  FROM product_revenue
)
SELECT
  product_name,
  category,
  revenue,
  units_sold,
  pct_of_revenue,
  cumulative_pct,
  CASE
    WHEN cumulative_pct <= 80
    THEN 'A — Top Product 🔥 Protect Stock'
    WHEN cumulative_pct <= 95
    THEN 'B — Good Product ✅ Monitor'
    ELSE 'C — Low Product ⚠️ Review'
  END                                         AS ABC_class
FROM ranked
ORDER BY revenue DESC;


-- ─────────────────────────────────────────────
-- FORMULA 18: PRICE ELASTICITY INSIGHT
-- "Are our products priced correctly?"
-- ─────────────────────────────────────────────
/*
Simple analysis:
High price + Low sales  → Price might be too high
Low price  + High sales → Price might be too low
                          Could be raised for
                          more profit
High price + High sales → Perfect sweet spot 🔥
*/

SELECT
  p.product_name,
  p.category,
  p.price,
  p.cost,
  ROUND(p.price - p.cost, 2)                  AS profit_per_unit,
  SUM(oi.quantity)                            AS units_sold,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS total_revenue,
  CASE
    WHEN p.price >= 200
    AND SUM(oi.quantity) >= 5
    THEN 'Premium Seller 🔥 Keep price'
    WHEN p.price >= 200
    AND SUM(oi.quantity) < 5
    THEN 'High price low volume ⚠️ Review'
    WHEN p.price < 50
    AND SUM(oi.quantity) >= 10
    THEN 'High volume low price 💡 Consider raising'
    WHEN p.price < 50
    AND SUM(oi.quantity) < 5
    THEN 'Low price low volume ❌ Needs attention'
    ELSE 'Monitor ✅'
  END                                         AS pricing_insight
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY
  p.product_id,
  p.product_name,
  p.category,
  p.price,
  p.cost
ORDER BY total_revenue DESC;


-- ─────────────────────────────────────────────
-- FORMULA 19: DISCOUNT IMPACT ANALYSIS
-- "Are our discounts helping or hurting profit?"
-- ─────────────────────────────────────────────
/*
FORMULA:
Revenue Lost to Discount
= Unit Price × Quantity × Discount %

Simple meaning:
You sold 10 courses at $99.99
with 20% discount each:
Revenue Lost = $99.99 × 10 × 0.20
             = $199.98 in lost revenue

Was the discount worth it?
→ If discount brought new customers
   who return → Worth it
→ If existing customers who would
   have bought anyway got discount
   → You just gave money away 😂
*/

SELECT
  CASE
    WHEN oi.discount_pct = 0
    THEN 'No Discount'
    WHEN oi.discount_pct BETWEEN 1 AND 10
    THEN 'Low Discount 1-10%'
    WHEN oi.discount_pct BETWEEN 11 AND 20
    THEN 'Medium Discount 11-20%'
    ELSE 'High Discount 20%+'
  END                                         AS discount_band,
  COUNT(DISTINCT oi.order_id)                 AS total_orders,
  SUM(oi.quantity)                            AS units_sold,
  ROUND(SUM(oi.unit_price * oi.quantity), 2)  AS full_price_revenue,
  ROUND(SUM(oi.unit_price * oi.quantity
    * (1 - oi.discount_pct / 100)), 2)        AS actual_revenue,
  ROUND(SUM(oi.unit_price * oi.quantity
    * (oi.discount_pct / 100)), 2)            AS revenue_sacrificed,
  ROUND(SUM(oi.unit_price * oi.quantity
    * (oi.discount_pct / 100))
    / SUM(oi.unit_price * oi.quantity)
    * 100, 2)                                 AS pct_revenue_lost
FROM order_items oi
GROUP BY discount_band
ORDER BY actual_revenue DESC;


-- ─────────────────────────────────────────────
-- FORMULA 20: PRODUCT RECOMMENDATION MATRIX
-- The complete view — all formulas in one query
-- "Give me the full picture on every product"
-- ─────────────────────────────────────────────

WITH product_full AS (
  SELECT
    p.product_id,
    p.product_name,
    p.category,
    p.price,
    p.cost,
    ROUND(p.price - p.cost, 2)                AS profit_per_unit,
    ROUND((p.price - p.cost)
      / p.price * 100, 2)                     AS unit_margin_pct,
    SUM(oi.quantity)                          AS units_sold,
    ROUND(SUM(oi.unit_price * oi.quantity),2) AS total_revenue,
    ROUND(SUM((oi.unit_price - p.cost)
      * oi.quantity), 2)                      AS total_profit
  FROM products p
  JOIN order_items oi ON oi.product_id = p.product_id
  GROUP BY
    p.product_id,
    p.product_name,
    p.category,
    p.price,
    p.cost
)
SELECT
  product_name,
  category,
  price                                       AS selling_price,
  cost                                        AS product_cost,
  profit_per_unit,
  unit_margin_pct,
  units_sold,
  total_revenue,
  total_profit,
  RANK() OVER (
    ORDER BY total_revenue DESC)              AS revenue_rank,
  RANK() OVER (
    ORDER BY total_profit DESC)               AS profit_rank,
  RANK() OVER (
    ORDER BY unit_margin_pct DESC)            AS margin_rank,
  ROUND(total_revenue
    / SUM(total_revenue) OVER () * 100, 2)    AS pct_of_total_revenue,
  ROUND(total_profit
    / SUM(total_profit) OVER () * 100, 2)     AS pct_of_total_profit,
  CASE
    WHEN unit_margin_pct >= 70
    AND units_sold >= 3
    THEN '🔥 PROMOTE — High margin high volume'
    WHEN unit_margin_pct >= 70
    AND units_sold < 3
    THEN '📢 MARKET MORE — High margin needs volume'
    WHEN unit_margin_pct < 70
    AND units_sold >= 5
    THEN '💡 RAISE PRICE — High volume low margin'
    WHEN unit_margin_pct < 50
    AND units_sold < 3
    THEN '❌ REVIEW — Low margin low volume'
    ELSE '✅ MAINTAIN — Performing adequately'
  END                                         AS strategic_recommendation
FROM product_full
ORDER BY total_profit DESC;


-- ============================================================
-- MASTER FORMULA QUICK REFERENCE CHEAT SHEET
-- ============================================================

/*
FINANCIAL REPORT FORMULAS:
═══════════════════════════════════════════════════════════════
Formula               Calculation                 Tells You
───────────────────────────────────────────────────────────────
Total Revenue         Price × Quantity            Money in
Total Cost            Cost × Quantity             Money out
Gross Profit          Revenue - Cost              Raw profit
Gross Margin %        Profit ÷ Revenue × 100      % kept
Net Profit            Gross Profit - Expenses     Real profit
MoM Growth %          (Now-Before)÷Before × 100   Monthly trend
YoY Growth %          (Now-Before)÷Before × 100   Yearly trend
Running Total         Cumulative SUM              Progress to target

PROFITABILITY FORMULAS:
═══════════════════════════════════════════════════════════════
Formula               Calculation                 Tells You
───────────────────────────────────────────────────────────────
Profit per Unit       Price - Cost                Unit profit
Profit Margin %       Profit ÷ Price × 100        % margin
Break Even Units      Fixed Cost ÷ Contribution   Min units needed
LTV                   AOV × Frequency × Lifespan  Customer worth
ROI %                 (Revenue-Cost)÷Cost × 100   Investment return
ROAS                  Revenue ÷ Ad Spend           Ad return
AOV                   Revenue ÷ Orders             Avg order size
CAC                   Spend ÷ New Customers        Cost per customer
LTV:CAC Ratio         LTV ÷ CAC                   Business health

PRODUCT RECOMMENDATION FORMULAS:
═══════════════════════════════════════════════════════════════
Formula               Calculation                 Tells You
───────────────────────────────────────────────────────────────
Performance Score     Revenue + Margin + Volume   Overall rating
ABC Classification    Cumulative revenue %         Priority tier
Price vs Volume       Price level vs units sold    Pricing decision
Discount Impact       Revenue sacrificed %         Discount worth?
Full Matrix           All combined                 What to do next

BENCHMARKS TO ALWAYS REMEMBER:
═══════════════════════════════════════════════════════════════
Metric           Poor        OK          Good        Excellent
───────────────────────────────────────────────────────────────
Gross Margin     <20%        20-40%      40-70%      70%+
ROAS             <1.0        1-2         2-4         4+
ROI              <0%         0-100%      100-300%    300%+
LTV:CAC          <1          1-2         2-3         3+
CVR              <1%         1-2%        2-4%        4%+
Profit Margin    <10%        10-30%      30-60%      60%+
MoM Growth       <0%         0-5%        5-15%       15%+
*/

-- ============================================================
-- END OF COMPLETE FORMULA REFERENCE
-- Financial Reports | Profitability | Product Recommendations
-- Prepared by Nudekor Bright as Reference for answering Business questions 🔥
-- ============================================================
