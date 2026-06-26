SELECT
    N.codigo_solicitacao        AS Sol_Negada,
    N.Chave_Paciente,
    N.Chave_Tipo,
    N.Nome_Paciente,
    N.cns_usuario,
    N.cpf_usuario,
    N.Nome_Unidade_Solicitante  AS Municipio_Origem,
    N.Codigo_Procedimento       AS Proc_Negado_Cod,
    N.Procedimento              AS Proc_Negado,
    N.Carater,
    N.Data_Solicitacao          AS Data_Negativa,
    N.status                    AS Status_Negativa,
    N.Categoria_Negativa,
    N.Dias_Desde_Solicitacao,
    LEFT(CAST(N.Justificativa_Impedimento AS nvarchar(max)), 300) AS Justificativa
FROM #Negados N
WHERE NOT EXISTS (
    SELECT 1 FROM #Rede R2
    WHERE R2.Chave_Paciente      = N.Chave_Paciente
      AND R2.codigo_solicitacao <> N.codigo_solicitacao
      AND R2.Data_Solicitacao   >= N.Data_Solicitacao
      AND R2.Data_Solicitacao   <= DATEADD(day, @JanelaDias, N.Data_Solicitacao)
)
ORDER BY N.Categoria_Negativa, N.Nome_Unidade_Solicitante, N.Data_Solicitacao;