-- =====================================================================
--  MAISON AURELLE - Luxury Clienteling & CRM Analysis
--  Practice SQL file (SQLite / DB Browser for SQLite)
--
--  How to use: in DB Browser, open the "Execute SQL" tab, paste ONE
--  query at a time (or highlight it), and press Ctrl+Enter to run it.
--  Lines starting with -- are comments: SQL ignores them.
--
--  Analysis date: 2026-10-31 (the last day in the data).
-- =====================================================================


-- ---------------------------------------------------------------------
--  LEVEL 1 - LOOKING AT THE DATA
-- ---------------------------------------------------------------------

-- 1.1  Show the first 10 rows of the transactions table
SELECT *
FROM transactions
LIMIT 10;

-- 1.2  How many clients do we have?
SELECT COUNT(*) AS number_of_clients
FROM clients;

-- 1.3  Only French clients who accept marketing (WHERE = filter)
SELECT client_id, nationality, preferred_contact
FROM clients
WHERE nationality = 'French'
  AND marketing_opt_in = 'Yes';

-- 1.4  The 10 most expensive products (ORDER BY = sort)
SELECT product_name, category, price_eur
FROM products
ORDER BY price_eur DESC
LIMIT 10;


-- ---------------------------------------------------------------------
--  LEVEL 2 - SUMMARISING (GROUP BY)
-- ---------------------------------------------------------------------

-- 2.1  Headline KPIs for the whole business
SELECT
    COUNT(DISTINCT client_id)            AS active_clients,
    COUNT(*)                             AS transactions,
    SUM(amount_eur)                      AS total_revenue_eur,
    ROUND(AVG(amount_eur), 0)            AS avg_ticket_eur
FROM transactions;

-- 2.2  Revenue per year
SELECT
    strftime('%Y', transaction_date)     AS year,
    SUM(amount_eur)                      AS revenue_eur,
    COUNT(DISTINCT client_id)            AS clients
FROM transactions
GROUP BY year
ORDER BY year;

-- 2.3  Revenue by sales channel
SELECT channel,
       COUNT(*)                          AS transactions,
       SUM(amount_eur)                   AS revenue_eur,
       ROUND(AVG(amount_eur), 0)         AS avg_ticket_eur
FROM transactions
GROUP BY channel
ORDER BY revenue_eur DESC;


-- ---------------------------------------------------------------------
--  LEVEL 3 - COMBINING TABLES (JOIN)
-- ---------------------------------------------------------------------

-- 3.1  Revenue by boutique (transactions + boutiques)
SELECT b.boutique_name,
       b.city,
       SUM(t.amount_eur)                 AS revenue_eur,
       COUNT(DISTINCT t.client_id)       AS clients
FROM transactions t
JOIN boutiques b ON t.boutique_id = b.boutique_id
GROUP BY b.boutique_name, b.city
ORDER BY revenue_eur DESC;

-- 3.2  Revenue by product category
SELECT p.category,
       SUM(t.amount_eur)                 AS revenue_eur,
       ROUND(100.0 * SUM(t.amount_eur) / (SELECT SUM(amount_eur) FROM transactions), 1) AS share_pct
FROM transactions t
JOIN products p ON t.product_id = p.product_id
GROUP BY p.category
ORDER BY revenue_eur DESC;

-- 3.3  Revenue by client nationality
SELECT c.nationality,
       COUNT(DISTINCT c.client_id)       AS clients,
       SUM(t.amount_eur)                 AS revenue_eur,
       ROUND(SUM(t.amount_eur) * 1.0 / COUNT(DISTINCT c.client_id), 0) AS revenue_per_client_eur
FROM transactions t
JOIN clients c ON t.client_id = c.client_id
GROUP BY c.nationality
ORDER BY revenue_eur DESC;

-- 3.4  Sales associate leaderboard
SELECT a.associate_name,
       b.city,
       COUNT(DISTINCT t.client_id)       AS clients_served,
       SUM(t.amount_eur)                 AS revenue_eur
FROM transactions t
JOIN sales_associates a ON t.associate_id = a.associate_id
JOIN boutiques b        ON a.boutique_id  = b.boutique_id
GROUP BY a.associate_name, b.city
ORDER BY revenue_eur DESC;


-- ---------------------------------------------------------------------
--  LEVEL 4 - THE CRM CORE: RFM SEGMENTATION
--  R = Recency   : days since the client's last purchase (lower = better)
--  F = Frequency : number of purchases
--  M = Monetary  : total amount spent
-- ---------------------------------------------------------------------

-- 4.1  One row per client with R, F and M
SELECT client_id,
       CAST(julianday('2026-10-31') - julianday(MAX(transaction_date)) AS INTEGER) AS recency_days,
       COUNT(*)                          AS frequency,
       SUM(amount_eur)                   AS monetary_eur
FROM transactions
GROUP BY client_id
ORDER BY monetary_eur DESC;

