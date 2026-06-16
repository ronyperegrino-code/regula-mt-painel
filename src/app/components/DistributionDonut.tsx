import { PieChart, Pie, Cell, Tooltip } from "recharts";

interface Props { uti: number; enfermaria: number; transInterHosp: number; hemodinamica: number; outros: number; total: number; }

const COLORS = ["#2a5aa8", "#36b85c", "#f59e0b", "#ef4444", "#7a4fc8"];

const CustomTooltip = ({ active, payload }: any) => {
  if (!active || !payload?.length) return null;
  const d = payload[0];
  return (
    <div className="bg-[#0d3350] border border-white/10 rounded p-2 text-xs">
      <div className="flex items-center gap-2">
        <span className="w-2 h-2 rounded-full" style={{ backgroundColor: d.payload.color }} />
        <span className="text-white/70">{d.name}:</span>
        <span className="text-white font-mono">{d.value.toLocaleString("pt-BR")}</span>
      </div>
    </div>
  );
};

export function DistributionDonut({ uti, enfermaria, transInterHosp, hemodinamica, outros, total }: Props) {
  const data = [
    { name: "UTI", value: uti, color: COLORS[0] },
    { name: "Enfermaria", value: enfermaria, color: COLORS[1] },
    { name: "Transferência Inter-Hospitalar", value: transInterHosp, color: COLORS[2] },
    { name: "Hemodinâmica", value: hemodinamica, color: COLORS[3] },
    { name: "Outros", value: outros, color: COLORS[4] },
  ].filter(d => d.value > 0);

  return (
    <div className="bg-card border border-white/8 rounded p-3 h-full">
      <div className="text-[10px] uppercase tracking-widest text-white/50 mb-0.5">Distribuição das Solicitações por Tipo</div>
      <div className="text-[9px] text-white/30 mb-2">Total no período</div>
      <div className="flex items-center gap-2">
        <div className="relative shrink-0" style={{ width: 144, height: 144 }}>
          <PieChart width={144} height={144}>
            <Pie data={data} cx="50%" cy="50%" innerRadius={40} outerRadius={60} startAngle={90} endAngle={-270} dataKey="value" strokeWidth={0}>
              {data.map((entry, i) => <Cell key={i} fill={entry.color} />)}
            </Pie>
            <Tooltip content={<CustomTooltip />} />
          </PieChart>
          <div className="absolute inset-0 flex flex-col items-center justify-center">
            <span className="text-lg font-bold text-white font-mono">{total.toLocaleString("pt-BR")}</span>
            <span className="text-[9px] text-white/40">TOTAL</span>
          </div>
        </div>
        <div className="flex flex-col gap-1.5 flex-1">
          {data.map((item, i) => {
            const pct = total > 0 ? ((item.value / total) * 100).toFixed(1) : "0.0";
            return (
              <div key={i} className="flex items-center gap-2">
                <span className="w-2 h-2 rounded-full shrink-0" style={{ backgroundColor: item.color }} />
                <span className="text-[10px] text-white/60 flex-1 leading-tight">{item.name}</span>
                <span className="text-[10px] font-mono text-white/80 shrink-0">{item.value.toLocaleString("pt-BR")} <span className="text-white/40">({pct}%)</span></span>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
