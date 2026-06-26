-- sql_hosp_elet_01_linha.sql — ELETIVO: linha a linha completa com situação
SELECT
    codigo_solicitacao                              AS Solicitacao,
    Chave_Paciente, Nome_Paciente, cns_usuario AS CNS,
    Sexo, Faixa_Etaria, Municipio_Residencia,
    Codigo_Unidade_Solicitante                      AS CNES_Solicitante,
    Nome_Unidade_Solicitante                        AS Unidade_Solicitante,
    Municipio_Unidade_Solicitante,
    Codigo_Unidade_Desejada                         AS CNES_Desejado,
    Nome_Unidade_Desejada                           AS Hospital_Desejado,
    Codigo_Unidade_Executante                       AS CNES_Executante,
    Nome_Unidade_Executante                         AS Hospital_Executante,
    Municipio_Unidade_Executante,
    Central_Regulacao,
    Codigo_Procedimento, Procedimento, Clinica,
    Data_Solicitacao,
    YEAR(Data_Solicitacao) AS Ano, MONTH(Data_Solicitacao) AS Mes,
    Data_Reserva,
    Data_Internacao                          AS Data_Internacao,
    Data_Alta,
    -- Situação com lógica correta
    CASE
        WHEN UPPER(LTRIM(RTRIM(status))) LIKE '%NEGAD%'
          OR UPPER(LTRIM(RTRIM(status))) LIKE '%DEVOLV%'
          OR UPPER(LTRIM(RTRIM(status))) LIKE '%CANCEL%'
             THEN 'NEGADO_DEVOLVIDO'
        WHEN Data_Internacao IS NOT NULL
             THEN 'INTERNADO'
        WHEN Data_Reserva IS NOT NULL AND Data_Internacao IS NULL
             THEN 'NAO_ATENDIDO'
        WHEN Data_Reserva IS NULL AND Data_Internacao IS NULL
             AND DATEDIFF(day, Data_Solicitacao, @DataAtual) > @DiasRepresado
             THEN 'AGUARDA_AGENDAMENTO_REPRESADO'
        WHEN Data_Reserva IS NULL AND Data_Internacao IS NULL
             THEN 'AGUARDA_AGENDAMENTO'
        ELSE 'OUTROS'
    END                                             AS Situacao,
    DATEDIFF(day, Data_Solicitacao, Data_Reserva)   AS Dias_Ate_Reserva,
    DATEDIFF(day, Data_Reserva, Data_Internacao) AS Dias_Reserva_Internacao,
    DATEDIFF(day, Data_Solicitacao, Data_Internacao) AS Dias_Total,
    DATEDIFF(day, Data_Solicitacao, @DataAtual)     AS Dias_Desde_Solicitacao,
    status, Justificativa_Impedimento
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
ORDER BY Situacao, Data_Solicitacao;
