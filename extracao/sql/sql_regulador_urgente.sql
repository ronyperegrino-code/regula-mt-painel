-- =============================================================================
-- sql_regulador_urgente.sql
-- Exporta todas as solicitações URGENTES de #ReguladorBase.
-- Requer: sql_regulador_base.sql executado antes.
-- =============================================================================

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
    Data_Solicitacao,
    Data_Reserva,
    Data_Internacao,
    Data_Alta,
    Dias_Total_Ate_Internacao,
    Dt_Atualizacao
FROM #ReguladorBase
WHERE UPPER(LTRIM(RTRIM(Carater))) IN ('URGENTE', 'URGENCIA', 'EMERGENCIA', 'URGÊNCIA', 'EMERGÊNCIA')
   OR UPPER(LTRIM(RTRIM(Carater))) LIKE '%URG%'
ORDER BY Data_Solicitacao, Codigo_Unidade_Desejada, codigo_solicitacao;
