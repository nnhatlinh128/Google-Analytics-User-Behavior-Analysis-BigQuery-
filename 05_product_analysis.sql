-- Query 09: Revenue Contribution by Device
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

-- Query 10: Cross-Sell Product Analysis
with 
buyer_list as(
    SELECT
        distinct fullVisitorId  
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    , UNNEST(hits) AS hits
    , UNNEST(hits.product) as product
    WHERE product.v2ProductName = "YouTube Men's Vintage Henley"
    AND totals.transactions>=1
    AND product.productRevenue is not null
)

SELECT
  product.v2ProductName AS other_purchased_products,
  SUM(product.productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
, UNNEST(hits) AS hits
, UNNEST(hits.product) as product
JOIN buyer_list using(fullVisitorId)
WHERE product.v2ProductName != "YouTube Men's Vintage Henley"
 and product.productRevenue is not null
 AND totals.transactions>=1
GROUP BY other_purchased_products
ORDER BY quantity DESC;