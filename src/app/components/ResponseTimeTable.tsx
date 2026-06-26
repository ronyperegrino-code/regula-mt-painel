import { Fragment } from "react";
import type { HospitalRow } from "./CSVUpload";

interface Props {
  hospitals: HospitalRow[];
}

function PctBar({ value }: { value: number }) {
  const color = value >= 85 ? "#36b85c" : value >= 70 ? "#f59e0b" : "#ef4444";
  return (
    <div className="flex items-center gap-2">
      <div className="flex-1 h-1.5 bg-white/10 rounded-full overflow-hidden">
        <div className="h-full rounded-full transition-all" style={{ width: `${value}%`, backgroundColor: color }} />
      </div>
      <span className="font-mono text-[10px] w-7 text-right" style={{ color }}>{value}%</span>
    </div>
  );
}

export function ResponseTimeTable({ hospitals }: Props) {
  const sorted = [...hospitals].sort((a, b) => a.pct_atendidas > b.pct_atendidas ? -1 : 1);

  return (
    <div className="bg-card border border-white/8 rounded p-3 h-full">
      <div className="text-[10px] uppercase tracking-widest text-white/50 mb-0.5">Tempo de Resposta das Unidades Hospitalares</div>
      <div className="text-[9px] text-white/30 mb-2">Tempo médio entre envio da busca de vaga e resposta (h/mm)</div>
      <div className="overflow-y-auto max-h-[280px]">
      <div className="grid grid-cols-[1fr_auto_auto_auto] gap-x-3 gap-y-0">
        <div className="text-[9px] text-white/30 pb-1 border-b border-white/8">Unidade Hospitalar</div>
        <div className="text-[9px] text-white/30 pb-1 border-b border-white/8 text-center">Médio</div>
        <div className="text-[9px] text-white/30 pb-1 border-b border-white/8 text-center">Mediana</div>
        <div className="text-[9px] text-white/30 pb-1 border-b border-white/8 text-center">% Atend.</div>
        {sorted.map((h, i) => (
          <Fragment key={i}>
            <div className="text-[10px] text-white/70 py-1.5 border-b border-white/5">{h.hospital}</div>
            <div className="text-[10px] font-mono text-white/60 py-1.5 border-b border-white/5 text-center">{h.tempo_medio}</div>
            <div className="text-[10px] font-mono text-white/60 py-1.5 border-b border-white/5 text-center">{h.mediana}</div>
            <div className="py-1.5 border-b border-white/5 min-w-[80px]">
              <PctBar value={h.pct_atendidas} />
            </div>
          </Fragment>
        ))}
      </div>
      </div>
    </div>
  );
}
