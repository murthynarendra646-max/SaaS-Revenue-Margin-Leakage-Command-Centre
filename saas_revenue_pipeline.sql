CREATE OR REPLACE VIEW vw_clean_saas_revenue AS
WITH deduplicated_txns AS (
    SELECT DISTINCT
        transaction_id,
        CAST(order_date AS DATE) AS order_date,
        customer_id,
        plan_tier,
        billing_cycle,
        gross_mrr,
        discount_pct,
        INITCAP(TRIM(channel)) AS clean_channel,
        status
    FROM raw_saas_transactions
    WHERE gross_mrr > 0
)
SELECT
    DATE_TRUNC('month', order_date) AS revenue_month,
    clean_channel,
    plan_tier,
    COUNT(DISTINCT customer_id) AS active_customers,
    SUM(gross_mrr) AS total_gross_mrr,
    ROUND(SUM(gross_mrr * (1 - discount_pct / 100.0)), 2) AS total_net_mrr,
    ROUND(SUM(CASE WHEN discount_pct > 20 THEN gross_mrr * (discount_pct / 100.0) ELSE 0 END), 2) AS unauthorized_leakage
FROM deduplicated_txns
WHERE status = 'Active'
GROUP BY 1, 2, 3;
