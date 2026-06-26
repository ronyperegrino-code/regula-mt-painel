-- =============================================================================
-- MÉTRICA 2 — Pacientes pendentes por tipo de solicitação
-- Tipos: UTI | Hemodinâmica | Trans. Inter-Hospitalar | Enfermaria (demais)
-- Pendente = sem Data_Internacao E status indica aguardo/fila
-- Requer: #ReguladorBase criado por sql_regulador_base.sql
-- =============================================================================

WITH Urg AS (
    SELECT *
    FROM #ReguladorBase
    WHERE (
        UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA','URGÊNCIA','EMERGÊNCIA')
        OR UPPER(LTRIM(RTRIM(Carater))) LIKE '%URG%'
    )
    AND Data_Internacao IS NULL
    AND (
        status = 'Pendente'
        OR status LIKE '%FILA%'
        OR status LIKE '%AGUARD%'
        OR status LIKE '%REPRESADO%'
    )
),
Classificada AS (
    SELECT
        codigo_solicitacao,
        Hospital_Desejado,
        Codigo_Unidade_Desejada,
        Nome_Unidade_Solicitante,
        Clinica,
        Procedimento,
        status,
        Data_Solicitacao,
        Dt_Atualizacao,
        DATEDIFF(hour,
            CAST(Data_Solicitacao AS datetime2),
            CAST(GETDATE() AS datetime2)
        )                               AS horas_em_espera,
        CASE
            WHEN UPPER(Clinica) LIKE '%UTI%'
              OR UPPER(Clinica) LIKE '%U.T.I%'
              OR UPPER(Clinica) LIKE '%TERAPIA INTENSIVA%'
              OR UPPER(Clinica) LIKE '%UNIDADE DE TERAPIA%'
              OR UPPER(Clinica) LIKE '%CUIDADOS INTENSIVOS%'
              OR UPPER(Clinica) LIKE '%CUIDADOS INTERMEDIARIOS%'
              OR UPPER(Procedimento) LIKE '%UTI%'
                THEN 'UTI'
            WHEN UPPER(Clinica)     LIKE '%HEMODINA%'
              OR UPPER(Procedimento) LIKE '%HEMODINA%'
              OR UPPER(Clinica)     LIKE '%HEMODIN%'
                THEN 'HEMODINAMICA'
            WHEN UPPER(Procedimento) LIKE '%REMOCAO%'
              OR UPPER(Procedimento) LIKE '%REMOÇÃO%'
              OR UPPER(Procedimento) LIKE '%TRANSPORTE INTER%'
              OR UPPER(Procedimento) LIKE '%TRANSLADO%'
              OR (
                  (UPPER(Nome_Unidade_Solicitante) LIKE '%HOSPITAL%'
                   OR UPPER(Nome_Unidade_Solicitante) LIKE '%H.%MUN%'
                   OR UPPER(Nome_Unidade_Solicitante) LIKE '%PRONTO SOCORRO%'
                   OR UPPER(Nome_Unidade_Solicitante) LIKE '%UPA%')
                  AND (UPPER(Nome_Unidade_Solicitante) NOT LIKE '%CRUE%'
                       AND UPPER(Nome_Unidade_Solicitante) NOT LIKE '%CENTRAL%REG%'
                       AND UPPER(Nome_Unidade_Solicitante) NOT LIKE '%NIR%'
                       AND UPPER(Nome_Unidade_Solicitante) NOT LIKE '%ERS%')
              )
                THEN 'TRANS_INTER_HOSP'
            ELSE 'ENFERMARIA'
        END AS Tipo_Solicitacao
    FROM Urg
)
-- Sumário por tipo
SELECT
    Tipo_Solicitacao,
    COUNT(*)                                           AS total_pendentes,
    AVG(horas_em_espera)                               AS media_horas_espera,
    MAX(horas_em_espera)                               AS max_horas_espera,
    MIN(Data_Solicitacao)                              AS solicitacao_mais_antiga,
    MAX(Data_Solicitacao)                              AS solicitacao_mais_recente
FROM Classificada
GROUP BY Tipo_Solicitacao
ORDER BY
    CASE Tipo_Solicitacao
        WHEN 'UTI'            THEN 1
        WHEN 'HEMODINAMICA'   THEN 2
        WHEN 'TRANS_INTER_HOSP' THEN 3
        WHEN 'ENFERMARIA'     THEN 4
        ELSE 5
    END;
