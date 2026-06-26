SELECT
    R.Codigo_Unidade_Executante AS CNES_Destino,
    R.Nome_Unidade_Executante   AS Hospital_Destino,
    R.Municipio_Unidade_Executante,
    CASE
        WHEN R.Codigo_Unidade_Executante = @CNES_Hospital THEN 'PROPRIO_HOSPITAL_ANALISADO'
        WHEN R.Codigo_Unidade_Executante IN (
             '2396424','2397676','2397684','2397501','2391635',
             '9209352','3269728','4069803','2495015','2392704',
             '2604426','2473046','2699842','2396866','2655411','2752654')
            THEN 'PORTARIA_0200'
        ELSE 'FORA_DA_PORTARIA'
    END AS Tipo_Hospital,
    COUNT(*)                        AS Total_Internacoes,
    COUNT(DISTINCT N.Chave_Paciente) AS Pacientes_Distintos,
    ROUND(AVG(CAST(DATEDIFF(day, N.Data_Solicitacao, R.Data_Internacao) AS float)),1)
                                    AS Media_Dias_Ate_Internacao,
    MIN(DATEDIFF(day, N.Data_Solicitacao, R.Data_Internacao)) AS Min_Dias,
    MAX(DATEDIFF(day, N.Data_Solicitacao, R.Data_Internacao)) AS Max_Dias
FROM #Negados N
INNER JOIN #Rede R
    ON  R.Chave_Paciente      = N.Chave_Paciente
    AND R.codigo_solicitacao <> N.codigo_solicitacao
    AND R.Data_Internacao    IS NOT NULL
    AND R.Data_Solicitacao   >= N.Data_Solicitacao
    AND R.Data_Solicitacao   <= DATEADD(day, @JanelaDias, N.Data_Solicitacao)
GROUP BY
    R.Codigo_Unidade_Executante,
    R.Nome_Unidade_Executante,
    R.Municipio_Unidade_Executante,
    CASE
        WHEN R.Codigo_Unidade_Executante = @CNES_Hospital THEN 'PROPRIO_HOSPITAL_ANALISADO'
        WHEN R.Codigo_Unidade_Executante IN (
             '2396424','2397676','2397684','2397501','2391635',
             '9209352','3269728','4069803','2495015','2392704',
             '2604426','2473046','2699842','2396866','2655411','2752654')
            THEN 'PORTARIA_0200'
        ELSE 'FORA_DA_PORTARIA'
    END
ORDER BY Total_Internacoes DESC;