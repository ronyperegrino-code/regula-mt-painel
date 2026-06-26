"""
dividir_hospitalar.py
Gera subconjuntos filtrados a partir dos arquivos completos de urgente e eletivo.

URGENTE  (saida/URGENTE/{nome}_{anos}/):
  urgente_completo.csv                      <- copiado pelo PS1
  urgente_aprovados.csv                     <- Flag_Negativa == "0" (internados em 7 dias)
  urgente_negados_pendentes_devolvidos.csv  <- status NEGAD / DEVOLV / PEND / CANCEL

ELETIVO  (saida/ELETIVO/{nome}_{anos}/):
  eletivo_completo.csv                      <- copiado pelo PS1
  eletivo_aguarda_agendamento.csv           <- sem reserva, sem internacao, nao negado
  eletivo_com_agendamento.csv               <- Data_Reserva preenchida
  eletivo_negado.csv                        <- status / situacao NEGAD / DEVOLV / CANCEL
  eletivo_executado.csv                     <- Data_Internacao preenchida

Uso:
  python dividir_hospitalar.py --urgente <path_completo_urg.csv> --eletivo <path_completo_elet.csv>
"""
import argparse, sys
from pathlib import Path
import pandas as pd
import warnings

warnings.filterwarnings("ignore")
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

parser = argparse.ArgumentParser()
parser.add_argument("--urgente", required=True, help="Caminho para urgente_completo.csv")
parser.add_argument("--eletivo", required=True, help="Caminho para eletivo_completo.csv")
args = parser.parse_args()

SEP = ";"
ENC = "utf-8-sig"


def salvar(df, path, label):
    df.to_csv(path, sep=SEP, index=False, encoding=ENC)
    print(f"  [{label}] {len(df):,} linhas -> {Path(path).name}")


# =============================================================================
# URGENTE
# =============================================================================
urg_path = Path(args.urgente)
if urg_path.exists():
    print(f"\n[URGENTE] {urg_path.name}")
    df = pd.read_csv(urg_path, sep=SEP, dtype=str, low_memory=False)
    print(f"  Total: {len(df):,} registros")
    out = urg_path.parent

    # Aprovados: internados dentro da janela (Flag_Negativa = 0)
    flag_col = next(
        (c for c in ["Flag_Negativa", "Flag_Sem_Internacao_Ate_7d"] if c in df.columns), None
    )
    mask_aprov = df[flag_col].str.strip() == "0" if flag_col else pd.Series([False] * len(df))

    # Negados / Pendentes / Devolvidos (coluna status)
    if "status" in df.columns:
        mask_neg = df["status"].str.upper().str.strip().str.contains(
            r"NEGAD|DEVOLV|PEND|CANCEL", na=False, regex=True
        )
    else:
        mask_neg = ~mask_aprov

    salvar(df[mask_aprov], out / "urgente_aprovados.csv",                   "aprovados")
    salvar(df[mask_neg],   out / "urgente_negados_pendentes_devolvidos.csv", "negados/pend/devol")
    print(f"  Aprovados: {mask_aprov.sum():,} | Negados/Pend/Devol: {mask_neg.sum():,}")
else:
    print(f"[AVISO] Urgente nao encontrado: {urg_path}")

# =============================================================================
# ELETIVO
# =============================================================================
elet_path = Path(args.eletivo)
if elet_path.exists():
    print(f"\n[ELETIVO] {elet_path.name}")
    df = pd.read_csv(elet_path, sep=SEP, dtype=str, low_memory=False)
    print(f"  Total: {len(df):,} registros")
    out = elet_path.parent

    # Coluna de situacao (varia conforme SQL usado para gerar o completo)
    sit_col = next(
        (c for c in ["Situacao_Auditoria", "Situacao"] if c in df.columns), None
    )
    sit = (
        df[sit_col].str.upper().str.strip()
        if sit_col
        else pd.Series([""] * len(df), dtype=str)
    )

    status = (
        df["status"].str.upper().str.strip()
        if "status" in df.columns
        else pd.Series([""] * len(df), dtype=str)
    )

    d_res = df.get("Data_Reserva",    pd.Series([""] * len(df), dtype=str)).fillna("").str.strip()
    d_int = df.get("Data_Internacao", pd.Series([""] * len(df), dtype=str)).fillna("").str.strip()

    # 1. Aguarda agendamento: sem reserva, sem internacao, nao negado
    mask_aguarda = sit.isin([
        "EM_FILA", "REPRESADO_FILA",
        "AGUARDA_AGENDAMENTO", "AGUARDA_AGENDAMENTO_REPRESADO"
    ])
    if not mask_aguarda.any():
        # fallback por datas quando coluna Situacao nao tem os valores esperados
        mask_aguarda = (
            (d_res == "") & (d_int == "") &
            ~status.str.contains(r"NEGAD|DEVOLV|CANCEL", na=False, regex=True)
        )

    # 2. Com agendamento confirmado: Data_Reserva preenchida
    mask_com_agend = d_res != ""

    # 3. Negado / Devolvido / Cancelado
    mask_negado = sit.str.contains(r"NEGAD|DEVOLV|CANCEL", na=False, regex=True)
    if not mask_negado.any():
        mask_negado = status.str.contains(r"NEGAD|DEVOLV|CANCEL", na=False, regex=True)

    # 4. Executado: Data_Internacao preenchida
    mask_exec = d_int != ""

    salvar(df[mask_aguarda],   out / "eletivo_aguarda_agendamento.csv", "aguarda_agendamento")
    salvar(df[mask_com_agend], out / "eletivo_com_agendamento.csv",     "com_agendamento")
    salvar(df[mask_negado],    out / "eletivo_negado.csv",              "negado")
    salvar(df[mask_exec],      out / "eletivo_executado.csv",           "executado")
    print(
        f"  aguarda:{mask_aguarda.sum():,} | com_agend:{mask_com_agend.sum():,} | "
        f"negado:{mask_negado.sum():,} | exec:{mask_exec.sum():,}"
    )
else:
    print(f"[AVISO] Eletivo nao encontrado: {elet_path}")

print("\n[dividir_hospitalar] Concluido.")
