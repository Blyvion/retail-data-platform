-- One row remains at the grain of the raw inventory table.
-- Dimension attributes are appended from each source table referenced
-- by a foreign-key relationship in sources.yml.

select
    i.*,
    st.* exclude (store_id),
    sk.* exclude (sku_id)
from {{ source('raw', 'inventory') }} as i
left join {{ source('raw', 'stores') }} as st
    on i.store_id = st.store_id
left join {{ source('raw', 'skus') }} as sk
    on i.sku_id = sk.sku_id