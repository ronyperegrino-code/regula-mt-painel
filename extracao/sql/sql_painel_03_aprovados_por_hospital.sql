-- =============================================================================
-- MÉTRICA 3 — Pacientes aprovados com detalhamento por unidade hospitalar
-- Aprovado = Data_Internacao preenchida OU status indica internação/aprovação
-- Hospital = Codigo_Unidade_Desejada (destino da solicitação)
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
Aprovados AS (
    SELECT *
    FROM Urg
    WHERE Data_Internacao IS NOT NULL
       OR status LIKE '%INTERNADO%'
       OR status LIKE '%INTERNADA%'
       OR status LIKE '%APROVADA%'
)
SELECT
    Codigo_Unidade_Desejada                            AS cnes_hospital,
    Hospital_Desejado                                  AS hospital,
    COUNT(*)                                           AS total_aprovados,
    -- Aprovados com internação confirmada (Data_Internacao preenchida)
    SUM(CASE WHEN Data_Internacao IS NOT NULL THEN 1 ELSE 0 END)
                                                       AS com_data_internacao,
    -- Aprovados só por status (sem data de internação registrada)
    SUM(CASE WHEN Data_Internacao IS NULL
              AND (status LIKE '%INTERNADO%' OR status LIKE '%APROVADA%')
             THEN 1 ELSE 0 END)                        AS aprovados_sem_data,
    -- Tempo médio entre solicitação e internação (em dias)
    AVG(CASE WHEN Data_Internacao IS NOT NULL
             THEN DATEDIFF(day, Data_Solicitacao, Data_Internacao)
             END)                                      AS media_dias_solicitacao_a_internacao,
    MIN(CASE WHEN Data_Internacao IS NOT NULL
             THEN DATEDIFF(day, Data_Solicitacao, Data_Internacao)
             END)                                      AS min_dias,
    MAX(CASE WHEN Data_Internacao IS NOT NULL
             THEN DATEDIFF(day, Data_Solicitacao, Data_Internacao)
             END)                                      AS max_dias
FROM Aprovados
GROUP BY Codigo_Unidade_Desejada, Hospital_Desejado
ORDER BY total_aprovados DESC;
