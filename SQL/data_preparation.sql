-- SAMMY'S SPORTS ONLINE SALES & CUSTOMER ANALYSIS
-- SQL DATA CLEANING, GATHERING KEY INSIGHTS, and TRANSFORMATION SCRIPT
-- Author: Juan Calzada Elorriaga

-- 1. Cleaned the "State" field 
-- Removed leading, trailing, and multiple internal spaces
SELECT
COUNT(*) AS count,
REGEXP_REPLACE(TRIM("State"), '\s+', ' ', 'g') AS state_cleaned,
LENGTH(REGEXP_REPLACE(TRIM("State"), '\s+', ' ', 'g')) AS length_cleaned,
"State"
FROM raw_customers
GROUP BY state_cleaned, "State";
-- Add the cleaned column to raw_customers
ALTER TABLE raw_customers ADD COLUMN state_cleaned TEXT;
UPDATE raw_customers
SET state_cleaned = REGEXP_REPLACE(TRIM("State"), '\s+', ' ', 'g');

-- 2. Fixing customer_id. Since it had unnecessary characters.
-- Extract the clean customer ID
SELECT SUBSTRING(customer_id, 9, 6) FROM raw_customers;

-- Add column and update
ALTER TABLE raw_customers ADD COLUMN customer_id_corrected TEXT;
UPDATE raw_customers
SET customer_id_corrected = SUBSTRING(customer_id, 9, 6);

-- 3. Cleaning order_id. 
-- Extract numeric portion of order ID
SELECT SUBSTRING(order_id::text, 5, 5) AS order_id_corrected FROM raw_orders;
-- Add column and update
ALTER TABLE raw_orders ADD COLUMN order_id_corrected INT;
UPDATE raw_orders
SET order_id_corrected = SUBSTRING(order_id::text, 5, 5)::INTEGER;

-- 4. Formatting revenue 
-- Pad with leading 0s (display)
UPDATE raw_orders
SET revenue_corrected = LPAD(revenue::text, 6, '0');

-- 5. Formatig profit
-- Pad with leading 0s (display)
UPDATE raw_orders
SET profit_corrected = LPAD(profit::text,6,'0')

-- 6. Capitalize the sport field 
ALTER TABLE raw_orders ADD COLUMN sports_corrected TEXT;
UPDATE raw_orders
SET sports_corrected = CONCAT(UPPER(LEFT(sport,1)), LOWER(SUBSTRING(sport,2,LENGTH(sport))));

-- 7. Inner join the cleaned tables 
SELECT
  rc.customer_id_corrected,
  rc.first_name,
  rc.last_name,
  ro.customer_id_corrected,
  ro.sports_corrected,
  rc.state_cleaned,
  ro.date,
  ro.profit,
  ro.revenue,
  ro.shipping_cost
FROM raw_customers rc
INNER JOIN raw_orders ro ON rc.customer_id_corrected = ro.customer_id_corrected;

-- Collecting key metrics and insights --------------------------------------------------------------------
-- 1. Total purchases and % by sport
SELECT 
sport,
COUNT(*) AS total_purchases,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage_of_total
FROM raw_orders
GROUP BY sport;

-- 2. Average purchased per customer (baseball example)
SELECT
COUNT(*) * 1.0 / COUNT(DISTINCT customer_id) AS avg_baseball_purchased
FROM raw_orders
WHERE sport = 'baseball';

-- 3. Since I had the shipping cost column empty, I decided to make a case.
-- The shipping cost % will vary by sport. Football(12%), hockey(11%), baseball(10%), basketball(9%), and soccer(8%).
UPDATE raw_orders
SET shipping_cost = CASE 
WHEN sports_corrected = 'Football' THEN revenue * 0.12
WHEN sports_corrected = 'Hockey' THEN revenue * 0.11
WHEN sports_corrected = 'Baseball' THEN revenue * 0.10
WHEN sports_corrected = 'Basketball' THEN revenue * 0.09
WHEN sports_corrected = 'Soccer' THEN revenue * 0.08
ELSE NULL
END;
-- Update the table 
UPDATE raw_orders
SET shipping_cost = ROUND(shipping_cost,2)

-- 4. Total revenue and profit by sport
SELECT 
sports_corrected AS sport,
ROUND(SUM(revenue), 2) AS total_revenue, 
ROUND(SUM(profit), 2) AS total_profit, 
COUNT(*) AS total_orders 
FROM full_customer_orders
GROUP BY sport
ORDER BY total_revenue desc

-- 5. Total revenue and profit by state
SELECT 
state_cleaned,
ROUND(SUM(revenue), 2) AS total_revenue_per_state,
ROUND(SUM(profit), 2) AS total_profit_per_state,
COUNT(*) AS orders_per_state
FROM full_customer_orders
GROUP BY state_cleaned
ORDER by total_revenue_per_state DESC

-- 6. Average profit margin by sport
SELECT
sports_corrected,
ROUND(AVG(profit/revenue)*100, 2) AS avg_profit_margin_percentage 
FROM full_customer_orders
GROUP BY sports_corrected 
ORDER BY avg_profit_margin_percentage DESC

-- 7. Average profit margin by state
SELECT 
state_cleaned,
ROUND(AVG(profit/revenue)*100, 2) AS avg_profit_margin_per_state
FROM full_customer_orders
GROUP BY state_cleaned
ORDER BY avg_profit_margin_per_state DESC

-- 8. Most Popular Sport by State
SELECT DISTINCT ON (state_cleaned) 
state_cleaned AS state, 
sports_corrected AS top_sports, 
COUNT(*) OVER (PARTITION BY state_cleaned, sports_corrected) AS sport_orders 
FROM full_customer_orders
ORDER BY state_cleaned, sport_orders DESC

-- 9. Average rating per sport + average rating per state + rating count by State
SELECT
state_cleaned AS states,
sports_corrected AS sports,
ROUND(AVG(rating), 2) AS avg_rating_per_state, 
COUNT(rating) AS rating_count 
FROM full_customer_orders
WHERE rating IS NOT NULL
GROUP BY states, sports
ORDER by avg_rating_per_state

-- 10. Rating VS profit/revenue
SELECT
state_cleaned AS states,
ROUND(AVG(rating), 2) AS Average_Rating,
ROUND(AVG(profit), 2) AS Average_Profit,
ROUND(AVG(revenue), 2) AS Average_Revenue
FROM full_customer_orders
WHERE rating IS NOT NULL
GROUP BY states
ORDER BY Average_Revenue DESC

-- 11. National average across all orders that had a rating
SELECT
ROUND(AVG(rating), 2) AS avg_rating,
ROUND(AVG(profit), 2) AS avg_profit,
ROUND(AVG(revenue), 2) AS avg_revenue
FROM full_customer_orders
WHERE rating IS NOT NULL;



