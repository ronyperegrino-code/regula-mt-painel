-- sql_hosp_elet_02_aguarda.sql
-- AGUARDA_AGENDAMENTO: apenas Data_Solicitacao preenchida
-- Sem Data_Reserva e sem Data_Internacao
-- → paciente ainda na fila regulatória, nunca teve vaga confirmada
SELECT
    codigo_solicitacao AS Solicitacao, Chave_Paciente,
    Nome_Paciente, cns_usuario AS CNS, Sexo, Faixa_Etaria,
    Municipio_Residencia,
    Codigo_Unidade_Solicitante AS CNES_Solicitante,
    Nome_Unidade_Solicitante AS Unidade_Solicitante,
    Municipio_Unidade_Solicitante,
    Codigo_Unidade_Desejada AS CNES_Desejado, Nome_Unidade_Desejada AS Hospital_Desejado,
    Codigo_Unidade_Executante AS CNES_Executante, Nome_Unidade_Executante AS Hospital_Executante,
    Municipio_Unidade_Executante, Central_Regulacao,
    Codigo_Procedimento, Procedimento, Clinica,
    Data_Solicitacao,
    YEAR(Data_Solicitacao) AS Ano, MONTH(Data_Solicitacao) AS Mes,
    DATEDIFF(day, Data_Solicitacao, @DataAtual) AS Dias_Aguardando,
    CASE
        WHEN DATEDIFF(day, Data_Solicitacao, @DataAtual) > 365 THEN 'CRITICO > 1 ano'
        WHEN DATEDIFF(day, Data_Solicitacao, @DataAtual) > 180 THEN 'GRAVE > 6 meses'
        WHEN DATEDIFF(day, Data_Solicitacao, @DataAtual) > 90  THEN 'ATENCAO > 3 meses'
        WHEN DATEDIFF(day, Data_Solicitacao, @DataAtual) > 30  THEN 'REPRESADO > 30 dias'
        ELSE 'EM FILA < 30 dias'
    END                                             AS Classificacao,
    status, Justificativa_Impedimento
FROM #Eventos
WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND Data_Reserva IS NULL
  AND Data_Internacao IS NULL
  AND UPPER(LTRIM(RTRIM(status))) NOT LIKE '%NEGAD%'
  AND UPPER(LTRIM(RTRIM(status))) NOT LIKE '%DEVOLV%'
  AND UPPER(LTRIM(RTRIM(status))) NOT LIKE '%CANCEL%'
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim
ORDER BY Dias_Aguardando DESC;
