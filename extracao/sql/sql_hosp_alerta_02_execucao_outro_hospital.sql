-- ALERTA 2: solicitação destinada ao CNES analisado, mas executada por outro hospital.
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
    Data_Alta,
    Numero_AIH,
    'Solicitacao da fila do hospital analisado com internacao executada em outro CNES' AS Alerta
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND Data_Internacao IS NOT NULL
  AND NULLIF(LTRIM(RTRIM(Codigo_Unidade_Executante)), '') IS NOT NULL
  AND Codigo_Unidade_Executante <> @CNES_Hospital
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
ORDER BY Data_Internacao, Solicitacao;
