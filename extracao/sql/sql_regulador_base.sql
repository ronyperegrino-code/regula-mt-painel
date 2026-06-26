-- =============================================================================
-- sql_regulador_base.sql
-- Extrai TODAS as solicitações da VW_HOSPITALAR no período, sem filtro de
-- hospital (Codigo_Unidade_Desejada) e sem filtro de caráter.
-- Cria #ReguladorBase com deduplicação por codigo_solicitacao.
-- =============================================================================

IF OBJECT_ID('tempdb..#ReguladorBase') IS NOT NULL DROP TABLE #ReguladorBase;

WITH Fonte AS (
    SELECT
        H.PK_Seq,
        CAST(H.codigo_solicitacao          AS varchar(100))   AS codigo_solicitacao,
        CAST(H.status                      AS nvarchar(100))  AS status,
        CAST(H.Numero_AIH                  AS varchar(100))   AS Numero_AIH,
        CAST(H.no_usuario                  AS nvarchar(250))  AS Nome_Paciente,
        CAST(H.cns_usuario                 AS varchar(50))    AS cns_usuario,
        CAST(H.cpf_usuario                 AS varchar(50))    AS cpf_usuario,
        CAST(H.dt_nascimento_usuario       AS varchar(50))    AS dt_nascimento_usuario,
        CAST(H.sexo_usuario                AS nvarchar(50))   AS Sexo,
        CAST(H.municipio_paciente_residencia AS nvarchar(250)) AS Municipio_Residencia,
        CAST(H.justificativa               AS nvarchar(max))  AS Justificativa_Internacao,
        CAST(H.sintomas                    AS nvarchar(max))  AS Sintomas,
        CAST(H.exames                      AS nvarchar(max))  AS Exames,
        CAST(H.justificativa_impedimento   AS nvarchar(max))  AS Justificativa_Impedimento,
        CAST(H.codigo_cid                  AS varchar(20))    AS codigo_cid,
        CAST(H.descricao_cid               AS nvarchar(500))  AS descricao_cid,

        -- Chave de identidade: CNS > CPF > NOME|NASC
        CAST(COALESCE(
            NULLIF(LTRIM(RTRIM(CAST(H.cns_usuario AS varchar(50)))), ''),
            NULLIF(LTRIM(RTRIM(CAST(H.cpf_usuario AS varchar(50)))), ''),
            NULLIF(
                UPPER(LTRIM(RTRIM(CAST(H.no_usuario AS nvarchar(250))))) + '|'
                + ISNULL(CAST(H.dt_nascimento_usuario AS varchar(50)), ''), '|'
            )
        ) AS varchar(300)) AS Chave_Paciente,

        CAST(H.codigo_unidade_solicitante  AS varchar(20))    AS Codigo_Unidade_Solicitante,
        CAST(H.nome_unidade_solicitante    AS nvarchar(250))  AS Nome_Unidade_Solicitante,
        CAST(H.codigo_unidade_desejada     AS varchar(20))    AS Codigo_Unidade_Desejada,
        CAST(H.nome_unidade_desejada       AS nvarchar(250))  AS Hospital_Desejado,
        CAST(H.codigo_unidade_executante   AS varchar(20))    AS Codigo_Unidade_Executante,
        CAST(H.nome_unidade_executante     AS nvarchar(250))  AS Nome_Unidade_Executante,
        CAST(H.municipio_unidade_executante AS nvarchar(250)) AS Municipio_Unidade_Executante,
        CAST(H.codigo_central_solicitante  AS varchar(20))    AS Codigo_Central_Solicitante,
        CAST(H.nome_central_solicitante    AS nvarchar(250))  AS Nome_Central_Solicitante,
        CAST(H.codigo_central_reguladora   AS varchar(20))    AS Codigo_Central_Reguladora,
        CAST(H.nome_central_reguladora     AS nvarchar(250))  AS Nome_Central_Reguladora,
        CAST(H.codigo_procedimento         AS varchar(50))    AS Codigo_Procedimento,
        CAST(H.descricao_procedimento      AS nvarchar(500))  AS Procedimento,
        CAST(H.carater                     AS nvarchar(100))  AS Carater,
        CAST(H.nome_clinica                AS nvarchar(200))  AS Clinica,

        TRY_CONVERT(date, NULLIF(CAST(H.data_solicitacao AS varchar(50)), '*Em Branco')) AS Data_Solicitacao,
        TRY_CONVERT(date, NULLIF(CAST(H.data_reserva     AS varchar(50)), '*Em Branco')) AS Data_Reserva,
        TRY_CONVERT(date, NULLIF(CAST(H.data_internacao  AS varchar(50)), '*Em Branco')) AS Data_Internacao,
        TRY_CONVERT(date, NULLIF(CAST(H.data_alta        AS varchar(50)), '*Em Branco')) AS Data_Alta,
        TRY_CONVERT(datetime2, NULLIF(CAST(H.dt_atualizacao AS varchar(50)), '*Em Branco')) AS Dt_Atualizacao,

        ROW_NUMBER() OVER (
            PARTITION BY H.codigo_solicitacao
            ORDER BY TRY_CONVERT(datetime2, NULLIF(CAST(H.dt_atualizacao AS varchar(50)), '*Em Branco')) DESC,
                     H.PK_Seq DESC
        ) AS rn

    FROM dbo.VW_HOSPITALAR H
    WHERE TRY_CONVERT(date, NULLIF(CAST(H.data_solicitacao AS varchar(50)), '*Em Branco')) >= @Inicio
      AND TRY_CONVERT(date, NULLIF(CAST(H.data_solicitacao AS varchar(50)), '*Em Branco')) <= CAST(GETDATE() AS date)
      AND YEAR(TRY_CONVERT(date, NULLIF(CAST(H.data_solicitacao AS varchar(50)), '*Em Branco'))) <= @AnoFim
    -- SEM filtro de Codigo_Unidade_Desejada (todos os hospitais)
    -- SEM filtro de Carater (todos os caracteres)
)
SELECT
    codigo_solicitacao,
    status,
    Numero_AIH,
    Nome_Paciente,
    cns_usuario,
    cpf_usuario,
    dt_nascimento_usuario,
    Sexo,
    Municipio_Residencia,
    Chave_Paciente,
    Codigo_Unidade_Solicitante,
    Nome_Unidade_Solicitante,
    Codigo_Unidade_Desejada,
    Hospital_Desejado,
    Codigo_Unidade_Executante,
    Nome_Unidade_Executante,
    Municipio_Unidade_Executante,
    Codigo_Central_Solicitante,
    Nome_Central_Solicitante,
    Codigo_Central_Reguladora,
    Nome_Central_Reguladora,
    Codigo_Procedimento,
    Procedimento,
    Carater,
    Clinica,
    codigo_cid,
    descricao_cid,
    Justificativa_Internacao,
    Justificativa_Impedimento,
    Sintomas,
    Exames,
    Data_Solicitacao,
    Data_Reserva,
    Data_Internacao,
    Data_Alta,
    Dt_Atualizacao,
    DATEDIFF(day, Data_Solicitacao, ISNULL(Data_Internacao, CAST(GETDATE() AS date))) AS Dias_Total_Ate_Internacao
INTO #ReguladorBase
FROM Fonte
WHERE rn = 1
  AND Data_Solicitacao IS NOT NULL;

CREATE INDEX IX_RegBase_Desejada ON #ReguladorBase (Codigo_Unidade_Desejada, Data_Solicitacao);
CREATE INDEX IX_RegBase_Carater  ON #ReguladorBase (Carater, Data_Solicitacao);
