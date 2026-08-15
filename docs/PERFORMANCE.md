# Estudo de desempenho

## Metodologia reproduzível

O script `scripts/collect-plans.sh` avalia cinco consultas:

1. faturamento mensal por período e estado;
2. pedidos recentes de um cliente;
3. vendas agregadas por produto;
4. uso e receita de cupons;
5. entregas atrasadas por estado e previsão.

Ele remove cinco índices analíticos, executa `EXPLAIN ANALYZE`, recria os índices e executa novamente. Os resultados reais do ambiente ficam em:

- `performance/results/before.txt`
- `performance/results/after.txt`

Esses arquivos são ignorados pelo Git porque contêm tempos e custos específicos da máquina. O repositório não inventa números de desempenho.

## Índices avaliados

| Índice | Colunas | Motivo |
|---|---|---|
| `idx_orders_placed_status` | `placed_at, status` | intervalo temporal é seletivo e inicia o acesso à consulta mensal |
| `idx_orders_customer_placed` | `customer_id, placed_at DESC` | igualdade no cliente seguida de histórico ordenado |
| `idx_orders_coupon_status` | `coupon_id, status, placed_at` | filtra cupom, estado válido e período |
| `idx_order_items_product_order` | `product_id, order_id` | começa pelo produto e alcança o pedido para validar estado |
| `idx_shipments_status_estimated` | `status, estimated_delivery_date` | reduz entregas por estado e faixa de previsão |

## Como interpretar

Compare o plano, não apenas o tempo:

- `Table scan` para `Index range scan` ou `Index lookup` sugere melhor acesso.
- Menos linhas examinadas tende a ser um ganho mais estável que uma única medição de tempo.
- `actual time` deve ser comparado na mesma máquina, após mais de uma execução.
- Índice também tem custo de armazenamento e escrita; por isso somente índices ligados a consultas concretas foram adicionados.

Com apenas centenas de linhas, o otimizador pode preferir varredura completa. Para estudo de seletividade, aumente o limite do seed e repita a coleta sem alterar as consultas.
