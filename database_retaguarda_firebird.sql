/* ==============================================================================
   SCRIPT DE INTEGRAÇÃO E AUDITORIA - RETAGUARDA FIREBIRD
   BASE DE DADOS: DADOS.FDB (MANSAO DA TORRE PIZZARIA)
   TABELAS ENVOLVIDAS: TB_INGRESSO, TB_MESA
   ============================================================================== */

-- 1. Criação de Índices de Otimização na Retaguarda Firebird (se ainda não existirem)
SET TERM ^ ;

EXECUTE BLOCK AS
BEGIN
  IF (NOT EXISTS (
    SELECT 1 
    FROM RDB$INDICES 
    WHERE RDB$INDEX_NAME = 'IDX_TB_INGRESSO_AUDIT_MESA'
  )) THEN
  BEGIN
    EXECUTE STATEMENT 'CREATE INDEX IDX_TB_INGRESSO_AUDIT_MESA ON TB_INGRESSO (ING_EMPRESA, ING_CODIGO, ING_STATUS);';
  END

  IF (NOT EXISTS (
    SELECT 1 
    FROM RDB$INDICES 
    WHERE RDB$INDEX_NAME = 'IDX_TB_INGRESSO_AUDIT_DATA'
  )) THEN
  BEGIN
    EXECUTE STATEMENT 'CREATE INDEX IDX_TB_INGRESSO_AUDIT_DATA ON TB_INGRESSO (ING_EMPRESA, ING_DT_ENTRADA);';
  END
END^

SET TERM ; ^
COMMIT;

/* ==============================================================================
   2. INSTRUÇÕES SQL DML COMPLETAS E PARAMETRIZADAS (FLUXO DO APLICATIVO)
   ============================================================================== */

-- 2.1. Inserção de Novo Registro de Check-in (Mesa Ocupada)
-- Executado quando o operador seleciona uma mesa livre e confirma a entrada.
INSERT INTO TB_INGRESSO (
    ING_EMPRESA,
    ING_ID,
    ING_STATUS,
    ING_USUARIO,
    ING_DT_LANCAMENTO,
    ING_DT_EMISSAO,
    ING_DT_EVENTO,
    ING_HR_EVENTO,
    ING_DT_ENTRADA,
    ING_DT_SAIDA,
    ING_DURACAO,
    ING_PESSOA,
    ING_TIPO_INGRESSO,
    ING_VALOR,
    ING_OBSERVACAO,
    ING_PEDIDO,
    ING_CODIGO,
    ING_TOTAL_RECEBIDO,
    ING_TOTAL_PRODUTOS,
    ING_VALOR_DIFERENCA,
    ING_CAIXA,
    ING_FECHAMENTO,
    ING_TROCO,
    ING_TIPO_TROCO,
    ING_GERAR_FINANCEIRO
) VALUES (
    1,                                                    -- ING_EMPRESA
    (SELECT COALESCE(MAX(ING_ID), 0) + 1 FROM TB_INGRESSO WHERE ING_EMPRESA = 1), -- ING_ID
    'E',                                                  -- ING_STATUS ('E' = Entrada / Em Atendimento)
    1,                                                    -- ING_USUARIO
    CURRENT_TIMESTAMP,                                    -- ING_DT_LANCAMENTO
    CURRENT_DATE,                                         -- ING_DT_EMISSAO
    CURRENT_DATE,                                         -- ING_DT_EVENTO
    CURRENT_TIME,                                         -- ING_HR_EVENTO
    CURRENT_TIMESTAMP,                                    -- ING_DT_ENTRADA (Check-in)
    NULL,                                                 -- ING_DT_SAIDA (Ainda em permanência)
    0,                                                    -- ING_DURACAO (Em minutos)
    NULL,                                                 -- ING_PESSOA
    1,                                                    -- ING_TIPO_INGRESSO
    0.00,                                                 -- ING_VALOR
    'Check-in efetuado via App Mobile de Permanência',    -- ING_OBSERVACAO
    NULL,                                                 -- ING_PEDIDO
    '1',                                                  -- ING_CODIGO (ID da Mesa / MSA_ID)
    0.00,                                                 -- ING_TOTAL_RECEBIDO
    0.00,                                                 -- ING_TOTAL_PRODUTOS
    0.00,                                                 -- ING_VALOR_DIFERENCA
    1,                                                    -- ING_CAIXA
    NULL,                                                 -- ING_FECHAMENTO
    0.00,                                                 -- ING_TROCO
    NULL,                                                 -- ING_TIPO_TROCO
    'N'                                                   -- ING_GERAR_FINANCEIRO
);
COMMIT;

