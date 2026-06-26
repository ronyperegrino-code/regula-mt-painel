-- Busca toda a rede ate JanelaDias apos a data mais recente de solicitacao

-- ─────────────────────────────────────────────────────────────────────────────
-- #Rede: TODA a rede hospitalar no periodo
-- Deduplicado por codigo_solicitacao (mais recente vence)
-- Sem filtro de CNES — captura qualquer hospital do SISREG
-- ─────────────────────────────────────────────────────────────────────────────
IF OBJECT_ID('tempdb..#Rede') IS NOT NULL DROP TABLE #Rede;
WITH Fonte AS (
    SELECT
        H.PK_Seq,
        CAST(H.codigo_solicitacao         AS varchar(100))   AS codigo_solicitacao,
        CAST(H.status                     AS nvarchar(100))  AS status,
        CAST(H.Numero_AIH                 AS varchar(100))   AS Numero_AIH,
        CAST(H.no_usuario                 AS nvarchar(250))  AS Nome_Paciente,
        CAST(H.cns_usuario                AS varchar(50))    AS cns_usuario,
        CAST(H.cpf_usuario                AS varchar(50))    AS cpf_usuario,
        CAST(H.dt_nascimento_usuario      AS varchar(50))    AS dt_nascimento_usuario,
        -- Chave de identidade: CNS > CPF > NOME|NASC
        CAST(COALESCE(
            NULLIF(LTRIM(RTRIM(CAST(H.cns_usuario AS varchar(50)))), ''),
            NULLIF(LTRIM(RTRIM(CAST(H.cpf_usuario AS varchar(50)))), ''),
            NULLIF(
                UPPER(LTRIM(RTRIM(CAST(H.no_usuario AS nvarchar(250))))) + '|'
                + ISNULL(CAST(H.dt_nascimento_usuario AS varchar(50)),''), '|'
            )
        ) AS varchar(300)) AS Chave_Paciente,
        CASE
            WHEN NULLIF(LTRIM(RTRIM(CAST(H.cns_usuario AS varchar(50)))), '') IS NOT NULL THEN 'CNS'
            WHEN NULLIF(LTRIM(RTRIM(CAST(H.cpf_usuario AS varchar(50)))), '') IS NOT NULL THEN 'CPF'
            ELSE 'NOME_NASC'
        END AS Chave_Tipo,
        CAST(H.codigo_unidade_solicitante  AS varchar(20))   AS Codigo_Unidade_Solicitante,
        CAST(H.nome_unidade_solicitante    AS nvarchar(250)) AS Nome_Unidade_Solicitante,
        CAST(H.codigo_unidade_desejada     AS varchar(20))   AS Codigo_Unidade_Desejada,
        CAST(H.nome_unidade_desejada       AS nvarchar(250)) AS Nome_Unidade_Desejada,
        CAST(H.codigo_unidade_executante   AS varchar(20))   AS Codigo_Unidade_Executante,
        CAST(H.nome_unidade_executante     AS nvarchar(250)) AS Nome_Unidade_Executante,
        CAST(H.municipio_unidade_executante AS nvarchar(250)) AS Municipio_Unidade_Executante,
        CAST(H.codigo_procedimento         AS varchar(50))   AS Codigo_Procedimento,
        CAST(H.descricao_procedimento      AS nvarchar(500)) AS Procedimento,
        CAST(H.carater                     AS nvarchar(100)) AS Carater,
        CAST(H.nome_clinica                AS nvarchar(200)) AS Clinica,
        CAST(H.justificativa_impedimento   AS nvarchar(max)) AS Justificativa_Impedimento,
        TRY_CONVERT(date, NULLIF(CAST(H.data_solicitacao AS varchar(50)), '*Em Branco')) AS Data_Solicitacao,
        TRY_CONVERT(date, NULLIF(CAST(H.data_internacao  AS varchar(50)), '*Em Branco')) AS Data_Internacao,
        TRY_CONVERT(date, NULLIF(CAST(H.data_alta        AS varchar(50)), '*Em Branco')) AS Data_Alta,
        TRY_CONVERT(datetime2, NULLIF(CAST(H.dt_atualizacao AS varchar(50)), '*Em Branco')) AS Dt_Atualizacao,
        ROW_NUMBER() OVER (
            PARTITION BY H.codigo_solicitacao
            ORDER BY TRY_CONVERT(datetime2, NULLIF(CAST(H.dt_atualizacao AS varchar(50)),'*Em Branco')) DESC,
                     H.PK_Seq DESC
        ) AS rn
    FROM dbo.VW_HOSPITALAR H
    WHERE TRY_CONVERT(date, NULLIF(CAST(H.data_solicitacao AS varchar(50)), '*Em Branco')) >= @Inicio
      AND TRY_CONVERT(date, NULLIF(CAST(H.data_solicitacao AS varchar(50)), '*Em Branco')) <= @FimBusca
)
SELECT * INTO #Rede FROM Fonte WHERE rn = 1;

