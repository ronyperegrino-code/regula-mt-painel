SELECT
    -- Negativa original
    N.codigo_solicitacao        AS Sol_Negada,
    N.Chave_Paciente,
    N.Chave_Tipo,
    N.Nome_Paciente,
    N.cns_usuario,
    N.cpf_usuario,
    N.Nome_Unidade_Solicitante  AS Municipio_Origem,
    N.Codigo_Procedimento       AS Proc_Negado_Cod,
    N.Procedimento              AS Proc_Negado,
    N.Carater                   AS Carater_Negado,
    N.Data_Solicitacao          AS Data_Negativa,
    N.status                    AS Status_Negativa,
    N.Categoria_Negativa,
    N.Dias_Desde_Solicitacao,
    LEFT(CAST(N.Justificativa_Impedimento AS nvarchar(max)), 300) AS Justificativa,

    -- Contato na rede dentro da janela
    R.codigo_solicitacao        AS Sol_Rede,
    R.Codigo_Unidade_Desejada   AS CNES_Desejado_Rede,
    R.Nome_Unidade_Desejada     AS Hospital_Desejado_Rede,
    R.Codigo_Unidade_Executante AS CNES_Executante_Rede,
    R.Nome_Unidade_Executante   AS Hospital_Executante_Rede,
    R.Municipio_Unidade_Executante,
    R.Codigo_Procedimento       AS Proc_Rede_Cod,
    R.Procedimento              AS Proc_Rede,
    R.Carater                   AS Carater_Rede,
    R.Data_Solicitacao          AS Data_Sol_Rede,
    R.Data_Internacao           AS Data_Internacao_Rede,
    R.Data_Alta                 AS Data_Alta_Rede,
    R.status                    AS Status_Rede,
    R.Numero_AIH                AS AIH_Rede,
    DATEDIFF(day, N.Data_Solicitacao, R.Data_Solicitacao)  AS Dias_Ate_Nova_Sol,
    DATEDIFF(day, N.Data_Solicitacao, R.Data_Internacao)   AS Dias_Ate_Internacao,

    -- Classifica o contato
    CASE
        WHEN R.codigo_solicitacao IS NULL
            THEN 'SEM_CONTATO_NA_REDE'
        WHEN R.Data_Internacao IS NOT NULL
             AND R.Codigo_Unidade_Executante = N.Codigo_Unidade_Desejada  -- hospital analisado
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
        ELSE 'OUTRO_CONTATO'
    END AS Classificacao_Contato

FROM #Negados N
OUTER APPLY (
    -- TODOS os contatos do paciente na rede dentro de JanelaDias
    -- (nao apenas o primeiro — permite ver a jornada completa)
    SELECT R2.*
    FROM #Rede R2
    WHERE R2.Chave_Paciente      = N.Chave_Paciente
      AND R2.codigo_solicitacao <> N.codigo_solicitacao  -- exclui a propria negativa
      AND R2.Data_Solicitacao   >= N.Data_Solicitacao
      AND R2.Data_Solicitacao   <= DATEADD(day, @JanelaDias, N.Data_Solicitacao)
) R
ORDER BY N.Categoria_Negativa, N.Nome_Unidade_Solicitante,
         N.Data_Solicitacao, N.Chave_Paciente, R.Data_Solicitacao;