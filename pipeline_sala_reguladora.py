"""
pipeline_sala_reguladora.py
Gera hospitais.csv e evolucao.csv para o Painel Sala Reguladora (Vercel).

Fonte: SISREG_ANALISE/saida/INIQUIDADE_ACESSO/<hospital>/*.csv
Saida: public/hospitais.csv  e  public/evolucao.csv

Uso:
  python pipeline_sala_reguladora.py
  python pipeline_sala_reguladora.py --dias 90
  python pipeline_sala_reguladora.py --dir "D:/outro/caminho/INIQUIDADE_ACESSO"
"""
import argparse
import re
import sys
import warnings
from pathlib import Path

import pandas as pd

warnings.filterwarnings("ignore")
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

# ── Caminhos padrão ───────────────────────────────────────────────────────────
REPO_DIR = Path(__file__).parent
DEFAULT_FONTE = (
    Path.home() / "Desktop" / "SES-MT" / "SISREG_ANALISE"
    / "saida" / "INIQUIDADE_ACESSO"
)
DEFAULT_OUT = REPO_DIR / "public"

# ── Argumentos ────────────────────────────────────────────────────────────────
parser = argparse.ArgumentParser()
parser.add_argument("--dir",  default=str(DEFAULT_FONTE), help="Pasta INIQUIDADE_ACESSO")
parser.add_argument("--dias", type=int, default=60,       help="Dias recentes para evolucao.csv")
parser.add_argument("--min-registros-dia", type=int, default=1)
args = parser.parse_args()

DIR_BASE = Path(args.dir).resolve()
DIR_OUT  = DEFAULT_OUT
DIAS     = args.dias
MIN_REG  = args.min_registros_dia

if not DIR_BASE.exists():
    print(f"[ERRO] Pasta nao encontrada: {DIR_BASE}")
    sys.exit(1)

DIR_OUT.mkdir(parents=True, exist_ok=True)

SEP = ";"
ENC = "utf-8-sig"

UTI_KEYWORDS = [
    "UTI", "U.T.I", "TERAPIA INTENSIVA", "CUIDADOS INTENSIVOS",
    "UNIDADE DE TERAPIA", "CUIDADOS INTERMEDIARIOS",
]


def e_uti(clinica) -> bool:
    if not clinica or pd.isna(clinica):
        return False
    return any(k in str(clinica).upper() for k in UTI_KEYWORDS)


def fmt_dias(valor) -> str:
    try:
        v = float(valor)
        return "< 1 d" if v < 1 else f"{round(v)} d"
    except (TypeError, ValueError):
        return "- d"


def nome_da_pasta(folder: str) -> str:
    name = folder
    for sfx in ["_HOSPITALAR", "_AMBULATORIAL", "_URGENTE"]:
        if name.upper().endswith(sfx):
            name = name[: -len(sfx)]
            break
    name = re.sub(r"_\d{4}_\d{4}$", "", name)
    return name.replace("_", " ").strip()


# ── Leitura ───────────────────────────────────────────────────────────────────
subpastas = sorted(p for p in DIR_BASE.iterdir() if p.is_dir())
print(f"[INFO] {len(subpastas)} pasta(s) encontrada(s) em: {DIR_BASE}\n")

linhas_hosp   = []
frames_global = []

