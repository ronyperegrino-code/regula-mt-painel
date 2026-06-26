-- =============================================================================
-- MÉTRICA 7 — Quantitativo geral das solicitações reguladas
-- Visão global: totais, situações, evolução diária e mensal
-- Permite acompanhamento contínuo da demanda e oferta de vagas.
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
        *,
        CASE
            WHEN Data_Internacao IS NOT NULL
              OR status LIKE '%INTERNADO%' OR status LIKE '%INTERNADA%'
              OR status LIKE '%APROVADA%'
                THEN 'APROVADO'
            WHEN status LIKE '%NEGAD%' OR status LIKE '%DEVOLV%'
                THEN 'NEGADO'
            WHEN status = 'Pendente'
              OR status LIKE '%FILA%' OR status LIKE '%AGUARD%'
              OR status LIKE '%REPRESADO%'
                THEN 'PENDENTE'
            ELSE 'OUTRO'
        END AS Situacao,
        CASE
            WHEN UPPER(Clinica) LIKE '%UTI%'
              OR UPPER(Clinica) LIKE '%TERAPIA INTENSIVA%'
              OR UPPER(Clinica) LIKE '%UNIDADE DE TERAPIA%'
              OR UPPER(Clinica) LIKE '%CUIDADOS INTENSIVOS%'
                THEN 'UTI'
            WHEN UPPER(Clinica)      LIKE '%HEMODINA%'
              OR UPPER(Procedimento) LIKE '%HEMODINA%'
                THEN 'HEMODINAMICA'
            WHEN UPPER(Procedimento) LIKE '%REMOCAO%'
              OR UPPER(Procedimento) LIKE '%REMOÇÃO%'
              OR UPPER(Procedimento) LIKE '%TRANSPORTE INTER%'
                THEN 'TRANS_INTER_HOSP'
            ELSE 'ENFERMARIA'
        END AS Tipo_Leito,
        CASE WHEN Data_Internacao IS NOT NULL
             THEN DATEDIFF(day, Data_Solicitacao, Data_Internacao)
             END AS dias_a_internacao
    FROM Urg
),

-- ── [A] Totais e taxas globais ────────────────────────────────────────────────
GeralAgregado AS (
    SELECT
        COUNT(*)                                                                      AS total_solicitacoes,
        SUM(CASE WHEN Situacao = 'APROVADO'              THEN 1 ELSE 0 END)           AS aprovados,
        SUM(CASE WHEN Situacao = 'NEGADO'                THEN 1 ELSE 0 END)           AS negados,
        SUM(CASE WHEN Situacao = 'PENDENTE'              THEN 1 ELSE 0 END)           AS pendentes,
        SUM(CASE WHEN Tipo_Leito = 'UTI'                 THEN 1 ELSE 0 END)           AS total_uti,
        SUM(CASE WHEN Tipo_Leito = 'ENFERMARIA'          THEN 1 ELSE 0 END)           AS total_enfermaria,
        SUM(CASE WHEN Tipo_Leito = 'HEMODINAMICA'        THEN 1 ELSE 0 END)           AS total_hemodinamica,
        SUM(CASE WHEN Tipo_Leito = 'TRANS_INTER_HOSP'    THEN 1 ELSE 0 END)           AS total_trans_inter_hosp,
        SUM(CASE WHEN Situacao = 'APROVADO' AND Tipo_Leito = 'UTI'        THEN 1 ELSE 0 END) AS aprovados_uti,
        SUM(CASE WHEN Situacao = 'APROVADO' AND Tipo_Leito = 'ENFERMARIA' THEN 1 ELSE 0 END) AS aprovados_enfermaria,
        ROUND(100.0 * SUM(CASE WHEN Situacao = 'APROVADO' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 1) AS taxa_aprovacao_pct,
        ROUND(100.0 * SUM(CASE WHEN Situacao = 'NEGADO'   THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 1) AS taxa_negacao_pct,
        ROUND(100.0 * SUM(CASE WHEN Situacao = 'PENDENTE' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 1) AS taxa_represamento_pct,
        AVG(CAST(dias_a_internacao AS float))                                         AS media_dias_a_internacao,
        MIN(Data_Solicitacao)                                                         AS periodo_inicio,
        MAX(Data_Solicitacao)                                                         AS periodo_fim,
        GETDATE()                                                                     AS gerado_em
    FROM Classificada
),
GeralMediana AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dias_a_internacao)
            OVER ()  AS mediana_dias_a_internacao
    FROM Classificada
    WHERE dias_a_internacao IS NOT NULL
)

-- [A] Painel geral único
SELECT g.*, m.mediana_dias_a_internacao
FROM GeralAgregado g
CROSS JOIN GeralMediana m;

-- ── [B] Evolução diária ───────────────────────────────────────────────────────
SELECT
    Data_Solicitacao                                                               AS data,
    COUNT(*)                                                                       AS solicitacoes,
    SUM(CASE WHEN Situacao = 'APROVADO'  THEN 1 ELSE 0 END)                       AS aprovados,
    SUM(CASE WHEN Situacao = 'NEGADO'    THEN 1 ELSE 0 END)                       AS negados,
    SUM(CASE WHEN Situacao = 'PENDENTE'  THEN 1 ELSE 0 END)                       AS pendentes,
    SUM(CASE WHEN Tipo_Leito = 'UTI'        THEN 1 ELSE 0 END)                    AS uti,
    SUM(CASE WHEN Tipo_Leito = 'ENFERMARIA' THEN 1 ELSE 0 END)                    AS enfermaria,
    ROUND(100.0 * SUM(CASE WHEN Situacao = 'APROVADO' THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*), 0), 1)                                                AS taxa_aprovacao_pct
FROM Classificada
GROUP BY Data_Solicitacao
ORDER BY Data_Solicitacao;

-- ── [C] Evolução mensal ───────────────────────────────────────────────────────
SELECT
    Ano_Solicitacao                                                                AS ano,
    MONTH(Data_Solicitacao)                                                        AS mes,
    FORMAT(Data_Solicitacao, 'MM/yyyy')                                            AS mes_ano,
    COUNT(*)                                                                       AS solicitacoes,
    SUM(CASE WHEN Situacao = 'APROVADO'  THEN 1 ELSE 0 END)                       AS aprovados,
    SUM(CASE WHEN Situacao = 'NEGADO'    THEN 1 ELSE 0 END)                       AS negados,
    SUM(CASE WHEN Situacao = 'PENDENTE'  THEN 1 ELSE 0 END)                       AS pendentes,
    SUM(CASE WHEN Tipo_Leito = 'UTI'        THEN 1 ELSE 0 END)                    AS uti,
    SUM(CASE WHEN Tipo_Leito = 'ENFERMARIA' THEN 1 ELSE 0 END)                    AS enfermaria,
    ROUND(100.0 * SUM(CASE WHEN Situacao = 'APROVADO' THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*), 0), 1)                                                AS taxa_aprovacao_pct,
    AVG(CAST(dias_a_internacao AS float))                                          AS media_dias_a_internacao
FROM Classificada
GROUP BY Ano_Solicitacao, MONTH(Data_Solicitacao), FORMAT(Data_Solicitacao, 'MM/yyyy')
ORDER BY Ano_Solicitacao, MONTH(Data_Solicitacao);
