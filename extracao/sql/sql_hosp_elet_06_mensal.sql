-- sql_hosp_elet_06_mensal.sql — ELETIVO: evolução mensal por situação
SELECT
    YEAR(Data_Solicitacao) AS Ano, MONTH(Data_Solicitacao) AS Mes,
    SUM(CASE WHEN Data_Internacao IS NOT NULL THEN 1 ELSE 0 END) AS Internados,
    SUM(CASE WHEN Data_Reserva IS NOT NULL AND Data_Internacao IS NULL THEN 1 ELSE 0 END) AS Nao_Atendidos,
    SUM(CASE WHEN Data_Reserva IS NULL AND Data_Internacao IS NULL
              AND UPPER(LTRIM(RTRIM(status))) NOT LIKE '%NEGAD%'
              AND UPPER(LTRIM(RTRIM(status))) NOT LIKE '%DEVOLV%'
              AND UPPER(LTRIM(RTRIM(status))) NOT LIKE '%CANCEL%'
             THEN 1 ELSE 0 END) AS Aguarda_Agendamento,
    SUM(CASE WHEN UPPER(LTRIM(RTRIM(status))) LIKE '%NEGAD%'
              OR UPPER(LTRIM(RTRIM(status))) LIKE '%DEVOLV%'
              OR UPPER(LTRIM(RTRIM(status))) LIKE '%CANCEL%'
             THEN 1 ELSE 0 END) AS Negados_Devolvidos,
    COUNT(*) AS Total
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
GROUP BY YEAR(Data_Solicitacao), MONTH(Data_Solicitacao)
ORDER BY Ano, Mes;
