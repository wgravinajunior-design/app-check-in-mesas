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
    'A',                                                  -- ING_STATUS ('A' = Em Atendimento)
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
    '001',                                                -- ING_CODIGO (Número da Mesa)
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

-- 2.2. Atualização de Status da Mesa na Retaguarda para Ocupada
UPDATE TB_MESA
SET MSA_STATUS = 'O'
WHERE MSA_EMPRESA = 1
  AND MSA_CODIGO = '001';
COMMIT;

-- 2.3. Fechamento de Check-out e Atualização de Permanência
-- Executado no momento em que a mesa é liberada pelo cliente.
UPDATE TB_INGRESSO
SET ING_STATUS = 'F',
    ING_DT_SAIDA = CURRENT_TIMESTAMP,
    ING_DURACAO = DATEDIFF(MINUTE FROM ING_DT_ENTRADA TO CURRENT_TIMESTAMP),
    ING_OBSERVACAO = ING_OBSERVACAO || ' | Check-out registrado via App'
WHERE ING_EMPRESA = 1
  AND ING_CODIGO = '001'
  AND ING_STATUS = 'A';
COMMIT;

-- 2.4. Atualização de Status da Mesa na Retaguarda para Livre
UPDATE TB_MESA
SET MSA_STATUS = 'A'
WHERE MSA_EMPRESA = 1
  AND MSA_CODIGO = '001';
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
