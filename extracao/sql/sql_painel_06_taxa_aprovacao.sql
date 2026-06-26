-- =============================================================================
-- MÉTRICA 6 — Taxa de aprovação das solicitações por unidade hospitalar
-- Taxa = aprovados / total_solicitacoes * 100
-- Inclui breakdown por situação final e evolução mensal.
-- Requer: #ReguladorBase criado por sql_regulador_base.sql
-- =============================================================================

WITH Urg AS (
    SELECT *
    FROM #ReguladorBase
    WHERE (
        UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA','URGÊNCIA','EMERGÊNCIA')
        OR UPPER(LTRIM(RTRIM(Carater))) LIKE '%URG%'
    )
),
Classificada AS (
    SELECT
        Codigo_Unidade_Desejada,
        Hospital_Desejado,
        codigo_solicitacao,
        Data_Solicitacao,
        Ano_Solicitacao,
        MONTH(Data_Solicitacao) AS Mes_Solicitacao,
        CASE
            WHEN Data_Internacao IS NOT NULL
              OR status LIKE '%INTERNADO%'
              OR status LIKE '%INTERNADA%'
              OR status LIKE '%APROVADA%'
                THEN 'APROVADO'
            WHEN status LIKE '%NEGAD%' OR status LIKE '%DEVOLV%'
                THEN 'NEGADO'
            WHEN status = 'Pendente'
              OR status LIKE '%FILA%'
              OR status LIKE '%AGUARD%'
              OR status LIKE '%REPRESADO%'
                THEN 'PENDENTE'
            ELSE 'OUTRO'
        END AS Situacao
    FROM Urg
)
SELECT
    Codigo_Unidade_Desejada                            AS cnes_hospital,
    Hospital_Desejado                                  AS hospital,
    COUNT(*)                                           AS total_solicitacoes,
    SUM(CASE WHEN Situacao = 'APROVADO'  THEN 1 ELSE 0 END) AS aprovados,
    SUM(CASE WHEN Situacao = 'NEGADO'    THEN 1 ELSE 0 END) AS negados,
    SUM(CASE WHEN Situacao = 'PENDENTE'  THEN 1 ELSE 0 END) AS pendentes,
    SUM(CASE WHEN Situacao = 'OUTRO'     THEN 1 ELSE 0 END) AS outros,
    -- Taxa de aprovação
    ROUND(
        100.0 * SUM(CASE WHEN Situacao = 'APROVADO' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 1
    )                                                  AS taxa_aprovacao_pct,
    -- Taxa de negação
    ROUND(
        100.0 * SUM(CASE WHEN Situacao = 'NEGADO' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 1
    )                                                  AS taxa_negacao_pct,
    -- Taxa de represamento (pendentes / total)
    ROUND(
        100.0 * SUM(CASE WHEN Situacao = 'PENDENTE' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 1
    )                                                  AS taxa_represamento_pct,
    MIN(Data_Solicitacao)                              AS primeira_solicitacao,
    MAX(Data_Solicitacao)                              AS ultima_solicitacao
FROM Classificada
GROUP BY Codigo_Unidade_Desejada, Hospital_Desejado
ORDER BY taxa_aprovacao_pct DESC;
