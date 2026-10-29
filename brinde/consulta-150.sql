-- Os 150 primeiros brindes (Copo Bucks) do devocional, no banco do portal-iecg.
-- Cada exemplar comprado vale um brinde: um pedido de 3 exemplares leva 3 copos.
-- Usada no nó Postgres do n8n (somente leitura).
--
-- Antes de usar, troque:
--   dev_iecg                  pelo schema de produção (variável DB_SCHEMA do portal)
--   'SLUG-DO-DEVOCIONAL'      pelo slug do evento do devocional no portal
--
-- Critérios:
--   * só pedidos com paymentStatus = 'confirmed'
--   * a ordem é a data de inscrição (createdAt); empate desempatado pelo código do pedido
--   * os 150 copos são distribuídos na ordem dos pedidos; o pedido que cruzar o 150
--     recebe só os copos que ainda couberem (ex.: pedido de 3 quando só restam 2 leva 2)
--
-- Uma linha por pedido; a coluna "copos" é quantos Copos Bucks esse pedido ganhou.

WITH pedidos AS (
  SELECT
    r."orderCode"                                                                          AS order_code,
    TRIM(COALESCE(r."buyerData"->>'buyer_name', r."buyerData"->>'nome', r."buyerData"->>'name')) AS nome,
    LOWER(TRIM(COALESCE(r."buyerData"->>'buyer_email', r."buyerData"->>'email')))          AS email,
    r."createdAt"                                                                          AS data_inscricao,
    GREATEST(COALESCE(r.quantity, 1), 1)                                                   AS quantidade,
    SUM(GREATEST(COALESCE(r.quantity, 1), 1)) OVER (ORDER BY r."createdAt", r."orderCode") AS acumulado
  FROM dev_iecg."Registrations" r
  JOIN dev_iecg."Events" e ON e.id = r."eventId"
  WHERE e.slug = 'SLUG-DO-DEVOCIONAL'
    AND r."paymentStatus" = 'confirmed'
)
SELECT
  order_code,
  nome,
  email,
  data_inscricao,
  quantidade,
  LEAST(acumulado, 150) - (acumulado - quantidade)         AS copos
FROM pedidos
WHERE acumulado - quantidade < 150
ORDER BY data_inscricao, order_code;
