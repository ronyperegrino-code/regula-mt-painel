-- ALERTA 3: procedimentos de amigdalectomia/adenoidectomia fora de Otorrinolaringologia.
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
    status,
    'Procedimento de amigdalectomia/adenoidectomia lancado fora de Otorrinolaringologia' AS Alerta
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND Codigo_Procedimento IN ('0404010032', '0404010024', '0404010016')
  AND UPPER(LTRIM(RTRIM(ISNULL(Clinica, '')))) NOT LIKE '%OTORRINO%'
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
ORDER BY Codigo_Procedimento, Clinica, Data_Solicitacao;