-- 2.2. Fechamento de Check-out e Atualização de Permanência
-- Executado no momento em que a mesa é liberada pelo cliente.
UPDATE TB_INGRESSO
SET ING_STATUS = 'F',
    ING_DT_SAIDA = CURRENT_TIMESTAMP,
    ING_DURACAO = DATEDIFF(MINUTE FROM ING_DT_ENTRADA TO CURRENT_TIMESTAMP),
    ING_OBSERVACAO = COALESCE(ING_OBSERVACAO, '') || ' | Check-out registrado via App'
WHERE ING_EMPRESA = 1
  AND (ING_CODIGO = '1' OR ING_CODIGO = '001')
  AND (ING_STATUS = 'E' OR ING_STATUS = 'A')
  AND ING_DT_SAIDA IS NULL;
COMMIT;

/* ==============================================================================
   3. CONSULTAS DE RELATÓRIO E AUDITORIA GERENCIAL
   ============================================================================== */

-- 3.1. Relatório de Mesas Atualmente Ocupadas e Tempo Decorrido em Minutos
SELECT
    I.ING_EMPRESA,
    I.ING_ID,
    I.ING_CODIGO AS NUMERO_MESA,
    I.ING_DT_ENTRADA,
    CURRENT_TIMESTAMP AS HORA_ATUAL,
    DATEDIFF(MINUTE FROM I.ING_DT_ENTRADA TO CURRENT_TIMESTAMP) AS MINUTOS_DECORRIDOS,
    CASE
        WHEN DATEDIFF(MINUTE FROM I.ING_DT_ENTRADA TO CURRENT_TIMESTAMP) <= 90 THEN 'NORMAL (AZUL)'
        WHEN DATEDIFF(MINUTE FROM I.ING_DT_ENTRADA TO CURRENT_TIMESTAMP) <= 120 THEN 'ALERTA TOLERANCIA (LARANJA)'
        ELSE 'TEMPO EXCEDIDO (VERMELHO)'
    END AS FAIXA_PERMANENCIA
FROM TB_INGRESSO I
WHERE I.ING_EMPRESA = 1
  AND I.ING_STATUS = 'A'
ORDER BY I.ING_DT_ENTRADA ASC;

-- 3.2. Relatório de Rotatividade e Tempo Médio de Permanência por Mesa no Dia
SELECT
    I.ING_CODIGO AS NUMERO_MESA,
    COUNT(I.ING_ID) AS TOTAL_ATENDIMENTOS,
    MIN(I.ING_DURACAO) AS MENOR_TEMPO_MINUTOS,
    MAX(I.ING_DURACAO) AS MAIOR_TEMPO_MINUTOS,
    AVG(I.ING_DURACAO) AS TEMPO_MEDIO_MINUTOS,
    SUM(CASE WHEN I.ING_DURACAO > 120 THEN 1 ELSE 0 END) AS QTD_EXCEDEU_2_HORAS
FROM TB_INGRESSO I
WHERE I.ING_EMPRESA = 1
  AND I.ING_STATUS = 'F'
  AND CAST(I.ING_DT_ENTRADA AS DATE) = CURRENT_DATE
GROUP BY I.ING_CODIGO
ORDER BY TOTAL_ATENDIMENTOS DESC, TEMPO_MEDIO_MINUTOS DESC;

-- 3.3. Auditoria de Atendimentos que Ultrapassaram o Limite de Tolerância (Mais de 2 Horas)
SELECT
    I.ING_EMPRESA,
    I.ING_ID,
    I.ING_CODIGO AS NUMERO_MESA,
    I.ING_DT_ENTRADA,
    I.ING_DT_SAIDA,
    I.ING_DURACAO AS TOTAL_MINUTOS,
    I.ING_OBSERVACAO
FROM TB_INGRESSO I
WHERE I.ING_EMPRESA = 1
  AND I.ING_DURACAO > 120
ORDER BY I.ING_DT_ENTRADA DESC;