CREATE INDEX IX_Rede_Chave ON #Rede (Chave_Paciente, Data_Solicitacao, Data_Internacao);
CREATE INDEX IX_Rede_Exec  ON #Rede (Codigo_Unidade_Executante, Data_Internacao);

-- ─────────────────────────────────────────────────────────────────────────────
-- #Negados: solicitacoes negadas/represadas destinadas ao hospital analisado
-- ─────────────────────────────────────────────────────────────────────────────
IF OBJECT_ID('tempdb..#Negados') IS NOT NULL DROP TABLE #Negados;
SELECT
    R.codigo_solicitacao,
    R.Chave_Paciente,
    R.Chave_Tipo,
    R.Nome_Paciente,
    R.cns_usuario,
    R.cpf_usuario,
    R.Nome_Unidade_Solicitante,
    R.Codigo_Unidade_Solicitante,
    R.Codigo_Unidade_Desejada,
    R.Nome_Unidade_Desejada,
    R.Codigo_Procedimento,
    R.Procedimento,
    R.Carater,
    R.Data_Solicitacao,
    R.Justificativa_Impedimento,
    R.status,
    -- Categoriza a negativa
    CASE
        WHEN UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%CLINIC%ERRAD%'
          OR UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%BOLETIM ERRAD%'
          OR UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%BOLETIM INCORRE%'
          OR UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%DUPLICAD%'
          OR UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%UNIDADE EXECUTANTE ERRAD%'
          OR UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%TROCA DE C%DIG%'
            THEN 'ADMINISTRATIVA'
        WHEN UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%OUTRO MUNIC%'
          OR UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%PARTICULAR%'
          OR UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%JA REALIZ%'
          OR UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%JA OPERO%'
          OR UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%DESISTIU%'
          OR UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%N%O TEM MAIS INTERESSE%'
          OR UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%REALIZAR%OUTRO%'
            THEN 'RESOLUCAO_EXTERNA'
        WHEN UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%FALTA DE VAGA%'
          OR UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%SEM VAGA%'
          OR UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%NAO LIBERADO%VAGA%'
            THEN 'FALTA_DE_VAGA'
        WHEN UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%NAO REALIZA%PROCEDIMENTO%'
          OR UPPER(CAST(R.Justificativa_Impedimento AS nvarchar(max))) LIKE '%N%O OFERTA%'
            THEN 'PROC_NAO_OFERTADO'
        WHEN R.status = 'Pendente' THEN 'REPRESADO_FILA'
        ELSE 'NEGADA_SEM_MOTIVO_CLARO'
    END AS Categoria_Negativa,
    DATEDIFF(day, R.Data_Solicitacao, @DataAtual) AS Dias_Desde_Solicitacao
INTO #Negados
FROM #Rede R
WHERE R.Chave_Paciente IS NOT NULL
  AND R.Chave_Paciente <> 'SEM_CHAVE'
  AND R.Codigo_Unidade_Desejada = @CNES_Hospital
  AND (
      -- Negada com justificativa
      (R.status = 'Negada'
       AND NULLIF(LTRIM(RTRIM(CAST(R.Justificativa_Impedimento AS nvarchar(max)))), '') IS NOT NULL)
      OR
      -- Represado ha mais de X dias
      (R.status = 'Pendente'
       AND DATEDIFF(day, R.Data_Solicitacao, @DataAtual) > @DiasRepresado
       AND R.Data_Internacao IS NULL)
  );