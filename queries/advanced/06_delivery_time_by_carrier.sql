-- Problema: comparar prazo real e pontualidade das transportadoras.
-- Solução: agregação condicional considera apenas entregas concluídas nas métricas de prazo.
SELECT
  carrier,
  shipment_count,
  delivered_count,
  late_count,
  average_delivery_hours,
  on_time_rate_percent,
  RANK() OVER (ORDER BY on_time_rate_percent DESC, average_delivery_hours) AS carrier_rank
FROM v_delivery_performance
ORDER BY carrier_rank, carrier;
