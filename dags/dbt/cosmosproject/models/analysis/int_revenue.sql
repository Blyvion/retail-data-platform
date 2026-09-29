-- sort items by highest total revenue
SELECT
    SKU_ID,
    SKU_NAME,
    SUM(TOTAL_VALUE) AS TOTAL_SALES
FROM {{ref('int_sales_conj')}}
GROUP BY
    SKU_ID,
    SKU_NAME
ORDER BY TOTAL_SALES DESC