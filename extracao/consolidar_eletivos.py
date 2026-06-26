"""
consolidar_eletivos.py
Gera tabelas consolidadas de eletivos e/ou urgentes a partir dos arquivos
01_eletivo_linha_a_linha.csv e 01_urgente_linha_a_linha.csv.

Agrega por: Municipio_Residencia, Procedimento, status, Situacao, Ano
Metrica:    Cont_sol (contagem de solicitacoes)
Ordena:     Cont_sol DESC

Uso:
  # Apenas eletivo
  python consolidar_eletivos.py --dir <pasta_eletivo>

  # Apenas urgente
  python consolidar_eletivos.py --dir-urgente <pasta_urgente>

  # Ambos
  python consolidar_eletivos.py --dir <pasta_eletivo> --dir-urgente <pasta_urgente>

  # Multiplos hospitais + destinos explícitos
  python consolidar_eletivos.py --dir <d1> <d2> --out <saida_elet.csv>
  python consolidar_eletivos.py --dir-urgente <u1> <u2> --out-urgente <saida_urg.csv>
"""
import argparse, sys
from pathlib import Path
import pandas as pd
import warnings

warnings.filterwarnings("ignore")
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

COLUNAS_GROUP = ["Municipio_Residencia", "Procedimento", "status", "Situacao", "Ano"]
SEP = ";"
ENC = "utf-8-sig"

parser = argparse.ArgumentParser()
parser.add_argument("--dir", nargs="+", default=[],
                    help="Pasta(s) do eletivo (contem 01_eletivo_linha_a_linha.csv)")
parser.add_argument("--dir-urgente", nargs="+", default=[],
                    help="Pasta(s) do urgente (contem 01_urgente_linha_a_linha.csv)")
parser.add_argument("--out", default="",
                    help="Saida eletivo (padrao: pasta pai do primeiro --dir / TABELA_ELETIVOS_CONSOLIDADA.csv)")
parser.add_argument("--out-urgente", default="",
                    help="Saida urgente (padrao: pasta pai do primeiro --dir-urgente / TABELA_URGENTES_CONSOLIDADA.csv)")
args = parser.parse_args()

if not args.dir and not args.dir_urgente:
    print("[ERRO] Informe ao menos --dir ou --dir-urgente.")
    sys.exit(1)


def consolidar(dirs, arquivo_fonte, out_path):
    frames = []
    for d in [Path(d).resolve() for d in dirs]:
        csv = d / arquivo_fonte
        if not csv.exists():
            print(f"[AVISO] Nao encontrado: {csv}")
            continue
        print(f"[INFO] Lendo: {csv}")
        df = pd.read_csv(csv, sep=SEP, dtype=str, low_memory=False)
        print(f"       {len(df):,} registros")
        frames.append(df)

    if not frames:
        print(f"[ERRO] Nenhum arquivo encontrado para {arquivo_fonte}.")
        return False

    base = pd.concat(frames, ignore_index=True)
    print(f"[INFO] Total: {len(base):,} registros")

    for col in COLUNAS_GROUP:
        if col not in base.columns:
            print(f"[AVISO] Coluna ausente: {col} — preenchendo com vazio")
            base[col] = ""
        base[col] = base[col].fillna("").str.strip()

    consolidada = (
        base.groupby(COLUNAS_GROUP, dropna=False)
        .size()
        .reset_index(name="Cont_sol")
        .sort_values("Cont_sol", ascending=False)
    )

    out_path.parent.mkdir(parents=True, exist_ok=True)
    consolidada.to_csv(out_path, sep=SEP, index=False, encoding=ENC)
    print(f"[OK] {len(consolidada):,} linhas -> {out_path}")
    return True


erros = 0

if args.dir:
    dirs_elet = args.dir
    out_elet = (
        Path(args.out) if args.out
        else Path(dirs_elet[0]).resolve().parent / "TABELA_ELETIVOS_CONSOLIDADA.csv"
    )
    if not consolidar(dirs_elet, "01_eletivo_linha_a_linha.csv", out_elet):
        erros += 1

if args.dir_urgente:
    dirs_urg = args.dir_urgente
    out_urg = (
        Path(args.out_urgente) if args.out_urgente
        else Path(dirs_urg[0]).resolve().parent / "TABELA_URGENTES_CONSOLIDADA.csv"
    )
    if not consolidar(dirs_urg, "01_urgente_linha_a_linha.csv", out_urg):
        erros += 1

sys.exit(1 if erros else 0)
