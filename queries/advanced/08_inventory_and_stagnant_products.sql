-- Problema: combinar risco de ruptura com produtos sem giro recente.
-- Solução: a view centraliza saldo/última venda e a consulta classifica a prioridade.
SET @analysis_date = '2026-08-01';

SELECT
  sku,
  name,
  available_quantity,
  reorder_point,
  stock_status,
  last_sale_at,
  CASE
    WHEN stock_status IN ('LOW_STOCK','OUT_OF_STOCK') THEN 'RESTOCK_NOW'
    WHEN last_sale_at IS NULL OR last_sale_at < @analysis_date - INTERVAL 180 DAY THEN 'REVIEW_STAGNANT'
    ELSE 'MONITOR'
  END AS recommended_action
FROM v_inventory_health
WHERE stock_status <> 'HEALTHY'
   OR last_sale_at IS NULL
   OR last_sale_at < @analysis_date - INTERVAL 180 DAY
ORDER BY FIELD(recommended_action, 'RESTOCK_NOW','REVIEW_STAGNANT','MONITOR'), available_quantity;