-- 4.2  Give each client a score from 1 to 5 on R, F and M, then a segment.
--      NTILE(5) splits clients into 5 equal groups (quintiles).
--      THIS IS THE TABLE YOU WILL EXPORT TO POWER BI  (save as rfm.csv)
WITH rfm AS (
    SELECT client_id,
           CAST(julianday('2026-10-31') - julianday(MAX(transaction_date)) AS INTEGER) AS recency_days,
           COUNT(*)                      AS frequency,
           SUM(amount_eur)               AS monetary_eur,
           MIN(transaction_date)         AS first_purchase,
           MAX(transaction_date)         AS last_purchase
    FROM transactions
    GROUP BY client_id
),
scores AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,   -- recent = 5
           NTILE(5) OVER (ORDER BY frequency ASC)     AS f_score,   -- frequent = 5
           NTILE(5) OVER (ORDER BY monetary_eur ASC)  AS m_score    -- big spender = 5
    FROM rfm
)
SELECT *,
       CASE
           WHEN r_score >= 4 AND f_score = 5  AND m_score = 5  THEN 'VIC (Champions)'
           WHEN r_score >= 3 AND f_score >= 3                  THEN 'Loyal'
           WHEN r_score >= 4 AND f_score <= 2                  THEN 'New / Promising'
           WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
           WHEN r_score <= 2 AND f_score <= 2                  THEN 'Dormant'
           ELSE 'Needs Attention'
       END AS segment
FROM scores
ORDER BY monetary_eur DESC;

-- 4.3  Summary per segment: how many clients and how much revenue?
--      (Copy query 4.2's WITH ... block above this, or run after creating a view - see 4.4)

-- 4.4  Save query 4.2 as a reusable VIEW (a saved query you can call like a table)
DROP VIEW IF EXISTS client_rfm;
CREATE VIEW client_rfm AS
WITH rfm AS (
    SELECT client_id,
           CAST(julianday('2026-10-31') - julianday(MAX(transaction_date)) AS INTEGER) AS recency_days,
           COUNT(*)                      AS frequency,
           SUM(amount_eur)               AS monetary_eur,
           MIN(transaction_date)         AS first_purchase,
           MAX(transaction_date)         AS last_purchase
    FROM transactions
    GROUP BY client_id
),
scores AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
           NTILE(5) OVER (ORDER BY frequency ASC)     AS f_score,
           NTILE(5) OVER (ORDER BY monetary_eur ASC)  AS m_score
    FROM rfm
)
SELECT *,
       CASE
           WHEN r_score >= 4 AND f_score = 5  AND m_score = 5  THEN 'VIC (Champions)'
           WHEN r_score >= 3 AND f_score >= 3                  THEN 'Loyal'
           WHEN r_score >= 4 AND f_score <= 2                  THEN 'New / Promising'
           WHEN r_score <= 2 AND f_score >= 3                  THEN 'At Risk'
           WHEN r_score <= 2 AND f_score <= 2                  THEN 'Dormant'
           ELSE 'Needs Attention'
       END AS segment
FROM scores;

-- 4.5  Segment summary (needs the view from 4.4)
SELECT segment,
       COUNT(*)                                        AS clients,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM client_rfm), 1)               AS pct_clients,
       SUM(monetary_eur)                               AS revenue_eur,
       ROUND(100.0 * SUM(monetary_eur) / (SELECT SUM(monetary_eur) FROM client_rfm), 1) AS pct_revenue,
       ROUND(AVG(recency_days), 0)                     AS avg_days_since_last_purchase
FROM client_rfm
GROUP BY segment
ORDER BY revenue_eur DESC;


-- ---------------------------------------------------------------------
--  LEVEL 5 - BUSINESS ACTIONS (the part that impresses recruiters)
-- ---------------------------------------------------------------------

-- 5.1  "Call list": At-Risk high spenders who accept marketing,
--      with their sales associate and preferred contact channel
SELECT r.client_id,
       c.nationality,
       c.preferred_contact,
       b.city                            AS home_boutique,
       r.monetary_eur,
       r.recency_days,
       r.last_purchase
FROM client_rfm r
JOIN clients   c ON r.client_id = c.client_id
JOIN boutiques b ON c.home_boutique_id = b.boutique_id
WHERE r.segment = 'At Risk'
  AND r.m_score >= 4
  AND c.marketing_opt_in = 'Yes'
ORDER BY r.monetary_eur DESC;

-- 5.2  Revenue at risk: total historical spend of At-Risk clients
SELECT COUNT(*)              AS at_risk_clients,
       SUM(monetary_eur)     AS historical_spend_eur
FROM client_rfm
WHERE segment = 'At Risk';

-- 5.3  Retention: of clients who first bought in a given year,
--      how many bought again in a LATER year?
WITH firsts AS (
    SELECT client_id, MIN(strftime('%Y', transaction_date)) AS first_year
    FROM transactions
    GROUP BY client_id
)
SELECT f.first_year,
       COUNT(DISTINCT f.client_id)                                      AS new_clients,
       COUNT(DISTINCT CASE WHEN strftime('%Y', t.transaction_date) > f.first_year
                           THEN t.client_id END)                        AS came_back,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN strftime('%Y', t.transaction_date) > f.first_year
                                         THEN t.client_id END)
             / COUNT(DISTINCT f.client_id), 1)                          AS retention_pct
FROM firsts f
JOIN transactions t ON f.client_id = t.client_id
GROUP BY f.first_year
ORDER BY f.first_year;

-- 5.4  Cross-selling: which categories do leather-goods buyers ALSO buy?
SELECT p2.category                       AS also_bought,
       COUNT(DISTINCT t2.client_id)      AS clients
FROM transactions t1
JOIN products p1     ON t1.product_id = p1.product_id AND p1.category = 'Leather Goods'
JOIN transactions t2 ON t1.client_id  = t2.client_id
JOIN products p2     ON t2.product_id = p2.product_id AND p2.category <> 'Leather Goods'
GROUP BY p2.category
ORDER BY clients DESC;
