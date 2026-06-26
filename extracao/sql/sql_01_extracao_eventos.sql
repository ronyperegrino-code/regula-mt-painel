IF OBJECT_ID('tempdb..#Base') IS NOT NULL DROP TABLE #Base;

WITH Fonte AS (
    SELECT
        H.PK_Seq,
        CAST(H.codigo_solicitacao AS varchar(100)) AS codigo_solicitacao,
        CAST(H.status AS nvarchar(100)) AS status,
        CAST(H.Numero_AIH AS varchar(100)) AS Numero_AIH,
        CAST(H.no_usuario AS nvarchar(250)) AS Nome_Paciente,
        CAST(H.cns_usuario AS varchar(50)) AS cns_usuario,
        CAST(H.cpf_usuario AS varchar(50)) AS cpf_usuario,
        CAST(H.dt_nascimento_usuario AS varchar(50)) AS dt_nascimento_usuario,
        CAST(H.sexo_usuario AS nvarchar(50)) AS Sexo,
        CAST(H.municipio_paciente_residencia AS nvarchar(250)) AS Municipio_Residencia,
        CAST(H.justificativa AS nvarchar(max)) AS Justificativa_Internacao,
        CAST(H.sintomas AS nvarchar(max)) AS Sintomas,
        CAST(H.exames AS nvarchar(max)) AS Exames,

        CAST(
            COALESCE(
                NULLIF(LTRIM(RTRIM(CAST(H.cns_usuario AS varchar(50)))), ''),
                NULLIF(LTRIM(RTRIM(CAST(H.cpf_usuario AS varchar(50)))), ''),
                NULLIF(
                    UPPER(LTRIM(RTRIM(CAST(H.no_usuario AS nvarchar(250))))) + '|'
                    + ISNULL(CAST(H.dt_nascimento_usuario AS varchar(50)), ''), '|'
                )
            ) AS varchar(300)
        ) AS Chave_Paciente,

        CASE
            WHEN NULLIF(LTRIM(RTRIM(CAST(H.cns_usuario AS varchar(50)))), '') IS NOT NULL THEN 'CNS'
            WHEN NULLIF(LTRIM(RTRIM(CAST(H.cpf_usuario AS varchar(50)))), '') IS NOT NULL THEN 'CPF'
            WHEN NULLIF(UPPER(LTRIM(RTRIM(CAST(H.no_usuario AS nvarchar(250))))), '') IS NOT NULL THEN 'NOME_NASC'
            ELSE 'SEM_CHAVE'
        END AS Chave_Paciente_Tipo,

        CAST(H.codigo_unidade_solicitante AS varchar(20)) AS Codigo_Unidade_Solicitante,
        CAST(H.nome_unidade_solicitante AS nvarchar(250)) AS Nome_Unidade_Solicitante,
        CAST('NAO_DISPONIVEL_NA_VIEW' AS nvarchar(250)) AS Municipio_Unidade_Solicitante,
        CAST(H.codigo_unidade_desejada AS varchar(20)) AS Codigo_Unidade_Desejada,
        CAST(H.nome_unidade_desejada AS nvarchar(250)) AS Nome_Unidade_Desejada,
        CAST(H.codigo_unidade_executante AS varchar(20)) AS Codigo_Unidade_Executante,
        CAST(H.nome_unidade_executante AS nvarchar(250)) AS Nome_Unidade_Executante,
        CAST(H.municipio_unidade_executante AS nvarchar(250)) AS Municipio_Unidade_Executante,
        CAST(H.codigo_central_solicitante AS varchar(20)) AS Codigo_Central_Solicitante,
        CAST(H.nome_central_solicitante AS nvarchar(250)) AS Nome_Central_Solicitante,
        CAST(H.codigo_central_reguladora AS varchar(20)) AS Codigo_Central_Reguladora,
        CAST(H.nome_central_reguladora AS nvarchar(250)) AS Nome_Central_Reguladora,
        CAST(H.codigo_procedimento AS varchar(50)) AS Codigo_Procedimento,
        CAST(H.descricao_procedimento AS nvarchar(500)) AS Procedimento,
        CAST(H.carater AS nvarchar(100)) AS Carater,
        CAST(H.nome_clinica AS nvarchar(200)) AS Clinica,
        CAST(H.justificativa_impedimento AS nvarchar(max)) AS Justificativa_Impedimento,
        CAST(H.codigo_cid                AS varchar(20))   AS codigo_cid,
        CAST(H.descricao_cid             AS nvarchar(500)) AS descricao_cid,

        TRY_CONVERT(date, NULLIF(CAST(H.data_solicitacao AS varchar(50)), '*Em Branco')) AS Data_Solicitacao,
        TRY_CONVERT(date, NULLIF(CAST(H.data_reserva AS varchar(50)), '*Em Branco')) AS Data_Reserva,
        TRY_CONVERT(date, NULLIF(CAST(H.data_internacao AS varchar(50)), '*Em Branco')) AS Data_Internacao,
        TRY_CONVERT(date, NULLIF(CAST(H.data_alta AS varchar(50)), '*Em Branco')) AS Data_Alta,
        TRY_CONVERT(datetime2, NULLIF(CAST(H.dt_atualizacao AS varchar(50)), '*Em Branco')) AS Dt_Atualizacao,

        ROW_NUMBER() OVER (
            PARTITION BY H.codigo_solicitacao
            ORDER BY TRY_CONVERT(datetime2, NULLIF(CAST(H.dt_atualizacao AS varchar(50)), '*Em Branco')) DESC,
                     H.PK_Seq DESC
        ) AS rn

    FROM dbo.VW_HOSPITALAR H
    WHERE TRY_CONVERT(date, NULLIF(CAST(H.data_solicitacao AS varchar(50)), '*Em Branco')) >= @Inicio
      AND TRY_CONVERT(date, NULLIF(CAST(H.data_solicitacao AS varchar(50)), '*Em Branco')) < @FimBusca
      AND YEAR(TRY_CONVERT(date, NULLIF(CAST(H.data_solicitacao AS varchar(50)), '*Em Branco'))) <= @AnoFim
)
SELECT * INTO #Base
FROM Fonte
WHERE rn = 1;

