-- One row remains at the grain of the raw sales table.
-- Dimension attributes are appended from each source table referenced
-- by a foreign-key relationship in sources.yml.

select
    s.* exclude (unit_price),
    s.unit_price as sales_unit_price,

    st.* exclude (store_id, city),
    st.city as store_city,

    sk.* exclude (sku_id, unit_price),
    sk.unit_price as sku_unit_price,

    c.* exclude (cust_id, city),
    c.city as customer_city

from {{ source('raw', 'sales') }} as s

left join {{ source('raw', 'stores') }} as st
    on s.store_id = st.store_id

left join {{ source('raw', 'skus') }} as sk
    on s.sku_id = sk.sku_id

left join {{ source('raw', 'customers') }} as c
    on s.customer_id = c.cust_id