# User Behavior Analysis

## Project Overview

This project analyzes the Google Analytics public dataset in BigQuery to explore user behavior, traffic quality, conversion performance, and revenue contribution in an e-commerce environment using SQL.

The analysis focuses on transforming raw session-level data into business insights through traffic analysis, revenue analysis, conversion funnel analysis, and user behavior exploration.

---

## Dataset

- Source: Google Analytics Sample Dataset
- Platform: BigQuery Public Dataset
- Table used: `ga_sessions_2017*`

The dataset contains:
- User sessions
- Traffic acquisition sources
- Product interactions
- Transactions
- Device information

---

## Objectives

- Analyze traffic and engagement performance
- Identify revenue-driving traffic sources
- Evaluate conversion funnel performance
- Compare purchaser and non-purchaser behavior
- Analyze revenue contribution across devices

---

## Project Walkthrough
### 1. Traffic & Engagement Analysis

#### Business Question
Which traffic sources bring the most engaged users?

#### SQL Query

```sql
SELECT trafficSource.source
  , COUNT(totals.visits) AS total_visits
  , COUNT(totals.bounces) AS total_no_of_bounces
  , ROUND(COUNT(totals.bounces)/ COUNT(totals.visits) * 100, 3) AS bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _table_suffix BETWEEN '0701'AND '0731'
GROUP BY trafficSource.source
ORDER BY total_visits DESC;
```
#### Result

<img width="679" height="459" alt="Screenshot 2026-05-07 at 17 30 53" src="https://github.com/user-attachments/assets/c4366ab0-9cf6-41a8-b0b5-dbd5c81455d3" />

#### Key Insight

Google drives the highest traffic volume, while YouTube shows a significantly higher bounce rate, indicating lower engagement quality.

### 2. Revenue Analysis

#### Business Question
Which traffic sources contribute the most revenue?

#### SQL Query

```sql
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
```

#### Result

<img width="786" height="486" alt="Screenshot 2026-05-07 at 17 32 52" src="https://github.com/user-attachments/assets/19bfd9bc-1bef-4afd-b1df-3188ac3e0ba1" />

#### Key Insight

Direct traffic contributes the highest revenue in June 2017, while revenue fluctuates noticeably across different weeks.

### 3. Device Revenue Analysis

#### Business Question
How does revenue contribution vary across devices?

#### SQL Query

```sql
with 
raw_data as (
  SELECT
    device.deviceCategory AS device
    ,SUM(productRevenue)/1000000 AS revenue_by_device
    ,(SELECT SUM(productRevenue)/1000000 AS total_revenue
      from `bigquery-public-data.google_analytics_sample.ga_sessions_*`
            ,unnest(hits) hits
          ,unnest(product) product
      where totals.transactions>=1
        and product.productRevenue is not null) as total_revenue
  from  `bigquery-public-data.google_analytics_sample.ga_sessions_*`
        ,unnest(hits) hits
      ,unnest(product) product
  where totals.transactions>=1
    and product.productRevenue is not null
  GROUP BY device
  ORDER BY revenue_by_device DESC)

select
  device
  ,revenue_by_device
  ,total_revenue
  ,round(100.00*(revenue_by_device/total_revenue),2) as ratio
from raw_data;
```

#### Result

<img width="636" height="109" alt="Screenshot 2026-05-07 at 17 33 54" src="https://github.com/user-attachments/assets/473d6c67-dd4d-4596-bcf0-e1fc0e392300" />

#### Key Insight

Desktop contributes more than 96% of total revenue, while mobile revenue remains relatively low.

### 4. Conversion Funnel Analysis 

#### Business Question
Where do users drop off in the purchase journey?

#### SQL Query

```sql
with
product_view as(
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    count(product.productSKU) as num_product_view
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  , UNNEST(hits) AS hits
  , UNNEST(hits.product) as product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  AND hits.eCommerceAction.action_type = '2'
  GROUP BY 1
),

add_to_cart as(
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    count(product.productSKU) as num_addtocart
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  , UNNEST(hits) AS hits
  , UNNEST(hits.product) as product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  AND hits.eCommerceAction.action_type = '3'
  GROUP BY 1
),

purchase as(
  SELECT
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    count(product.productSKU) as num_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  , UNNEST(hits) AS hits
  , UNNEST(hits.product) as product
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
  AND hits.eCommerceAction.action_type = '6'
  and product.productRevenue is not null   
  group by 1
)

select
    pv.*,
    num_addtocart,
    num_purchase,
    round(num_addtocart*100/num_product_view,2) as add_to_cart_rate,
    round(num_purchase*100/num_product_view,2) as purchase_rate
from product_view pv
left join add_to_cart a on pv.month = a.month
left join purchase p on pv.month = p.month
order by pv.month;
```

#### Result

<img width="882" height="109" alt="Screenshot 2026-05-07 at 17 34 33" src="https://github.com/user-attachments/assets/4409f79b-1b3c-43ee-8a86-2c339701d8d9" />


#### Key Insight

A significant drop occurs between product views and add-to-cart actions, indicating friction in the conversion funnel.
