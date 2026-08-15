# Transações e falha segura

As procedures `sp_create_order`, `sp_cancel_order` e `sp_restock_product` usam `START TRANSACTION`, bloqueio `FOR UPDATE`, `COMMIT` e um handler que executa `ROLLBACK` antes de propagar a falha.

No teste `tests/040_transaction_rollback_test.sql`, a transação:

1. reduz o estoque de um produto;
2. tenta inserir um fornecedor com chave única duplicada;
3. recebe erro;
4. executa rollback;
5. comprova que o estoque voltou ao valor anterior.

Esse teste evita um caso comum em marketplaces: alterar estoque parcialmente quando outra gravação do mesmo fluxo falha.

## Concorrência na criação de pedido

`sp_create_order` bloqueia a linha de produto/estoque com `FOR UPDATE`, valida o saldo e reduz a quantidade na mesma transação. Duas sessões disputando o último item são serializadas; a segunda reavalia o saldo depois que recebe o bloqueio e falha com `INSUFFICIENT_STOCK` se necessário.