/* ==============================================================================
   4. CONSULTAS DE PEDIDOS E CONSUMO POR MESA (MODELO PRÉ-PAGO)
   TABELAS ENVOLVIDAS: TB_PEDIDO_VENDA, TB_INGRESSO, TB_MESA
   ============================================================================== */

-- 4.1. Criação do Índice de Alta Performance para Pedidos por Mesa e Data
SET TERM ^ ;
EXECUTE BLOCK AS
BEGIN
  IF (NOT EXISTS (
    SELECT 1 
    FROM RDB$INDICES 
    WHERE RDB$INDEX_NAME = 'IDX_TB_PEV_AUDIT_MESA_DATA'
  )) THEN
  BEGIN
    EXECUTE STATEMENT 'CREATE INDEX IDX_TB_PEV_AUDIT_MESA_DATA ON TB_PEDIDO_VENDA (PEV_EMPRESA, PEV_MESA, PEV_DT_LANCAMENTO);';
  END
END^
SET TERM ; ^
COMMIT;

-- 4.2. Consulta de Pedidos Realizados na Mesa após o Momento do Check-in
-- Regras de negócio:
-- - Modelo pré-pago: Não filtra por pedido em aberto; cada pedido é pago no ato.
-- - Filtro temporal: Apenas pedidos após ING_DT_ENTRADA (Check-in da mesa).
-- - Último pedido: Ordenação decrescente por data/hora para capturar a transação mais recente.
-- - Tempo decorrido: Minutos entre o último pedido e a hora atual.
-- - Valores: Valor do último pedido e somatório total de todos os pedidos desde o check-in.
SELECT
    P.PEV_ID AS ID_PEDIDO,
    P.PEV_EMPRESA,
    P.PEV_MESA AS NUMERO_MESA,
    P.PEV_DT_LANCAMENTO AS DATA_HORA_PEDIDO,
    CURRENT_TIMESTAMP AS HORA_ATUAL,
    DATEDIFF(MINUTE FROM P.PEV_DT_LANCAMENTO TO CURRENT_TIMESTAMP) AS MINUTOS_DESDE_PEDIDO,
    COALESCE(P.PEV_VALOR_TOTAL, 0.0) AS VALOR_PEDIDO,
    P.PEV_STATUS
FROM TB_PEDIDO_VENDA P
WHERE P.PEV_EMPRESA = 1
  AND P.PEV_MESA = 23 -- Número ou ID da mesa
  AND P.PEV_DT_LANCAMENTO >= '2026-10-13 19:30:00' -- Data/Hora exata do Check-in
  AND COALESCE(P.PEV_STATUS, '') != 'C' -- Desconsidera cancelados
ORDER BY P.PEV_DT_LANCAMENTO DESC;

-- 4.3. Resumo Consolidado com Último Pedido, Minutos Decorridos e Somatório Total
SELECT
    P.PEV_MESA AS NUMERO_MESA,
    COUNT(P.PEV_ID) AS QTD_PEDIDOS_DESDE_CHECKIN,
    MAX(P.PEV_DT_LANCAMENTO) AS DATA_HORA_ULTIMO_PEDIDO,
    DATEDIFF(MINUTE FROM MAX(P.PEV_DT_LANCAMENTO) TO CURRENT_TIMESTAMP) AS MINUTOS_DESDE_ULTIMO_PEDIDO,
    (
        SELECT FIRST 1 COALESCE(U.PEV_VALOR_TOTAL, 0.0)
        FROM TB_PEDIDO_VENDA U
        WHERE U.PEV_EMPRESA = P.PEV_EMPRESA
          AND U.PEV_MESA = P.PEV_MESA
          AND U.PEV_DT_LANCAMENTO >= '2026-10-13 19:30:00'
          AND COALESCE(U.PEV_STATUS, '') != 'C'
        ORDER BY U.PEV_DT_LANCAMENTO DESC
    ) AS VALOR_ULTIMO_PEDIDO,
    SUM(COALESCE(P.PEV_VALOR_TOTAL, 0.0)) AS VALOR_TOTAL_CONSUMIDO
FROM TB_PEDIDO_VENDA P
WHERE P.PEV_EMPRESA = 1
  AND P.PEV_MESA = 23
  AND P.PEV_DT_LANCAMENTO >= '2026-10-13 19:30:00'
  AND COALESCE(P.PEV_STATUS, '') != 'C'
