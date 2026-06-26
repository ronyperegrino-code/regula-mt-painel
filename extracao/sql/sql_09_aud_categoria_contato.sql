WITH Melhor AS (
    SELECT
        N.Categoria_Negativa,
        N.Nome_Unidade_Solicitante AS Municipio_Origem,
        N.Chave_Paciente,
        CASE
            WHEN R.Data_Internacao IS NOT NULL
                 AND R.Codigo_Unidade_Executante = @CNES_Hospital      THEN 'INTERNADO_HOSPITAL_ANALISADO'
            WHEN R.Data_Internacao IS NOT NULL
                 AND R.Codigo_Unidade_Executante IN (
                     '2396424','2397676','2397684','2397501','2391635',
                     '9209352','3269728','4069803','2495015','2392704',
                     '2604426','2473046','2699842','2396866','2655411','2752654')
                                                                       THEN 'INTERNADO_OUTRO_PORTARIA'
            WHEN R.Data_Internacao IS NOT NULL                         THEN 'INTERNADO_FORA_PORTARIA'
            WHEN R.status = 'Aprovada' AND R.Data_Internacao IS NULL   THEN 'APROVADA_SEM_INTERNACAO'
            WHEN R.status IN ('Pendente','Reenviada','Devolvida')      THEN 'NOVA_SOL_PENDENTE'
            WHEN R.status = 'Negada'                                   THEN 'NOVA_NEGATIVA'
            WHEN R.codigo_solicitacao IS NULL                          THEN 'SEM_CONTATO_NA_REDE'
            ELSE 'OUTRO'
        END AS Classificacao,
        ROW_NUMBER() OVER (
            PARTITION BY N.codigo_solicitacao
            ORDER BY
                CASE WHEN R.Data_Internacao IS NOT NULL THEN 1
                     WHEN R.status = 'Aprovada'         THEN 2
                     WHEN R.status = 'Pendente'         THEN 3
                     ELSE 4 END,
                R.Data_Solicitacao ASC
        ) AS rn
    FROM #Negados N
    OUTER APPLY (
        SELECT R2.*
        FROM #Rede R2
        WHERE R2.Chave_Paciente      = N.Chave_Paciente
          AND R2.codigo_solicitacao <> N.codigo_solicitacao
          AND R2.Data_Solicitacao   >= N.Data_Solicitacao
          AND R2.Data_Solicitacao   <= DATEADD(day, @JanelaDias, N.Data_Solicitacao)
    ) R
)
SELECT
    Categoria_Negativa,
    Classificacao,
    COUNT(*)                       AS Total_Casos,
    COUNT(DISTINCT Chave_Paciente) AS Pacientes_Distintos
FROM Melhor WHERE rn = 1
GROUP BY Categoria_Negativa, Classificacao
ORDER BY Categoria_Negativa, Total_Casos DESC;