for pasta in subpastas:
    dfs = []
    for arq in ["01_eletivo_linha_a_linha.csv", "01_urgente_linha_a_linha.csv"]:
        fpath = pasta / arq
        if not fpath.exists():
            continue
        try:
            df = pd.read_csv(fpath, sep=SEP, dtype=str, low_memory=False, encoding=ENC)
            df["_fonte"] = arq.split("_")[1]
            dfs.append(df)
        except Exception as e:
            print(f"  [AVISO] {fpath.name}: {e}")

    if not dfs:
        print(f"  [AVISO] Sem dados: {pasta.name}")
        continue

    df = pd.concat(dfs, ignore_index=True)
    total = len(df)

    # Nome do hospital
    nome = ""
    if "Hospital_Desejado" in df.columns:
        vals = df["Hospital_Desejado"].dropna()
        vals = vals[vals.str.strip() != ""]
        if not vals.empty:
            nome = vals.value_counts().index[0].strip().title()
    if not nome:
        nome = nome_da_pasta(pasta.name).title()

    # Aprovações / internações
    mask_int = pd.Series(False, index=df.index)
    if "Situacao_Auditoria" in df.columns:
        mask_int |= df["Situacao_Auditoria"].str.upper().str.contains("INTERNADO", na=False)
    if "status" in df.columns:
        mask_int |= df["status"].str.upper().isin(["INTERNADA", "INTERNADO", "APROVADA"])

    aprovacoes = int(mask_int.sum())
    df_aprov   = df[mask_int].copy()

    # UTI vs Enfermaria
    if "Clinica" in df_aprov.columns:
        mask_uti = df_aprov["Clinica"].apply(e_uti).astype(bool)
    elif "_fonte" in df_aprov.columns:
        mask_uti = (df_aprov["_fonte"] == "urgente").astype(bool)
    else:
        mask_uti = pd.Series(False, index=df_aprov.index, dtype=bool)

    uti        = int(mask_uti.sum())
    enfermaria = int((~mask_uti).sum())

    # Tempo médio
    media_raw  = None
    median_raw = None
    col_dias   = "Dias_Total_Ate_Internacao"
    tempo_str  = "- d"
    median_str = "- d"

    if col_dias in df_aprov.columns and not df_aprov.empty:
        nums = pd.to_numeric(
            df_aprov[col_dias].astype(str).str.replace(",", ".", regex=False),
            errors="coerce",
        )
        nums = nums[nums >= 0]
        if not nums.empty:
            media_raw  = round(float(nums.mean()), 1)
            median_raw = round(float(nums.median()), 1)
            tempo_str  = fmt_dias(media_raw)
            median_str = fmt_dias(median_raw)

    pct = round(aprovacoes / total * 100) if total > 0 else 0

    linhas_hosp.append({
        "hospital":      nome,
        "solicitacoes":  total,
        "aprovacoes":    aprovacoes,
        "uti":           uti,
        "enfermaria":    enfermaria,
        "tempo_medio":   tempo_str,
        "mediana":       median_str,
        "_media_raw":    media_raw,
        "_median_raw":   median_raw,
        "pct_atendidas": pct,
    })

    cols_evo = [c for c in ["Data_Solicitacao", "Situacao_Auditoria", "status"] if c in df.columns]
    frames_global.append(df[cols_evo].copy())

    print(
        f"  [OK] {nome[:45]:<45} | {total:5} sol | {aprovacoes:4} intern "
        f"| UTI={uti} Enf={enfermaria} | {pct}%"
    )

if not linhas_hosp:
    print("[ERRO] Nenhum dado processado.")
    sys.exit(1)

# ── hospitais.csv ─────────────────────────────────────────────────────────────
df_raw = pd.DataFrame(linhas_hosp)
df_raw = df_raw[df_raw["solicitacoes"] > 0]


def consolidar(group):
    total_sol   = group["solicitacoes"].sum()
    total_aprov = group["aprovacoes"].sum()
    total_uti   = group["uti"].sum()
    total_enf   = group["enfermaria"].sum()
    pct = round(total_aprov / total_sol * 100) if total_sol > 0 else 0

    medias  = group["_media_raw"].dropna()
    pesos   = group.loc[medias.index, "aprovacoes"]
    if not medias.empty and pesos.sum() > 0:
        t_med = fmt_dias((medias * pesos).sum() / pesos.sum())
        meds  = group["_median_raw"].dropna()
        t_mdn = fmt_dias(meds.mean()) if not meds.empty else "- d"
    else:
        t_med = group.loc[group["_media_raw"].notna(), "tempo_medio"].iloc[0] if group["_media_raw"].notna().any() else "- d"
        t_mdn = group.loc[group["_median_raw"].notna(), "mediana"].iloc[0]    if group["_median_raw"].notna().any() else "- d"

    return pd.Series({
        "hospital":      group.name,
        "solicitacoes":  total_sol,
        "aprovacoes":    total_aprov,
        "uti":           total_uti,
        "enfermaria":    total_enf,
        "tempo_medio":   t_med,
        "mediana":       t_mdn,
        "pct_atendidas": pct,
    })