GROUP BY P.PEV_EMPRESA, P.PEV_MESA;

-- 4.4. Consulta Detalhada por Itens: Total Consumo, Qtd Pessoas, Último Consumo, Tempo e Último Produto
-- Corrige a duplicação de valores do JOIN usando SUM(i.pevi_valor_total), captura o último produto consumido
-- e calcula o tempo decorrido em minutos via DATEDIFF.
SELECT
    SUM(i.pevi_valor_total) AS TOTAL,
    MAX(pv.pev_qtde_pessoas) AS QTD_PESSOAS,
    MAX(i.pevi_dt_lancamento) AS ULTIMO_CONSUMO,
    DATEDIFF(MINUTE FROM MAX(i.pevi_dt_lancamento) TO CURRENT_TIMESTAMP) AS MINUTOS_ULTIMO_CONSUMO,
    (
        SELECT FIRST 1 i2.pevi_descricao
        FROM tb_pedido_venda pv2
        INNER JOIN tb_pedido_venda_item i2 
            ON i2.pevi_empresa = pv2.pev_empresa 
           AND i2.pevi_pedido_venda = pv2.pev_id
        WHERE pv2.pev_status <> 'C' 
          AND pv2.pev_dt_lancamento >= :data_ingresso 
          AND pv2.pev_mesa = :id_mesa
        ORDER BY i2.pevi_dt_lancamento DESC, i2.pevi_sequencia DESC
    ) AS ULTIMO_PRODUTO
FROM tb_pedido_venda pv
INNER JOIN tb_pedido_venda_item i 
    ON i.pevi_empresa = pv.pev_empresa 
   AND i.pevi_pedido_venda = pv.pev_id
WHERE pv.pev_status <> 'C' 
  AND pv.pev_dt_lancamento >= :data_ingresso 
  AND pv.pev_mesa = :id_mesa;

-- 4.5. Consulta Oficial de Integração em Lote (Lucas Dagnoni - 13/10/2026)
-- Retorna todas as mesas ativas, status de ingresso ('E'), total consumido, último consumo e pessoas
WITH MESAS AS (
  SELECT
    MES.MSA_ID,
    MES.MSA_CODIGO
  FROM TB_MESA MES
  WHERE MES.MSA_STATUS = 'A'
),
INGRESSOS AS (
  SELECT
    ING.ING_CODIGO,
    ING.ING_DT_ENTRADA
  FROM TB_INGRESSO ING
  WHERE ING.ING_STATUS = 'E' AND ING.ING_DT_SAIDA IS NULL
)
SELECT
  MSA_ID,
  MSA_CODIGO,
  ING_CODIGO,
  ING_DT_ENTRADA,
  (SELECT SUM(PV.PEV_VALOR_TOTAL)
   FROM TB_PEDIDO_VENDA PV
   WHERE PV.PEV_STATUS <> 'C'
     AND PV.PEV_DT_LANCAMENTO >= INGRESSOS.ING_DT_ENTRADA
     AND PV.PEV_MESA = ING_CODIGO) AS TOTAL_CONSUMIDO,
  (SELECT MAX(I.PEVI_DT_LANCAMENTO)
   FROM TB_PEDIDO_VENDA PV
   INNER JOIN TB_PEDIDO_VENDA_ITEM I ON I.PEVI_EMPRESA = PV.PEV_EMPRESA AND I.PEVI_PEDIDO_VENDA = PV.PEV_ID
   WHERE PV.PEV_STATUS <> 'C'
     AND PV.PEV_DT_LANCAMENTO >= INGRESSOS.ING_DT_ENTRADA
     AND PV.PEV_MESA = INGRESSOS.ING_CODIGO) AS ULTIMO_CONSUMO,
  (SELECT SUM(PV.PEV_QTDE_PESSOAS)
   FROM TB_PEDIDO_VENDA PV
   WHERE PV.PEV_STATUS <> 'C'
     AND PV.PEV_DT_LANCAMENTO >= INGRESSOS.ING_DT_ENTRADA
     AND PV.PEV_MESA = INGRESSOS.ING_CODIGO) AS QTDE_PESSOAS
FROM MESAS
LEFT JOIN INGRESSOS ON INGRESSOS.ING_CODIGO = MESAS.MSA_ID
ORDER BY MSA_ID;

