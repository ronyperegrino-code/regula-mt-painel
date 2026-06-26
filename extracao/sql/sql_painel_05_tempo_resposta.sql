-- =============================================================================
-- MÉTRICA 5 — Tempo de resposta das unidades hospitalares
-- Mede o intervalo entre a solicitação e a resposta do hospital:
--   • Dias_Solicitacao_a_Reserva  = Data_Reserva - Data_Solicitacao
--     (hospital confirmou vaga: mais fiel ao "tempo de resposta")
--   • Dias_Solicitacao_a_Internacao = Data_Internacao - Data_Solicitacao
--     (tempo total até ocupação do leito)
-- Requer: #ReguladorBase criado por sql_regulador_base.sql
-- =============================================================================

WITH Urg AS (
    SELECT *
    FROM #ReguladorBase
    WHERE (
        UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE','URGENCIA','EMERGENCIA','URGÊNCIA','EMERGÊNCIA')
        OR UPPER(LTRIM(RTRIM(Carater))) LIKE '%URG%'
    )
    AND (Data_Reserva IS NOT NULL OR Data_Internacao IS NOT NULL)
    AND Data_Solicitacao IS NOT NULL
),
Tempos AS (
    SELECT
        Codigo_Unidade_Desejada,
        Hospital_Desejado,
        codigo_solicitacao,
        Data_Solicitacao,
        Data_Reserva,
        Data_Internacao,
        CASE WHEN Data_Reserva IS NOT NULL
             THEN DATEDIFF(day, Data_Solicitacao, Data_Reserva)
             END AS dias_a_reserva,
        CASE WHEN Data_Internacao IS NOT NULL
             THEN DATEDIFF(day, Data_Solicitacao, Data_Internacao)
             END AS dias_a_internacao
    FROM Urg
),
-- Agregados normais (COUNT, AVG, SUM) por hospital
Agregado AS (
    SELECT
        Codigo_Unidade_Desejada,
        Hospital_Desejado,
        COUNT(*)                                                       AS solicitacoes_com_resposta,
        COUNT(dias_a_reserva)                                          AS n_com_reserva,
        AVG(CAST(dias_a_reserva AS float))                             AS media_dias_a_reserva,
        MIN(dias_a_reserva)                                            AS min_dias_a_reserva,
        MAX(dias_a_reserva)                                            AS max_dias_a_reserva,
        SUM(CASE WHEN dias_a_reserva = 0            THEN 1 ELSE 0 END) AS reserva_mesmo_dia,
        SUM(CASE WHEN dias_a_reserva BETWEEN 1 AND 2 THEN 1 ELSE 0 END) AS reserva_1_2_dias,
        SUM(CASE WHEN dias_a_reserva BETWEEN 3 AND 7 THEN 1 ELSE 0 END) AS reserva_3_7_dias,
        SUM(CASE WHEN dias_a_reserva > 7             THEN 1 ELSE 0 END) AS reserva_acima_7_dias,
        COUNT(dias_a_internacao)                                       AS n_com_internacao,
        AVG(CAST(dias_a_internacao AS float))                          AS media_dias_a_internacao
    FROM Tempos
    GROUP BY Codigo_Unidade_Desejada, Hospital_Desejado
),
-- Medianas calculadas via window function (sem GROUP BY)
Medianas AS (
    SELECT DISTINCT
        Codigo_Unidade_Desejada,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dias_a_reserva)
            OVER (PARTITION BY Codigo_Unidade_Desejada)    AS mediana_dias_a_reserva,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dias_a_internacao)
            OVER (PARTITION BY Codigo_Unidade_Desejada)    AS mediana_dias_a_internacao
    FROM Tempos
)
SELECT
    a.Codigo_Unidade_Desejada                              AS cnes_hospital,
    a.Hospital_Desejado                                    AS hospital,
    a.solicitacoes_com_resposta,
    a.n_com_reserva,
    a.media_dias_a_reserva,
    m.mediana_dias_a_reserva,
    a.min_dias_a_reserva,
    a.max_dias_a_reserva,
    a.reserva_mesmo_dia,
    a.reserva_1_2_dias,
    a.reserva_3_7_dias,
    a.reserva_acima_7_dias,
    a.n_com_internacao,
    a.media_dias_a_internacao,
    m.mediana_dias_a_internacao
FROM Agregado a
JOIN Medianas m ON a.Codigo_Unidade_Desejada = m.Codigo_Unidade_Desejada
ORDER BY a.media_dias_a_reserva ASC;
