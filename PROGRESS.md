# Progresso

## Concluído

- [x] Modelo conceitual, lógico e físico
- [x] Migrations incrementais com PK, FK, unique, check, defaults e índices
- [x] Clientes, endereços, fornecedores, categorias, produtos e estoque
- [x] Pedidos, itens, cupons, pagamentos, entregas, devoluções e avaliações
- [x] Histórico de preço, estoque, estado do pedido e auditoria
- [x] Seed determinístico com 150 clientes, 120 produtos, 720 pedidos e 1.440 itens
- [x] Consultas básicas, intermediárias e avançadas
- [x] CTEs, subconsultas, `LAG`, `LEAD`, ranking e curva ABC
- [x] Sete views analíticas
- [x] Functions para desconto e segmento do cliente
- [x] Procedures transacionais para pedido, cancelamento e reposição
- [x] Triggers justificados para preço e auditoria
- [x] Testes de integridade, resultados, procedures, triggers e rollback
- [x] Coleta reproduzível de cinco planos antes/depois dos índices
- [x] Docker Compose, reset, comando único e CI
- [x] README, dicionário, modelos, guias e licença MIT

## Validação local

- Sintaxe de todos os scripts shell verificada com `sh -n`.
- Arquivos Docker Compose e GitHub Actions validados como YAML.
- A execução MySQL completa depende de Docker/MySQL 8.4; use `./scripts/run-all.sh` em um ambiente com Docker.

Não há funcionalidades pendentes na entrega.
