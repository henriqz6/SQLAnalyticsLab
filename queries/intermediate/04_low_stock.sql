-- Estoque baixo usa o ponto de reposição configurado por produto.
SELECT
  sku,
  name,
  available_quantity,
  reorder_point,
  stock_status
FROM v_inventory_health
WHERE stock_status IN ('LOW_STOCK','OUT_OF_STOCK')
ORDER BY available_quantity, name;
