-- =============================================================================
-- MÉTRICA 1 — Solicitações nas últimas 12 horas
-- Filtra por Dt_Atualizacao (datetime), pois Data_Solicitacao é somente date.
-- Retorna: total, aprovadas, pendentes, negadas — com quebra por hora do dia.
-- Requer: #ReguladorBase criado por sql_regulador_base.sql
-- =============================================================================

WITH Urg AS (
    SELECT *
    FROM #ReguladorBase
    WHERE (
        UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA','URGÊNCIA','EMERGÊNCIA')
        OR UPPER(LTRIM(RTRIM(Carater))) LIKE '%URG%'
    )
    AND Dt_Atualizacao >= DATEADD(hour, -12, GETDATE())
),
Classificada AS (
    SELECT
        *,
        CASE
            WHEN status LIKE '%INTERNADO%' OR status LIKE '%INTERNADA%'
              OR status LIKE '%APROVADA%'  OR Data_Internacao IS NOT NULL
                THEN 'APROVADO'
            WHEN status LIKE '%NEGAD%' OR status LIKE '%DEVOLV%'
                THEN 'NEGADO'
            WHEN status = 'Pendente' OR status LIKE '%FILA%' OR status LIKE '%AGUARD%'
                THEN 'PENDENTE'
            ELSE 'OUTRO'
        END AS Situacao
    FROM Urg
)
SELECT
    -- Totais gerais
    COUNT(*)                                           AS total_solicitacoes_12h,
    SUM(CASE WHEN Situacao = 'APROVADO'  THEN 1 END)  AS aprovadas,
    SUM(CASE WHEN Situacao = 'PENDENTE'  THEN 1 END)  AS pendentes,
    SUM(CASE WHEN Situacao = 'NEGADO'    THEN 1 END)  AS negadas,
    SUM(CASE WHEN Situacao = 'OUTRO'     THEN 1 END)  AS outras,
    -- Janela de referência
    DATEADD(hour, -12, GETDATE())                      AS janela_inicio,
    GETDATE()                                          AS janela_fim,
    -- Última atualização
    MAX(Dt_Atualizacao)                                AS ultima_atualizacao
FROM Classificada;
