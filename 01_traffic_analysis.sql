-- Query 01: Monthly Traffic Overview
SELECT
  format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
  SUM(totals.visits) AS visits,
  SUM(totals.pageviews) AS pageviews,
  SUM(totals.transactions) AS transactions,
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
GROUP BY 1
ORDER BY 1;

-- Query 02: Bounce Rate by Traffic Source
SELECT trafficSource.source
  , COUNT(totals.visits) AS total_visits
  , COUNT(totals.bounces) AS total_no_of_bounces
  , ROUND(COUNT(totals.bounces)/ COUNT(totals.visits) * 100, 3) AS bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _table_suffix BETWEEN '0701'AND '0731'
GROUP BY trafficSource.source
ORDER BY total_visits DESC;