IF OBJECT_ID('tempdb..#Eventos') IS NOT NULL DROP TABLE #Eventos;

SELECT
    B.codigo_solicitacao,
    B.Data_Solicitacao,
    YEAR(B.Data_Solicitacao) AS Ano_Solicitacao,
    MONTH(B.Data_Solicitacao) AS Mes_Solicitacao,
    B.status,
    B.Nome_Paciente,
    B.cns_usuario,
    B.cpf_usuario,
    B.dt_nascimento_usuario AS Dt_Nascimento,
    B.Sexo,
    CASE
        WHEN TRY_CONVERT(date, NULLIF(B.dt_nascimento_usuario, '*Em Branco')) IS NULL THEN 'NAO_INFORMADO'
        WHEN DATEDIFF(year, TRY_CONVERT(date, NULLIF(B.dt_nascimento_usuario, '*Em Branco')), B.Data_Solicitacao) < 1 THEN '<1'
        WHEN DATEDIFF(year, TRY_CONVERT(date, NULLIF(B.dt_nascimento_usuario, '*Em Branco')), B.Data_Solicitacao) BETWEEN 1 AND 4 THEN '01-04'
        WHEN DATEDIFF(year, TRY_CONVERT(date, NULLIF(B.dt_nascimento_usuario, '*Em Branco')), B.Data_Solicitacao) BETWEEN 5 AND 9 THEN '05-09'
        WHEN DATEDIFF(year, TRY_CONVERT(date, NULLIF(B.dt_nascimento_usuario, '*Em Branco')), B.Data_Solicitacao) BETWEEN 10 AND 14 THEN '10-14'
        WHEN DATEDIFF(year, TRY_CONVERT(date, NULLIF(B.dt_nascimento_usuario, '*Em Branco')), B.Data_Solicitacao) BETWEEN 15 AND 19 THEN '15-19'
        WHEN DATEDIFF(year, TRY_CONVERT(date, NULLIF(B.dt_nascimento_usuario, '*Em Branco')), B.Data_Solicitacao) BETWEEN 20 AND 29 THEN '20-29'
        WHEN DATEDIFF(year, TRY_CONVERT(date, NULLIF(B.dt_nascimento_usuario, '*Em Branco')), B.Data_Solicitacao) BETWEEN 30 AND 39 THEN '30-39'
        WHEN DATEDIFF(year, TRY_CONVERT(date, NULLIF(B.dt_nascimento_usuario, '*Em Branco')), B.Data_Solicitacao) BETWEEN 40 AND 49 THEN '40-49'
        WHEN DATEDIFF(year, TRY_CONVERT(date, NULLIF(B.dt_nascimento_usuario, '*Em Branco')), B.Data_Solicitacao) BETWEEN 50 AND 59 THEN '50-59'
        WHEN DATEDIFF(year, TRY_CONVERT(date, NULLIF(B.dt_nascimento_usuario, '*Em Branco')), B.Data_Solicitacao) BETWEEN 60 AND 69 THEN '60-69'
        WHEN DATEDIFF(year, TRY_CONVERT(date, NULLIF(B.dt_nascimento_usuario, '*Em Branco')), B.Data_Solicitacao) BETWEEN 70 AND 79 THEN '70-79'
        ELSE '80+'
    END AS Faixa_Etaria,
    B.Municipio_Residencia,
    B.Chave_Paciente,
    B.Chave_Paciente_Tipo,
    B.Codigo_Unidade_Solicitante,
    B.Nome_Unidade_Solicitante,
    B.Municipio_Unidade_Solicitante,
    B.Codigo_Unidade_Desejada,
    B.Nome_Unidade_Desejada,
    B.Codigo_Unidade_Executante,
    B.Nome_Unidade_Executante,
    B.Municipio_Unidade_Executante,
    B.Codigo_Central_Solicitante,
    B.Nome_Central_Solicitante,
    B.Codigo_Central_Reguladora,
    B.Nome_Central_Reguladora,
    CASE
        WHEN NULLIF(LTRIM(RTRIM(B.Nome_Central_Reguladora)), '') IS NOT NULL
             THEN B.Nome_Central_Reguladora
        WHEN NULLIF(LTRIM(RTRIM(B.Nome_Central_Solicitante)), '') IS NOT NULL
             THEN B.Nome_Central_Solicitante
        WHEN B.Nome_Unidade_Desejada LIKE '%CRUE%'
          OR B.Nome_Unidade_Desejada LIKE '%CENTRAL%REGULACAO%'
          OR B.Nome_Unidade_Solicitante LIKE '%CRUE%'
          OR B.Nome_Unidade_Solicitante LIKE '%CENTRAL%REGULACAO%'
             THEN 'CRUE - Central de Regulacao Estadual'
        WHEN B.Nome_Unidade_Desejada LIKE '%ESCRITORIO REGIONAL%'
          OR B.Nome_Unidade_Solicitante LIKE '%ESCRITORIO REGIONAL%'
             THEN 'ERS - Escritorio Regional de Saude'
        WHEN B.Nome_Unidade_Desejada LIKE '%NIR%'
          OR B.Nome_Unidade_Solicitante LIKE '%NIR%'
             THEN 'NIR - Nucleo Interno de Regulacao'
        ELSE 'NAO_IDENTIFICADA'
    END AS Central_Regulacao,
    B.Codigo_Procedimento,
    B.Procedimento,
    B.Carater,
    B.Clinica,
    B.codigo_cid,
    B.descricao_cid,
    B.Justificativa_Impedimento,
    B.Justificativa_Internacao,
    B.Sintomas,
    B.Exames,
    B.Numero_AIH,
    B.Data_Reserva,
    B.Data_Internacao,
    B.Data_Alta,

    CASE 
        WHEN DATEADD(day, 7, B.Data_Solicitacao) <= @DataAtual THEN 1 
        ELSE 0 
    END AS Janela_7_Dias_Completa,

    M.codigo_solicitacao AS Solicitacao_Internacao_Ate_7d,
    M.Numero_AIH AS AIH_Internacao_Ate_7d,
    M.Data_Internacao AS Data_Internacao_Ate_7d,
    DATEDIFF(day, B.Data_Solicitacao, M.Data_Internacao) AS Dias_Ate_Internacao,
    M15.codigo_solicitacao AS Solicitacao_Internacao_Ate_15d,
    M15.Numero_AIH AS AIH_Internacao_Ate_15d,
    M15.Data_Internacao AS Data_Internacao_Ate_15d,
    DATEDIFF(day, B.Data_Solicitacao, M15.Data_Internacao) AS Dias_Ate_Internacao_15d,

    NP.codigo_solicitacao AS Solicitacao_Posterior,
    NP.Data_Solicitacao AS Data_Solicitacao_Posterior,
    DATEDIFF(day, B.Data_Solicitacao, NP.Data_Solicitacao) AS Dias_Ate_Solicitacao_Posterior,
    NP.status AS Status_Solicitacao_Posterior,
    NP.Codigo_Procedimento AS Codigo_Procedimento_Posterior,
    NP.Procedimento AS Procedimento_Posterior,
    NP.Data_Internacao AS Data_Internacao_Posterior,
    DATEDIFF(day, B.Data_Solicitacao, NP.Data_Internacao) AS Dias_Ate_Internacao_Posterior,

    CASE
        WHEN M.codigo_solicitacao IS NULL THEN 1
        ELSE 0
    END AS Flag_Sem_Internacao_Ate_7d,

    CASE
        WHEN M15.codigo_solicitacao IS NULL THEN 1
        ELSE 0
    END AS Flag_Sem_Internacao_Ate_15d,

    -- 1 = regulador registrou algum impedimento; 0 = aprovação direta / sem barreira documentada.
    -- Permite filtrar apenas casos negados/impedidos nas queries downstream
    -- sem excluir aprovações do universo total (necessário para comparação com SIH).
    CASE
        WHEN NULLIF(LTRIM(RTRIM(CAST(B.Justificativa_Impedimento AS nvarchar(max)))), '') IS NOT NULL
             THEN 1 ELSE 0
    END AS Flag_Com_Impedimento

