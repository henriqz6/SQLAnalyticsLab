CALL assert_true(
  (SELECT COUNT(*) FROM v_monthly_revenue) >= 20,
  'monthly_revenue_has_at_least_20_periods'
);

CALL assert_true(
  ABS(
    (SELECT COALESCE(SUM(revenue), 0) FROM v_monthly_revenue)
    -
    (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE status IN ('PAID','PROCESSING','SHIPPED','DELIVERED'))
  ) < 0.01,
  'monthly_revenue_matches_orders'
);

CALL assert_equals_bigint(
  120,
  (SELECT COUNT(*) FROM v_inventory_health),
  'inventory_view_has_every_product'
);

CALL assert_true(
  (SELECT COUNT(*) FROM v_inventory_health WHERE stock_status = 'LOW_STOCK') >= 7,
  'seed_contains_low_stock_scenarios'
);

CALL assert_true(
  fn_coupon_discount(500.00, 'PERCENTAGE', 10.00, 40.00) = 40.00,
  'coupon_percentage_respects_cap'
);

CALL assert_true(
  fn_coupon_discount(100.00, 'FIXED', 120.00, NULL) = 100.00,
  'coupon_never_exceeds_subtotal'
);
