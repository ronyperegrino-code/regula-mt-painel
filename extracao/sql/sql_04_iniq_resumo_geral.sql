SELECT
    MIN(Data_Solicitacao) AS Data_Inicio, MAX(Data_Solicitacao) AS Data_Fim,
    COUNT(*) AS Total_Solicitacoes,
    COUNT(DISTINCT Chave_Paciente) AS Pacientes_Distintos,
    COUNT(DISTINCT CASE WHEN Flag_Sem_Internacao_Ate_7d=0 THEN Chave_Paciente END) AS Pacientes_Com_Internacao_Ate_7d,
    COUNT(DISTINCT CASE WHEN Flag_Sem_Internacao_Ate_7d=1 THEN Chave_Paciente END) AS Pacientes_Sem_Internacao_Ate_7d,
    SUM(CASE WHEN Janela_7_Dias_Completa=0 THEN 1 ELSE 0 END) AS Casos_Janela_Incompleta
FROM #Eventos;