df_hosp = (
    df_raw.groupby("hospital", sort=False)
    .apply(consolidar, include_groups=False)
    .reset_index(drop=True)
    .sort_values("solicitacoes", ascending=False)
    .reset_index(drop=True)
)

out_hosp = DIR_OUT / "hospitais.csv"
df_hosp.to_csv(out_hosp, index=False, encoding="utf-8-sig")
print(f"\n[OK] hospitais.csv → {out_hosp}  ({len(df_hosp)} hospitais)")

# ── evolucao.csv ──────────────────────────────────────────────────────────────
if not frames_global:
    print("[AVISO] Sem dados para evolucao.csv.")
    sys.exit(0)

df_global = pd.concat(frames_global, ignore_index=True)

if "Data_Solicitacao" not in df_global.columns:
    print("[AVISO] Coluna Data_Solicitacao ausente. Pulando evolucao.csv.")
    sys.exit(0)

df_global["_data"] = pd.to_datetime(
    df_global["Data_Solicitacao"], dayfirst=True, errors="coerce"
).dt.normalize()
df_global = df_global.dropna(subset=["_data"])

mask_int  = pd.Series(False, index=df_global.index)
mask_pend = pd.Series(False, index=df_global.index)

if "Situacao_Auditoria" in df_global.columns:
    sit = df_global["Situacao_Auditoria"].str.upper().fillna("")
    mask_int  |= sit.str.contains("INTERNADO", na=False)
    mask_pend |= sit.isin(["EM_FILA", "REPRESADO_FILA", "AGUARDA_AGENDAMENTO"])

if "status" in df_global.columns:
    st = df_global["status"].str.upper().fillna("")
    mask_int  |= st.isin(["INTERNADA", "INTERNADO", "APROVADA"])
    mask_pend |= st.isin(["PENDENTE", "EM FILA"])

df_global["_int"]  = mask_int.astype(int)
df_global["_pend"] = mask_pend.astype(int)

evo = (
    df_global.groupby("_data")
    .agg(solicitacoes=("_int", "count"), aprovacoes=("_int", "sum"), pendentes=("_pend", "sum"))
    .reset_index()
    .rename(columns={"_data": "data"})
    .sort_values("data")
)
evo = evo[evo["solicitacoes"] >= MIN_REG].tail(DIAS).copy()
evo["data"] = evo["data"].dt.strftime("%d/%m")
for col in ["solicitacoes", "aprovacoes", "pendentes"]:
    evo[col] = evo[col].astype(int)

out_evo = DIR_OUT / "evolucao.csv"
evo.to_csv(out_evo, index=False, encoding="utf-8-sig")
print(f"[OK] evolucao.csv  → {out_evo}  ({len(evo)} dias)")

# ── Resumo ────────────────────────────────────────────────────────────────────
total_sol   = int(df_hosp["solicitacoes"].sum())
total_aprov = int(df_hosp["aprovacoes"].sum())
taxa        = round(total_aprov / total_sol * 100, 1) if total_sol > 0 else 0
periodo     = f"{evo['data'].iloc[0]} a {evo['data'].iloc[-1]}" if not evo.empty else "N/A"

print("\n" + "=" * 60)
print(f"  TOTAL    : {total_sol:,} solicitacoes | {total_aprov:,} internacoes".replace(",", "."))
print(f"  TAXA     : {taxa}%")
print(f"  PERIODO  : {periodo}")
print(f"  HOSPITAIS: {len(df_hosp)}")
print("=" * 60)
