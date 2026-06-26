WITH Contatos AS (
    SELECT
        N.codigo_solicitacao    AS Sol_Negada,
        N.Chave_Paciente,
        N.Nome_Paciente,
        N.cns_usuario,
        N.cpf_usuario,
        N.Nome_Unidade_Solicitante AS Municipio_Origem,
        N.Codigo_Procedimento   AS Proc_Negado_Cod,
        N.Procedimento          AS Proc_Negado,
        N.Carater,
        N.Data_Solicitacao      AS Data_Negativa,
        N.status                AS Status_Negativa,
        N.Categoria_Negativa,
        N.Dias_Desde_Solicitacao,
        LEFT(CAST(N.Justificativa_Impedimento AS nvarchar(max)), 200) AS Justificativa,
        R.codigo_solicitacao    AS Sol_Rede,
        R.Codigo_Unidade_Executante AS CNES_Destino,
        R.Nome_Unidade_Executante   AS Hospital_Destino,
        R.Municipio_Unidade_Executante AS Municipio_Destino,
        R.Codigo_Procedimento   AS Proc_Destino_Cod,
        R.Procedimento          AS Proc_Destino,
        R.Data_Solicitacao      AS Data_Sol_Destino,
        R.Data_Internacao       AS Data_Internacao_Destino,
        R.Data_Alta             AS Data_Alta_Destino,
        R.status                AS Status_Destino,
        R.Numero_AIH            AS AIH_Destino,
        DATEDIFF(day, N.Data_Solicitacao, R.Data_Internacao) AS Dias_Ate_Internacao,
        CASE
            WHEN R.Data_Internacao IS NOT NULL
                 AND R.Codigo_Unidade_Executante = @CNES_Hospital
                THEN 'INTERNADO_HOSPITAL_ANALISADO'
            WHEN R.Data_Internacao IS NOT NULL
                 AND R.Codigo_Unidade_Executante IN (
                     '2396424','2397676','2397684','2397501','2391635',
                     '9209352','3269728','4069803','2495015','2392704',
                     '2604426','2473046','2699842','2396866','2655411','2752654')
                THEN 'INTERNADO_OUTRO_PORTARIA'
            WHEN R.Data_Internacao IS NOT NULL
                THEN 'INTERNADO_FORA_PORTARIA'
            WHEN R.status = 'Aprovada' AND R.Data_Internacao IS NULL
                THEN 'APROVADA_SEM_INTERNACAO'
            WHEN R.status IN ('Pendente','Reenviada','Devolvida')
                THEN 'NOVA_SOLICITACAO_PENDENTE'
            WHEN R.status = 'Negada'
                THEN 'NOVA_NEGATIVA'
            WHEN R.codigo_solicitacao IS NULL
                THEN 'SEM_CONTATO_NA_REDE'
            ELSE 'OUTRO'
        END AS Classificacao_Contato,
        -- Prioridade para selecionar o melhor contato
        ROW_NUMBER() OVER (
            PARTITION BY N.codigo_solicitacao
            ORDER BY
                CASE
                    WHEN R.Data_Internacao IS NOT NULL THEN 1  -- internacao tem prioridade
                    WHEN R.status = 'Aprovada'         THEN 2
                    WHEN R.status = 'Pendente'         THEN 3
                    WHEN R.status = 'Negada'           THEN 4
                    ELSE 5
                END,
                R.Data_Solicitacao ASC
        ) AS rn_contato
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
SELECT * FROM Contatos WHERE rn_contato = 1
ORDER BY Categoria_Negativa, Municipio_Origem, Data_Negativa;