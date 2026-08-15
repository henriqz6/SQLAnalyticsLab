SELECT coupon_id, COUNT(*) AS uses_count, SUM(discount_amount) AS discounts, SUM(total_amount) AS revenue
FROM orders
WHERE coupon_id IS NOT NULL AND status <> 'CANCELLED' AND placed_at >= '2025-01-01'
GROUP BY coupon_id
