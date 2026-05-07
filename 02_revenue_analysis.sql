-- Query 03: Revenue by Traffic Source (Week & Month)
WITH base AS (
  SELECT
    PARSE_DATE('%Y%m%d', date) AS dt
    , trafficSource.source AS source
    , product.productRevenue / 1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
  UNNEST(hits) AS hits,
  UNNEST(hits.product) AS product
  WHERE date BETWEEN '20170601' AND '20170630'
    AND product.productRevenue IS NOT NULL
)

SELECT
  'Month' AS time_type
  , FORMAT_DATE('%Y%m', dt) AS time
  , source
  , ROUND(SUM(revenue),4) AS revenue
FROM base
GROUP BY time, source

UNION ALL

SELECT
  'Week' AS time_type
  , FORMAT_DATE('%Y%V', dt) AS time
  , source
  , ROUND(SUM(revenue),4) AS revenue
FROM base
GROUP BY time, source

ORDER BY source, time_type, time; 

-- Query 04: Weekly & Cumulative Revenue Trend
WITH weekly_revenue AS (
  SELECT
    FORMAT_DATE('%G-%V', PARSE_DATE('%Y%m%d', date)) AS week
    , product.productRevenue / 1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`, 
  UNNEST(hits) AS hits,
  UNNEST(hits.product) AS product
  WHERE product.productRevenue IS NOT NULL
    AND PARSE_DATE('%Y%m%d', date) BETWEEN DATE '2017-05-01' AND DATE '2017-07-31'
)

SELECT
  week
  , ROUND(SUM(revenue), 2) AS weekly_revenue
  , ROUND(SUM(SUM(revenue)) OVER (ORDER BY week ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2) AS cumulative_revenue
FROM weekly_revenue
GROUP BY week
ORDER BY week;
