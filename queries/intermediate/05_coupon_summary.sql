-- Desempenho consolidado dos cupons, inclusive cupons nunca usados.
SELECT
  code,
  discount_type,
  order_count,
  discount_granted,
  revenue_generated,
  average_ticket
FROM v_coupon_performance
ORDER BY revenue_generated DESC, code;
