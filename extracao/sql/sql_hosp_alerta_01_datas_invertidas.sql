-- ALERTA 1: internação anterior à reserva formalizada no SISREG.
SELECT
    codigo_solicitacao AS Solicitacao,
    Chave_Paciente,
    Nome_Paciente,
    cns_usuario AS CNS,
    Municipio_Residencia,
    Codigo_Unidade_Desejada AS CNES_Desejado,
    Nome_Unidade_Desejada AS Hospital_Desejado,
    Codigo_Unidade_Executante AS CNES_Executante,
    Nome_Unidade_Executante AS Hospital_Executante,
    Codigo_Procedimento,
    Procedimento,
    Clinica,
    Data_Solicitacao,
    Data_Reserva,
    Data_Internacao,
    DATEDIFF(day, Data_Reserva, Data_Internacao) AS Dias_Reserva_Internacao,
    'Data_Internacao anterior a Data_Reserva: possivel lancamento retroativo ou inversao de datas no SISREG' AS Alerta
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND Data_Reserva IS NOT NULL
  AND Data_Internacao IS NOT NULL
  AND DATEDIFF(day, Data_Reserva, Data_Internacao) < 0
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
ORDER BY Dias_Reserva_Internacao, Data_Solicitacao;
