SELECT oi.product_id, SUM(oi.quantity) AS units_sold, SUM(oi.line_total) AS revenue
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE oi.product_id BETWEEN 20 AND 40 AND o.status <> 'CANCELLED'
GROUP BY oi.product_id
