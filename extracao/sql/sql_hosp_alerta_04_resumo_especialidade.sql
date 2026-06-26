-- Resumo dos procedimentos de amigdalectomia/adenoidectomia por clinica.
SELECT
    Codigo_Procedimento AS Codigo,
    Procedimento,
    SUM(CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(Clinica, '')))) = 'CIRURGIA GERAL' THEN 1 ELSE 0 END) AS Cirurgia_Geral,
    SUM(CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(Clinica, '')))) LIKE '%OTORRINO%' THEN 1 ELSE 0 END) AS Otorrinolaringologia,
    SUM(CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(Clinica, '')))) = 'CARDIOLOGIA' THEN 1 ELSE 0 END) AS Cardiologia,
    SUM(CASE
        WHEN UPPER(LTRIM(RTRIM(ISNULL(Clinica, '')))) NOT IN ('CIRURGIA GERAL', 'CARDIOLOGIA')
         AND UPPER(LTRIM(RTRIM(ISNULL(Clinica, '')))) NOT LIKE '%OTORRINO%'
        THEN 1 ELSE 0
    END) AS Outras_Clinicas,
    COUNT(*) AS Total,
    SUM(CASE WHEN UPPER(LTRIM(RTRIM(ISNULL(Clinica, '')))) NOT LIKE '%OTORRINO%' THEN 1 ELSE 0 END) AS Total_Incompativel
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND Codigo_Procedimento IN ('0404010032', '0404010024', '0404010016')
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
GROUP BY Codigo_Procedimento, Procedimento
ORDER BY Total_Incompativel DESC, Total DESC;
