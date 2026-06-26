-- =============================================================================
-- MÉTRICA 4 — Aprovações de UTI e Enfermaria por hospital
-- Classifica apenas os APROVADOS pelo tipo de clínica
-- Requer: #ReguladorBase criado por sql_regulador_base.sql
-- =============================================================================

WITH Urg AS (
    SELECT *
    FROM #ReguladorBase
    WHERE (
        UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA','URGÊNCIA','EMERGÊNCIA')
        OR UPPER(LTRIM(RTRIM(Carater))) LIKE '%URG%'
    )
    AND (
        Data_Internacao IS NOT NULL
        OR status LIKE '%INTERNADO%'
        OR status LIKE '%INTERNADA%'
        OR status LIKE '%APROVADA%'
    )
),
Classificada AS (
    SELECT
        Codigo_Unidade_Desejada,
        Hospital_Desejado,
        codigo_solicitacao,
        Clinica,
        Procedimento,
        Data_Solicitacao,
        Data_Internacao,
        CASE
            WHEN UPPER(Clinica) LIKE '%UTI%'
              OR UPPER(Clinica) LIKE '%U.T.I%'
              OR UPPER(Clinica) LIKE '%TERAPIA INTENSIVA%'
              OR UPPER(Clinica) LIKE '%UNIDADE DE TERAPIA%'
              OR UPPER(Clinica) LIKE '%CUIDADOS INTENSIVOS%'
              OR UPPER(Clinica) LIKE '%CUIDADOS INTERMEDIARIOS%'
              OR UPPER(Procedimento) LIKE '%UTI%'
                THEN 'UTI'
            ELSE 'ENFERMARIA'
        END AS Tipo_Leito
    FROM Urg
)
SELECT
    Codigo_Unidade_Desejada                            AS cnes_hospital,
    Hospital_Desejado                                  AS hospital,
    COUNT(*)                                           AS total_aprovados,
    SUM(CASE WHEN Tipo_Leito = 'UTI'       THEN 1 ELSE 0 END) AS aprovados_uti,
    SUM(CASE WHEN Tipo_Leito = 'ENFERMARIA' THEN 1 ELSE 0 END) AS aprovados_enfermaria,
    -- Proporção UTI vs Enfermaria
    ROUND(
        100.0 * SUM(CASE WHEN Tipo_Leito = 'UTI' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 1
    )                                                  AS pct_uti,
    ROUND(
        100.0 * SUM(CASE WHEN Tipo_Leito = 'ENFERMARIA' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 1
    )                                                  AS pct_enfermaria
FROM Classificada
GROUP BY Codigo_Unidade_Desejada, Hospital_Desejado
ORDER BY total_aprovados DESC;
