-- sql_hosp_elet_05_resumo.sql — ELETIVO: resumo geral por ano e situação
SELECT
    YEAR(Data_Solicitacao) AS Ano,
    CASE
        WHEN UPPER(LTRIM(RTRIM(status))) LIKE '%NEGAD%'
          OR UPPER(LTRIM(RTRIM(status))) LIKE '%DEVOLV%'
          OR UPPER(LTRIM(RTRIM(status))) LIKE '%CANCEL%'
             THEN 'NEGADO_DEVOLVIDO'
        WHEN Data_Internacao IS NOT NULL THEN 'INTERNADO'
        WHEN Data_Reserva IS NOT NULL AND Data_Internacao IS NULL THEN 'NAO_ATENDIDO'
        WHEN Data_Reserva IS NULL AND Data_Internacao IS NULL THEN 'AGUARDA_AGENDAMENTO'
        ELSE 'OUTROS'
    END                                             AS Situacao,
    COUNT(*)                                        AS Total,
    COUNT(DISTINCT Chave_Paciente)                  AS Pacientes,
    ROUND(CAST(COUNT(*) AS float)
          / NULLIF(SUM(COUNT(*)) OVER(PARTITION BY YEAR(Data_Solicitacao)), 0)*100, 1) AS Pct_Total,
    ROUND(AVG(CASE WHEN Data_Reserva IS NOT NULL
               THEN CAST(DATEDIFF(day, Data_Solicitacao, Data_Reserva) AS float) END), 1)
                                                    AS Media_Dias_Ate_Reserva,
    ROUND(AVG(CASE WHEN Data_Reserva IS NOT NULL AND Data_Internacao IS NOT NULL
               THEN CAST(DATEDIFF(day, Data_Reserva, Data_Internacao) AS float) END), 1)
                                                    AS Media_Dias_Reserva_Internacao,
    MAX(DATEDIFF(day, Data_Solicitacao, @DataAtual)) AS Max_Dias_Desde_Solicitacao
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
GROUP BY
    YEAR(Data_Solicitacao),
    CASE
        WHEN UPPER(LTRIM(RTRIM(status))) LIKE '%NEGAD%'
          OR UPPER(LTRIM(RTRIM(status))) LIKE '%DEVOLV%'
          OR UPPER(LTRIM(RTRIM(status))) LIKE '%CANCEL%'
             THEN 'NEGADO_DEVOLVIDO'
        WHEN Data_Internacao IS NOT NULL THEN 'INTERNADO'
        WHEN Data_Reserva IS NOT NULL AND Data_Internacao IS NULL THEN 'NAO_ATENDIDO'
        WHEN Data_Reserva IS NULL AND Data_Internacao IS NULL THEN 'AGUARDA_AGENDAMENTO'
        ELSE 'OUTROS'
    END
ORDER BY Ano, Total DESC;
