import { LineChart, Line, XAxis, YAxis, Tooltip, CartesianGrid, ResponsiveContainer, Legend } from "recharts";
import type { DayRow } from "./CSVUpload";

interface Props {
  data: DayRow[];
}

const CustomTooltip = ({ active, payload, label }: any) => {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-[#0d3350] border border-white/10 rounded p-2 text-xs">
      <div className="text-white/50 mb-1">{label}</div>
      {payload.map((p: any) => (
        <div key={p.name} className="flex items-center gap-2">
          <span className="w-2 h-2 rounded-full" style={{ backgroundColor: p.color }} />
          <span className="text-white/60">{p.name}:</span>
          <span className="text-white font-mono font-semibold">{p.value}</span>
        </div>
      ))}
    </div>
  );
};

export function EvolutionChart({ data }: Props) {
  return (
    <div className="bg-card border border-white/8 rounded p-3 h-full">
      <div className="text-[10px] uppercase tracking-widest text-white/50 mb-0.5">Evolução das Solicitações (Últimos {data.length} dias)</div>
      <div className="flex gap-4 mb-2">
        <span className="flex items-center gap-1 text-[9px] text-white/50">
          <span className="w-4 h-0.5 inline-block rounded" style={{ backgroundColor: "#36b85c" }} /> Solicitações
        </span>
        <span className="flex items-center gap-1 text-[9px] text-white/50">
          <span className="w-4 h-0.5 inline-block rounded" style={{ backgroundColor: "#2a5aa8" }} /> Aprovações
        </span>
        <span className="flex items-center gap-1 text-[9px] text-white/50">
          <span className="w-4 h-0.5 bg-yellow-400 inline-block rounded" /> Pendentes
        </span>
      </div>
      <ResponsiveContainer width="100%" height={190}>
        <LineChart data={data} margin={{ left: -10, right: 10, top: 5, bottom: 0 }}>
          <CartesianGrid key="cg" stroke="rgba(255,255,255,0.05)" vertical={false} />
          <XAxis key="xaxis" dataKey="data" tick={{ fill: "#8a9bb0", fontSize: 9 }} axisLine={false} tickLine={false} />
          <YAxis key="yaxis" tick={{ fill: "#8a9bb0", fontSize: 9 }} axisLine={false} tickLine={false} />
          <Tooltip key="tooltip" content={<CustomTooltip />} />
          <Line key="line-sol" type="monotone" dataKey="solicitacoes" name="Solicitações" stroke="#36b85c" strokeWidth={2} dot={{ r: 3, fill: "#36b85c" }} />
          <Line key="line-aprov" type="monotone" dataKey="aprovacoes" name="Aprovações" stroke="#2a5aa8" strokeWidth={2} dot={{ r: 3, fill: "#2a5aa8" }} />
          <Line key="line-pend" type="monotone" dataKey="pendentes" name="Pendentes" stroke="#f59e0b" strokeWidth={2} dot={{ r: 3, fill: "#f59e0b" }} />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
