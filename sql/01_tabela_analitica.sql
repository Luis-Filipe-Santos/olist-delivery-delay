CREATE OR REPLACE TABLE analitica_pedidos AS
WITH itens AS (
    SELECT
        oi.order_id,
        COUNT(*)                                    AS n_itens,
        COUNT(DISTINCT oi.seller_id)                AS n_vendedores,
        SUM(oi.price)                               AS valor_produtos,
        SUM(oi.freight_value)                       AS valor_frete,
        SUM(p.product_weight_g)                     AS peso_total_g,
        arg_max(oi.seller_id, oi.price)             AS seller_id,
        arg_max(p.product_category_name, oi.price)  AS categoria_pt
    FROM order_items oi
    LEFT JOIN products p ON p.product_id = oi.product_id
    GROUP BY oi.order_id
)
SELECT
    o.order_id,
    c.customer_unique_id,
    c.customer_state,
    c.customer_city,
    s.seller_state,
    COALESCE(t.product_category_name_english, i.categoria_pt) AS categoria,
    i.n_itens,
    i.n_vendedores,
    i.valor_produtos,
    i.valor_frete,
    i.peso_total_g,
    o.order_purchase_timestamp      AS dt_compra,
    o.order_delivered_carrier_date  AS dt_postagem,
    o.order_delivered_customer_date AS dt_entrega,
    o.order_estimated_delivery_date AS dt_prometida,
    date_diff('day', CAST(o.order_purchase_timestamp AS DATE),
                     CAST(o.order_estimated_delivery_date AS DATE)) AS prazo_prometido_dias,
    date_diff('day', CAST(o.order_purchase_timestamp AS DATE),
                     CAST(o.order_delivered_customer_date AS DATE)) AS prazo_real_dias,
    date_diff('day', CAST(o.order_estimated_delivery_date AS DATE),
                     CAST(o.order_delivered_customer_date AS DATE)) AS dias_atraso,
    (CAST(o.order_delivered_customer_date AS DATE)
       > CAST(o.order_estimated_delivery_date AS DATE))              AS atrasado,
    COALESCE(o.order_delivered_customer_date < o.order_delivered_carrier_date, FALSE)
                                                                     AS data_inconsistente
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN itens i ON i.order_id = o.order_id
LEFT JOIN sellers s ON s.seller_id = i.seller_id
LEFT JOIN product_category_name_translation t ON t.product_category_name = i.categoria_pt
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL;