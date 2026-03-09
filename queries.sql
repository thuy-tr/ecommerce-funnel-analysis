-- E-commerce Funnel Analysis --
-- SQL queries used in this project


-- 1. Inspect dataset

SELECT *
FROM `project-a9ddc777-7d09-4bf5-88e.sql_projects.User events`
LIMIT 50;


-- 2. Funnel stage counts
-- How many users reach each stage


SELECT
COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS page_views,
COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS add_to_cart,
COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS checkout_start,
COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS payment_info,
COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchases
FROM `project-a9ddc777-7d09-4bf5-88e.sql_projects.User events`;


-- 3. Funnel conversion rates

WITH funnel_counts AS (

SELECT
COUNT(DISTINCT CASE WHEN event_type = 'page_view' THEN user_id END) AS page_views,
COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS add_to_cart,
COUNT(DISTINCT CASE WHEN event_type = 'checkout_start' THEN user_id END) AS checkout_start,
COUNT(DISTINCT CASE WHEN event_type = 'payment_info' THEN user_id END) AS payment_info,
COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS purchases

FROM `project-a9ddc777-7d09-4bf5-88e.sql_projects.User events`

)

SELECT
page_views,
add_to_cart,
checkout_start,
payment_info,
purchases,

ROUND(add_to_cart / page_views * 100,2) AS view_to_cart_rate,
ROUND(checkout_start / add_to_cart * 100,2) AS cart_to_checkout_rate,
ROUND(payment_info / checkout_start * 100,2) AS checkout_to_payment_rate,
ROUND(purchases / payment_info * 100,2) AS payment_to_purchase_rate,
ROUND(purchases / page_views * 100,2) AS overall_conversion_rate

FROM funnel_counts;

-- 4. Traffic source performance

WITH events AS (

SELECT
user_id,
event_type,
TIMESTAMP(event_date) AS event_ts,
traffic_source

FROM `project-a9ddc777-7d09-4bf5-88e.sql_projects.User events`

),

first_touch AS (

SELECT
user_id,
ARRAY_AGG(traffic_source ORDER BY event_ts LIMIT 1)[OFFSET(0)] AS first_source
FROM events
GROUP BY user_id

),

user_funnel AS (

SELECT
user_id,
MAX(CASE WHEN event_type = 'add_to_cart' THEN 1 ELSE 0 END) AS add_to_cart,
MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS purchased
FROM events
GROUP BY user_id

)

SELECT
f.first_source,
COUNT(*) AS users,
SUM(u.add_to_cart) AS add_to_cart_users,
SUM(u.purchased) AS purchasers,
ROUND(SUM(u.purchased)/COUNT(*) * 100,2) AS conversion_rate

FROM first_touch f
JOIN user_funnel u
ON f.user_id = u.user_id

GROUP BY f.first_source
ORDER BY conversion_rate DESC;


-- 5. Revenue by traffic source

WITH events AS (

SELECT
user_id,
event_type,
TIMESTAMP(event_date) AS event_ts,
amount,
traffic_source

FROM `project-a9ddc777-7d09-4bf5-88e.sql_projects.User events`

),

first_touch AS (

SELECT
user_id,
ARRAY_AGG(traffic_source ORDER BY event_ts LIMIT 1)[OFFSET(0)] AS first_source
FROM events
GROUP BY user_id

),

purchases AS (

SELECT
user_id,
amount
FROM events
WHERE event_type = 'purchase'

)

SELECT
f.first_source,
COUNT(p.user_id) AS purchases,
ROUND(SUM(p.amount),2) AS revenue,
ROUND(AVG(p.amount),2) AS avg_order_value

FROM first_touch f
JOIN purchases p
ON f.user_id = p.user_id

GROUP BY f.first_source
ORDER BY revenue DESC;


-- 6. Product performance

SELECT
product_id,
COUNT(*) AS purchases,
COUNT(DISTINCT user_id) AS buyers,
ROUND(SUM(amount),2) AS revenue,
ROUND(AVG(amount),2) AS avg_order_value

FROM `project-a9ddc777-7d09-4bf5-88e.sql_projects.User events`

WHERE event_type = 'purchase'

GROUP BY product_id
ORDER BY revenue DESC;