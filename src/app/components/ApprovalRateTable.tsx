import { Fragment } from "react";
import type { HospitalRow } from "./CSVUpload";

interface Props { hospitals: HospitalRow[]; }

function RateBadge({ value }: { value: number }) {
  const color = value >= 70 ? "bg-emerald-700/30 text-emerald-300" : value >= 55 ? "bg-yellow-500/20 text-yellow-400" : "bg-red-500/20 text-red-400";
  return <span className={`inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-mono font-semibold ${color}`}>{value.toFixed(1).replace(".", ",")}%</span>;
}

export function ApprovalRateTable({ hospitals }: Props) {
  const sorted = [...hospitals].sort((a, b) => b.aprovacoes - a.aprovacoes);
  const total = { hospital: "TOTAL", solicitacoes: hospitals.reduce((s, h) => s + h.solicitacoes, 0), aprovacoes: hospitals.reduce((s, h) => s + h.aprovacoes, 0), taxa: 0 };
  total.taxa = total.solicitacoes > 0 ? (total.aprovacoes / total.solicitacoes) * 100 : 0;

  return (
    <div className="bg-card border border-white/8 rounded p-3 h-full">
      <div className="text-[10px] uppercase tracking-widest text-white/50 mb-0.5">Taxa de Aprovação por Unidade Hospitalar</div>
      <div className="text-[9px] text-white/30 mb-2">% de aprovações sobre o total de solicitações</div>
      <div className="grid grid-cols-[1fr_auto_auto_auto] gap-x-4 gap-y-0">
        <div className="text-[9px] text-white/30 pb-1 border-b border-white/8">Unidade Hospitalar</div>
        <div className="text-[9px] text-white/30 pb-1 border-b border-white/8 text-right">Solicitações</div>
        <div className="text-[9px] text-white/30 pb-1 border-b border-white/8 text-right">Aprovações</div>
        <div className="text-[9px] text-white/30 pb-1 border-b border-white/8 text-center">Taxa</div>
        {sorted.map((h, i) => {
          const taxa = h.solicitacoes > 0 ? (h.aprovacoes / h.solicitacoes) * 100 : 0;
          return (
            <Fragment key={i}>
              <div className="text-[10px] text-white/70 py-1.5 border-b border-white/5">{h.hospital}</div>
              <div className="text-[10px] font-mono text-white/60 py-1.5 border-b border-white/5 text-right">{h.solicitacoes}</div>
              <div className="text-[10px] font-mono text-white/60 py-1.5 border-b border-white/5 text-right">{h.aprovacoes}</div>
              <div className="py-1.5 border-b border-white/5 text-center"><RateBadge value={taxa} /></div>
            </Fragment>
          );
        })}
        <div className="text-[10px] font-semibold text-white py-1.5 border-t border-white/15 mt-1">{total.hospital}</div>
        <div className="text-[10px] font-mono font-semibold text-white py-1.5 border-t border-white/15 text-right mt-1">{total.solicitacoes}</div>
        <div className="text-[10px] font-mono font-semibold text-white py-1.5 border-t border-white/15 text-right mt-1">{total.aprovacoes}</div>
        <div className="py-1.5 border-t border-white/15 text-center mt-1"><RateBadge value={total.taxa} /></div>
      </div>
    </div>
  );
}
