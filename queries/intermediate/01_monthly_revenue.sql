-- Faturamento mensal considera somente estados que representam receita reconhecida.
SELECT month_start, order_count, unique_customers, revenue, average_ticket
FROM v_monthly_revenue
ORDER BY month_start;
