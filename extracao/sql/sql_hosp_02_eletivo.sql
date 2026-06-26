-- =============================================================================
-- sql_hosp_02_eletivo.sql
-- Eletivos linha a linha com as TRÊS DATAS FUNDAMENTAIS e indicadores derivados
--
-- Data_Solicitacao → Data_Reserva → Data_Internacao
--
-- Indicadores calculados:
--   Dias_Ate_Reserva          : fila regulatória (espera pela vaga)
--   Dias_Reserva_Internacao   : eficiência do agendamento hospitalar
--   Dias_Total_Ate_Internacao : acesso real do paciente (ponta a ponta)
--   Dias_Desde_Solicitacao    : espera atual (para quem ainda está na fila)
--   Situacao_Auditoria        : classifica o cenário do paciente
-- =============================================================================

SELECT

    -- ── IDENTIFICAÇÃO ─────────────────────────────────────────────────────────
    codigo_solicitacao                          AS Solicitacao,
    Numero_AIH,
    Chave_Paciente,
    Chave_Paciente_Tipo,
    Nome_Paciente,
    cns_usuario                                 AS CNS,
    cpf_usuario                                 AS CPF,
    Sexo,
    Faixa_Etaria,
    Dt_Nascimento,
    Municipio_Residencia,

    -- ── ORIGEM / DESTINO ──────────────────────────────────────────────────────
    Nome_Unidade_Solicitante                    AS Unidade_Solicitante,
    Codigo_Unidade_Solicitante                  AS CNES_Solicitante,
    Municipio_Unidade_Solicitante,
    Codigo_Unidade_Desejada                     AS CNES_Desejado,
    Nome_Unidade_Desejada                       AS Hospital_Desejado,
    Codigo_Unidade_Executante                   AS CNES_Executante,
    Nome_Unidade_Executante                     AS Hospital_Executante,
    Municipio_Unidade_Executante,
    Codigo_Central_Solicitante,
    Nome_Central_Solicitante,
    Codigo_Central_Reguladora,
    Nome_Central_Reguladora,
    Central_Regulacao,

    -- ── PROCEDIMENTO ──────────────────────────────────────────────────────────
    Codigo_Procedimento,
    Procedimento,
    Clinica,
    'ELETIVO'                                   AS Carater,
    'ELETIVO'                                   AS Tipo_Carater,

    -- ── AS TRÊS DATAS FUNDAMENTAIS ────────────────────────────────────────────
    -- 1. Data em que o médico registrou a solicitação na fila
    Data_Solicitacao,
    YEAR(Data_Solicitacao)                      AS Ano,
    MONTH(Data_Solicitacao)                     AS Mes,

    -- 2. Data em que o hospital confirmou a vaga (≠ internação)
    --    NULL = ainda na fila, nenhum hospital aceitou
    Data_Reserva,

    -- 3. Data em que o paciente efetivamente internou
    --    NULL = vaga reservada mas não executada, ou paciente ainda na fila
    Data_Internacao                      AS Data_Internacao,

    -- 4. Data de alta (se houver)
    Data_Alta,

    -- ── INDICADORES DE TEMPO ──────────────────────────────────────────────────

    -- Espera regulatória: quanto tempo até aparecer uma vaga
    -- Fórmula: Reserva - Solicitação
    DATEDIFF(day, Data_Solicitacao, Data_Reserva)
                                                AS Dias_Ate_Reserva,

    -- Eficiência do agendamento hospitalar: tempo entre vaga e internação
    -- Fórmula: Internação - Reserva
    -- Alto = problema interno do hospital (equipe, material, cancelamento)
    DATEDIFF(day, Data_Reserva, Data_Internacao)
                                                AS Dias_Reserva_Internacao,

    -- Acesso real ponta a ponta: experiência total do paciente
    -- Fórmula: Internação - Solicitação
    DATEDIFF(day, Data_Solicitacao, Data_Internacao)
                                                AS Dias_Total_Ate_Internacao,

    -- Dias de internação (se já teve alta; senão, até hoje)
    CASE
        WHEN Data_Internacao IS NOT NULL THEN
            DATEDIFF(day,
                Data_Internacao,
                ISNULL(Data_Alta, @DataAtual))
        ELSE NULL
    END                                         AS Dias_Internado,

    -- Dias na fila desde a solicitação até hoje (para quem ainda aguarda)
    DATEDIFF(day, Data_Solicitacao, @DataAtual) AS Dias_Desde_Solicitacao,

    -- ── CLASSIFICAÇÃO DO CENÁRIO (os 4 cenários de auditoria) ─────────────────
    --
    -- Cenário 1 — Rede funcionando:
    --   Solicitação → Reserva em dias → Internação em dias
    --
    -- Cenário 2 — Problema hospitalar:
    --   Solicitação 01/01 → Reserva 10/01 → Internação 20/06
    --   Vaga existiu, mas internação atrasou muito
    --
    -- Cenário 3 — Fila pura (problema regulatório):
    --   Solicitação 01/01 → Reserva NULL → Internação NULL
    --
    -- Cenário 4 — CRÍTICO: Vaga reservada não executada
    --   Solicitação 01/01 → Reserva 15/03 → Internação NULL
    --
    CASE
        WHEN UPPER(LTRIM(RTRIM(status))) LIKE '%CANCEL%'
             THEN 'CANCELADO'

        WHEN UPPER(LTRIM(RTRIM(status))) LIKE '%NEGAD%'
          OR UPPER(LTRIM(RTRIM(status))) LIKE '%DEVOLV%'
             THEN 'NEGADO_DEVOLVIDO'

        WHEN Data_Internacao IS NOT NULL
             THEN 'INTERNADO'

        WHEN Data_Reserva IS NOT NULL
         AND Data_Internacao IS NULL
             THEN 'VAGA_RESERVADA_NAO_EXECUTADA'   -- Cenário 4: CRÍTICO para auditoria

        WHEN Data_Reserva IS NULL
         AND Data_Internacao IS NULL
         AND DATEDIFF(day, Data_Solicitacao, @DataAtual) > @DiasRepresado
             THEN 'REPRESADO_FILA'                 -- Cenário 3: > 30 dias sem resposta

        WHEN Data_Reserva IS NULL
         AND Data_Internacao IS NULL
             THEN 'EM_FILA'                        -- Aguardando vaga

        ELSE 'OUTROS'
    END                                         AS Situacao_Auditoria,

    -- ── STATUS E JUSTIFICATIVA ────────────────────────────────────────────────
    status,
    Flag_Sem_Internacao_Ate_7d                  AS Flag_Negativa,
    Flag_Sem_Internacao_Ate_15d,
    Janela_7_Dias_Completa                      AS Janela_Completa,
    Solicitacao_Internacao_Ate_15d,
    AIH_Internacao_Ate_15d,
    Data_Internacao_Ate_15d,
    Dias_Ate_Internacao_15d,
    Solicitacao_Posterior,
    Data_Solicitacao_Posterior,
    Dias_Ate_Solicitacao_Posterior,
    Status_Solicitacao_Posterior,
    Codigo_Procedimento_Posterior,
    Procedimento_Posterior,
    Data_Internacao_Posterior,
    Dias_Ate_Internacao_Posterior,
    Justificativa_Impedimento,

    -- Categoria da justificativa
    CASE
        WHEN Justificativa_Impedimento LIKE '%VAGA%'
          OR Justificativa_Impedimento LIKE '%LOTACAO%'
          OR Justificativa_Impedimento LIKE '%SEM LEITO%'
          OR Justificativa_Impedimento LIKE '%NAO LIBER%'
             THEN 'FALTA DE VAGA'
        WHEN Justificativa_Impedimento LIKE '%BOLETIM%'
          OR Justificativa_Impedimento LIKE '%CLINICA ERRAD%'
          OR Justificativa_Impedimento LIKE '%CONFECCAO%'
          OR Justificativa_Impedimento LIKE '%SIGTAP%'
          OR Justificativa_Impedimento LIKE '%ERRADO%'
             THEN 'BARREIRA BUROCRÁTICA'
        WHEN Justificativa_Impedimento LIKE '%AMBULAT%'
          OR Justificativa_Impedimento LIKE '%CONSERVADOR%'
          OR Justificativa_Impedimento LIKE '%BAIXA COMPLEX%'
             THEN 'PERFIL CLÍNICO'
        WHEN Justificativa_Impedimento LIKE '%PARTICULAR%'
          OR Justificativa_Impedimento LIKE '%JA REALIZ%'
          OR Justificativa_Impedimento LIKE '%DESISTIU%'
          OR Justificativa_Impedimento LIKE '%OBITO%'
             THEN 'RESOLUÇÃO EXTERNA'
        WHEN Justificativa_Impedimento LIKE '%DECRETO%'
          OR Justificativa_Impedimento LIKE '%ADMINISTRATIV%'
             THEN 'DEPURAÇÃO ADMINISTRATIVA'
        WHEN NULLIF(LTRIM(RTRIM(
                CAST(Justificativa_Impedimento AS nvarchar(max))
             )), '') IS NULL
             THEN 'SEM JUSTIFICATIVA'
        ELSE 'OUTRO'
    END                                         AS Categoria_Negativa

FROM #Eventos

WHERE UPPER(LTRIM(RTRIM(Carater))) LIKE '%ELETIV%'
  AND YEAR(Data_Solicitacao) BETWEEN YEAR(@Inicio) AND @AnoFim

ORDER BY
    Situacao_Auditoria,
    Data_Solicitacao,
    Dias_Desde_Solicitacao DESC;