INTO #Eventos
FROM #Base B
OUTER APPLY (
    SELECT TOP 1 B2.*
    FROM #Base B2
    WHERE B2.Chave_Paciente = B.Chave_Paciente
      AND B2.Chave_Paciente IS NOT NULL
      AND B2.Chave_Paciente <> 'SEM_CHAVE'
      AND B2.Data_Internacao IS NOT NULL
      AND B2.Codigo_Unidade_Executante = @CNES_Hospital
      AND B2.Data_Internacao >= B.Data_Solicitacao
      AND B2.Data_Internacao <= DATEADD(day, 7, B.Data_Solicitacao)
    ORDER BY B2.Data_Internacao ASC, B2.Data_Solicitacao ASC, B2.codigo_solicitacao ASC
) M
OUTER APPLY (
    SELECT TOP 1 B2.*
    FROM #Base B2
    WHERE B2.Chave_Paciente = B.Chave_Paciente
      AND B2.Chave_Paciente IS NOT NULL
      AND B2.Chave_Paciente <> 'SEM_CHAVE'
      AND B2.Data_Internacao IS NOT NULL
      AND B2.Codigo_Unidade_Executante = @CNES_Hospital
      AND B2.Data_Internacao >= B.Data_Solicitacao
      AND B2.Data_Internacao <= DATEADD(day, 15, B.Data_Solicitacao)
    ORDER BY B2.Data_Internacao ASC, B2.Data_Solicitacao ASC, B2.codigo_solicitacao ASC
) M15
OUTER APPLY (
    SELECT TOP 1 B3.*
    FROM #Base B3
    WHERE B3.Chave_Paciente = B.Chave_Paciente
      AND B3.Chave_Paciente IS NOT NULL
      AND B3.Chave_Paciente <> 'SEM_CHAVE'
      AND B3.codigo_solicitacao <> B.codigo_solicitacao
      AND B3.Data_Solicitacao >= B.Data_Solicitacao
      AND B3.Data_Solicitacao <= DATEADD(day, 90, B.Data_Solicitacao)
    ORDER BY B3.Data_Solicitacao ASC, B3.codigo_solicitacao ASC
) NP
WHERE B.Data_Solicitacao >= @Inicio
  AND B.Data_Solicitacao < @FimSolicitacao
  AND YEAR(B.Data_Solicitacao) <= @AnoFim
  AND B.Codigo_Unidade_Desejada = @CNES_Hospital
  AND (
      UPPER(LTRIM(RTRIM(B.Carater))) IN ('URGENTE', 'URGENCIA', 'EMERGENCIA')
      OR UPPER(LTRIM(RTRIM(B.Carater))) LIKE '%ELETIV%'
  );
