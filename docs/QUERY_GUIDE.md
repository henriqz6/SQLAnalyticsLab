# Guia das consultas

## Básicas

- `01_active_product_catalog.sql`: joins simples de catálogo, fornecedor e estoque.
- `02_customer_order_history.sql`: filtro por variável e ordenação temporal.
- `03_order_details.sql`: composição de um pedido e seus itens.

## Intermediárias

- `01_monthly_revenue.sql`: usa a view consolidada de faturamento.
- `02_average_ticket_by_status.sql`: ticket médio, mínimo e máximo por estado.
- `03_late_orders.sql`: atraso real ou prazo vencido ainda sem entrega.
- `04_low_stock.sql`: saldo comparado ao ponto de reposição individual.
- `05_coupon_summary.sql`: descontos e receita de cada cupom.

## Avançadas

| Arquivo | Técnica principal | Pergunta respondida |
|---|---|---|
| `01_month_over_month_revenue.sql` | CTE, `LAG`, `LEAD` | Como o faturamento mudou em relação ao mês anterior? |
| `02_best_sellers_and_returns.sql` | CTEs independentes | Quais produtos mais vendem e quais mais retornam? |
| `03_category_revenue.sql` | window rank | Quais categorias geram mais receita sem dupla contagem? |
| `04_new_vs_recurring_customers.sql` | CTE e primeira compra | Quantos clientes do mês são novos ou recorrentes? |
| `05_customers_without_recent_purchase.sql` | `LEFT JOIN` e `HAVING` | Quem está há 180 dias sem comprar ou nunca comprou? |
| `06_delivery_time_by_carrier.sql` | agregação condicional e rank | Qual transportadora é mais rápida e pontual? |
| `07_cancellation_and_return_rates.sql` | CTEs com denominadores distintos | Quais são as taxas mensais de cancelamento e devolução? |
| `08_inventory_and_stagnant_products.sql` | classificação por regra | O que precisa de reposição ou revisão por falta de giro? |
| `09_coupon_incremental_analysis.sql` | grupos observacionais | Como pedidos com e sem cupom se comparam? |
| `10_customer_ranking.sql` | `DENSE_RANK` e soma acumulada | Quais clientes lideram em LTV e curva ABC? |
| `11_product_abc_curve.sql` | participação acumulada | Quais produtos concentram 80%/95% da receita? |
| `12_supplier_profitability.sql` | snapshot de custo | Qual fornecedor gera mais margem bruta? |

As consultas que usam `@analysis_date` adotam `2026-08-01`, a data de referência do seed. Troque a variável para analisar outro corte temporal.
