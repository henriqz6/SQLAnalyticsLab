# Dicionário de dados

| Tabela | Finalidade | Chave e observações principais |
|---|---|---|
| `customers` | Cadastro de clientes fictícios | e-mail único; estado ativo/inativo/bloqueado |
| `addresses` | Endereços de entrega | pertence a um cliente; CEP de oito dígitos |
| `suppliers` | Fornecedores do catálogo | CNPJ fictício único e prazo de reposição |
| `categories` | Hierarquia de categorias | `parent_category_id` permite subcategorias |
| `products` | Catálogo de produtos | SKU único, fornecedor, custo e preço de venda |
| `product_categories` | Relação N:N produto/categoria | marca uma categoria como principal |
| `product_price_history` | Histórico de preço | preço antigo/novo, data e responsável |
| `inventory` | Saldo atual | quantidade física, reservada e ponto de reposição |
| `inventory_movements` | Livro de movimentos | mudança com sinal, saldo posterior e referência |
| `coupons` | Regras promocionais | percentual/fixo, vigência, mínimo e limite de uso |
| `orders` | Cabeçalho do pedido | cliente, endereço, estado e totais financeiros |
| `order_items` | Itens adquiridos | snapshot de SKU/nome/preço/custo; total gerado |
| `payments` | Tentativas e confirmações | método, estado, valor e referência externa fictícia |
| `shipments` | Entrega do pedido | transportadora, rastreio, previsão e datas reais |
| `returns` | Solicitação de devolução | estado, datas, total reembolsado e observação |
| `return_items` | Itens devolvidos | quantidade, motivo, condição e reembolso |
| `reviews` | Avaliação de compra | nota 1–5 associada ao item comprado |
| `order_status_history` | Linha do tempo do pedido | estado anterior/novo, motivo e ator |
| `audit_log` | Auditoria técnica | entidade, ação e valores JSON antes/depois |

## Views

| View | Uso |
|---|---|
| `v_order_financials` | receita, custo e margem bruta por pedido |
| `v_monthly_revenue` | faturamento e ticket mensal |
| `v_customer_360` | pedidos, LTV, ticket e recência do cliente |
| `v_product_performance` | vendas, devoluções, avaliação e última venda |
| `v_inventory_health` | saldo disponível, risco de ruptura e giro |
| `v_delivery_performance` | prazo e pontualidade por transportadora |
| `v_coupon_performance` | uso, desconto e receita por cupom |
