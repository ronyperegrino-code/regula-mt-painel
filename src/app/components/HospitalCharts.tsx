import { BarChart, Bar, XAxis, YAxis, Cell, ResponsiveContainer, Tooltip, CartesianGrid } from "recharts";
import type { HospitalRow } from "./CSVUpload";

interface Props {
  hospitals: HospitalRow[];
}

const COLORS_BAR = ["#36b85c", "#2a9e4f", "#1e8441", "#2a5aa8", "#1d4a8c", "#3b7dd8", "#5b9de8", "#7ab8f5"];

const CustomTooltip = ({ active, payload, label }: any) => {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-[#0d3350] border border-white/10 rounded p-2 text-xs">
      <div className="text-white/70 mb-1">{label}</div>
      {payload.map((p: any) => (
        <div key={p.name} className="flex gap-2">
          <span style={{ color: p.fill || p.color }}>{p.name}:</span>
          <span className="text-white font-mono">{p.value}</span>
        </div>
      ))}
    </div>
  );
};

export function AprovadosPorHospital({ hospitals }: Props) {
  const data = [...hospitals]
    .sort((a, b) => b.aprovacoes - a.aprovacoes)
    .map((h) => ({
      hospital: h.hospital.replace("Hospital ", "").replace("HOSPITAL ", ""),
      aprovacoes: h.aprovacoes,
    }));

  return (
    <div className="bg-card border border-white/8 rounded p-3 h-full">
      <div className="text-[10px] uppercase tracking-widest text-white/50 mb-0.5">Aprovados por Unidade Hospitalar</div>
      <div className="text-[9px] text-white/30 mb-2">Total de aprovações no período</div>
      <ResponsiveContainer width="100%" height={420}>
        <BarChart data={data} layout="vertical" margin={{ left: 0, right: 40, top: 0, bottom: 0 }}>
          <CartesianGrid key="cg" horizontal={false} stroke="rgba(255,255,255,0.05)" />
          <XAxis key="xaxis" type="number" tick={{ fill: "#8a9bb0", fontSize: 9 }} axisLine={false} tickLine={false} />
          <YAxis
            key="yaxis"
            type="category"
            dataKey="hospital"
            tick={{ fill: "#8a9bb0", fontSize: 9 }}
            width={150}
            axisLine={false}
            tickLine={false}
          />
          <Tooltip key="tooltip" content={<CustomTooltip />} cursor={{ fill: "rgba(255,255,255,0.04)" }} />
          <Bar key="bar" dataKey="aprovacoes" radius={[0, 2, 2, 0]} label={{ position: "right", fill: "#8a9bb0", fontSize: 9 }}>
            {data.map((entry, i) => (
              <Cell key={`aprov-${entry.hospital}`} fill={COLORS_BAR[i % COLORS_BAR.length]} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}

export function UTIEnfermariaChart({ hospitals }: Props) {
  const data = [...hospitals]
    .sort((a, b) => b.aprovacoes - a.aprovacoes)
    .map((h) => ({
      hospital: h.hospital.replace("Hospital ", "").replace("HOSPITAL ", ""),
      UTI: h.uti,
      Enfermaria: h.enfermaria,
      total: h.aprovacoes,
    }));

  return (
    <div className="bg-card border border-white/8 rounded p-3 h-full">
      <div className="text-[10px] uppercase tracking-widest text-white/50 mb-0.5">Aprovações de UTI e Enfermaria por Hospital</div>
      <div className="flex gap-3 mb-2">
        <span className="flex items-center gap-1 text-[9px] text-white/50">
          <span className="w-2 h-2 rounded-sm inline-block" style={{ backgroundColor: "#2a5aa8" }} /> UTI
        </span>
        <span className="flex items-center gap-1 text-[9px] text-white/50">
          <span className="w-2 h-2 rounded-sm inline-block" style={{ backgroundColor: "#36b85c" }} /> Enfermaria
        </span>
      </div>
      <ResponsiveContainer width="100%" height={420}>
        <BarChart data={data} layout="vertical" margin={{ left: 0, right: 40, top: 0, bottom: 0 }}>
          <CartesianGrid key="cg" horizontal={false} stroke="rgba(255,255,255,0.05)" />
          <XAxis key="xaxis" type="number" tick={{ fill: "#8a9bb0", fontSize: 9 }} axisLine={false} tickLine={false} />
          <YAxis
            key="yaxis"
            type="category"
            dataKey="hospital"
            tick={{ fill: "#8a9bb0", fontSize: 9 }}
            width={150}
            axisLine={false}
            tickLine={false}
          />
          <Tooltip key="tooltip" content={<CustomTooltip />} cursor={{ fill: "rgba(255,255,255,0.04)" }} />
          <Bar key="bar-uti" dataKey="UTI" name="bar-uti" stackId="a" fill="#2a5aa8" radius={[0, 0, 0, 0]} />
          <Bar key="bar-enf" dataKey="Enfermaria" name="bar-enf" stackId="a" fill="#36b85c" radius={[0, 2, 2, 0]}
            label={{ position: "right", fill: "#8a9bb0", fontSize: 9, formatter: (_: any, entry: any) => entry?.total }}
          />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
}
