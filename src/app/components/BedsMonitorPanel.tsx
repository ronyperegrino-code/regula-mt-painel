import { useState, useCallback, useRef } from "react";
import { Upload, AlertTriangle, CheckCircle, Clock, BedDouble, Activity } from "lucide-react";
import { BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid, ResponsiveContainer, LineChart, Line, PieChart, Pie, Cell } from "recharts";
import { Fragment } from "react";
import { MatoGrossoMap, type RegionData } from "./MatoGrossoMap";

const DEFAULT_REGIONS: RegionData[] = [
  { regiao: "Sinop", municipio_sede: "Sinop", fila_total: 28, urgente: 8, tempo_resposta_min: 18, leitos_disponiveis: 45, taxa_atendimento: 88 },
  { regiao: "Barra do Garças", municipio_sede: "Barra do Garças", fila_total: 12, urgente: 2, tempo_resposta_min: 25, leitos_disponiveis: 28, taxa_atendimento: 92 },
  { regiao: "Cuiabá", municipio_sede: "Cuiabá", fila_total: 45, urgente: 12, tempo_resposta_min: 14, leitos_disponiveis: 89, taxa_atendimento: 91 },
  { regiao: "Cáceres", municipio_sede: "Cáceres", fila_total: 10, urgente: 2, tempo_resposta_min: 28, leitos_disponiveis: 22, taxa_atendimento: 85 },
  { regiao: "Rondonópolis", municipio_sede: "Rondonópolis", fila_total: 18, urgente: 5, tempo_resposta_min: 20, leitos_disponiveis: 38, taxa_atendimento: 90 },
];

type TrendRow = { data: string; entradas: number; saidas: number };

const DEFAULT_TREND: TrendRow[] = [
  { data: "1 Dia", entradas: 45, saidas: 38 },
  { data: "2 Dias", entradas: 52, saidas: 41 },
  { data: "3 Dias", entradas: 48, saidas: 45 },
  { data: "4 Dias", entradas: 61, saidas: 43 },
  { data: "5 Dias", entradas: 55, saidas: 50 },
  { data: "6 Dias", entradas: 49, saidas: 52 },
  { data: "7 Dias", entradas: 42, saidas: 48 },
];

const DEFAULT_ALERTS = [
  { tipo: "OFFLINE", hospital: "Hospital Regional — Cuiabá", prioridade: "critica" },
  { tipo: "ATRASO", hospital: "Sistema de Transferência — Sinop", prioridade: "alta" },
  { tipo: "VENTILADOR", hospital: "H. São Lucas — Rondonópolis", prioridade: "alta" },
  { tipo: "VENTILADOR", hospital: "H. São Lucas — Cáceres", prioridade: "media" },
];

const SPECIALTY_COLORS = ["#2a5aa8", "#36b85c", "#f59e0b", "#ef4444", "#a855f7"];

function parseRegions(text: string): RegionData[] {
  const lines = text.trim().split("\n");
  if (!lines[0].toLowerCase().includes("regiao")) return [];
  return lines.slice(1).map(line => {
    const c = line.split(",").map(s => s.trim());
    return {
      regiao: c[0] ?? "",
      municipio_sede: c[1] ?? c[0] ?? "",
      fila_total: Number(c[2]) || 0,
      urgente: Number(c[3]) || 0,
      tempo_resposta_min: Number(c[4]) || 0,
      leitos_disponiveis: Number(c[5]) || 0,
      taxa_atendimento: Number(c[6]) || 0,
    };
  });
}

function parseTrend(text: string): TrendRow[] {
  const lines = text.trim().split("\n");
  return lines.slice(1).map(line => {
    const c = line.split(",").map(s => s.trim());
    return { data: c[0] ?? "", entradas: Number(c[1]) || 0, saidas: Number(c[2]) || 0 };
  });
}

const CustomTooltip = ({ active, payload, label }: any) => {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-[#0d3350] border border-white/10 rounded p-2 text-xs">
      <div className="text-white/50 mb-1">{label}</div>
      {payload.map((p: any) => (
        <div key={p.name} className="flex items-center gap-2">
          <span className="w-2 h-2 rounded-full" style={{ backgroundColor: p.color || p.fill }} />
          <span className="text-white/60">{p.name}:</span>
          <span className="text-white font-mono font-semibold">{p.value}</span>
        </div>
      ))}
    </div>
  );
};

export function BedsMonitorPanel() {
  const [regions, setRegions] = useState<RegionData[]>(DEFAULT_REGIONS);
  const [trend, setTrend] = useState<TrendRow[]>(DEFAULT_TREND);
  const [selectedRegion, setSelectedRegion] = useState<string | null>(null);
  const regionRef = useRef<HTMLInputElement>(null);
  const trendRef = useRef<HTMLInputElement>(null);

  const totalFila = regions.reduce((s, r) => s + r.fila_total, 0);
  const totalUrgente = regions.reduce((s, r) => s + r.urgente, 0);
  const avgTempo = Math.round(regions.reduce((s, r) => s + r.tempo_resposta_min, 0) / regions.length);
  const totalLeitos = regions.reduce((s, r) => s + r.leitos_disponiveis, 0);
  const avgTaxa = Math.round(regions.reduce((s, r) => s + r.taxa_atendimento, 0) / regions.length);

  const sorted = [...regions].sort((a, b) => b.fila_total - a.fila_total);

  const specialtyData = [
    { name: "UTI", value: Math.round(totalFila * 0.33), color: SPECIALTY_COLORS[0] },
    { name: "Enfermaria", value: Math.round(totalFila * 0.45), color: SPECIALTY_COLORS[1] },
    { name: "Clínico", value: Math.round(totalFila * 0.12), color: SPECIALTY_COLORS[2] },
    { name: "Pediátrico", value: Math.round(totalFila * 0.10), color: SPECIALTY_COLORS[3] },
  ];

  async function handleRegionCSV(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    const text = await file.text();
    const parsed = parseRegions(text);
    if (parsed.length > 0) setRegions(parsed);
  }

  async function handleTrendCSV(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    const text = await file.text();
    const parsed = parseTrend(text);
    if (parsed.length > 0) setTrend(parsed);
  }

  function downloadRegionTemplate() {
    const content = "regiao,municipio_sede,fila_total,urgente,tempo_resposta_min,leitos_disponiveis,taxa_atendimento\n" +
      regions.map(r => `${r.regiao},${r.municipio_sede},${r.fila_total},${r.urgente},${r.tempo_resposta_min},${r.leitos_disponiveis},${r.taxa_atendimento}`).join("\n");
    const blob = new Blob(["﻿" + content], { type: "text/csv;charset=utf-8;" });
    const a = document.createElement("a"); a.href = URL.createObjectURL(blob); a.download = "regioes_leitos.csv"; a.click();
  }

  function downloadTrendTemplate() {
    const content = "data,entradas,saidas\n" + trend.map(t => `${t.data},${t.entradas},${t.saidas}`).join("\n");
    const blob = new Blob(["﻿" + content], { type: "text/csv;charset=utf-8;" });
    const a = document.createElement("a"); a.href = URL.createObjectURL(blob); a.download = "tendencia_leitos.csv"; a.click();
  }

  return (
    <div className="p-3">
      {/* Sub-header CSV controls */}
      <div className="flex items-center gap-2 mb-3 pb-2 border-b border-white/8">
        <span className="text-[10px] text-white/40">Dados:</span>
        <input ref={regionRef} type="file" accept=".csv" className="hidden" onChange={handleRegionCSV} />
        <input ref={trendRef} type="file" accept=".csv" className="hidden" onChange={handleTrendCSV} />
        <button onClick={() => regionRef.current?.click()} className="flex items-center gap-1 px-2 py-1 rounded text-[10px] border border-white/15 text-white/60 hover:text-white hover:border-green-500/50 hover:bg-green-500/10 transition-all">
          <Upload size={10} />regioes_leitos.csv
        </button>
        <button onClick={() => trendRef.current?.click()} className="flex items-center gap-1 px-2 py-1 rounded text-[10px] border border-white/15 text-white/60 hover:text-white hover:border-blue-500/50 hover:bg-blue-500/10 transition-all">
          <Upload size={10} />tendencia_leitos.csv
        </button>
        <button onClick={downloadRegionTemplate} className="flex items-center gap-1 px-2 py-1 rounded text-[10px] text-white/30 hover:text-green-400 transition-all">↓ modelo regiões</button>
        <button onClick={downloadTrendTemplate} className="flex items-center gap-1 px-2 py-1 rounded text-[10px] text-white/30 hover:text-blue-400 transition-all">↓ modelo tendência</button>
      </div>

      {/* KPI Row */}
      <div className="grid grid-cols-5 gap-2 mb-2">
        {[
          { icon: <Activity size={20} className="text-yellow-400" />, label: "Total em Fila", value: totalFila, color: "text-yellow-400", sub: "solicitações" },
          { icon: <AlertTriangle size={20} className="text-red-400" />, label: "Prioridade Urgente", value: totalUrgente, color: "text-red-400", sub: "vermelho" },
          { icon: <Clock size={20} className="text-blue-400" />, label: "Tempo Médio Resposta", value: `${avgTempo} min`, color: "text-blue-400", sub: "média geral" },
          { icon: <BedDouble size={20} className="text-green-400" />, label: "Leitos Disponíveis", value: totalLeitos, color: "text-green-400", sub: "em tempo real" },
          { icon: <CheckCircle size={20} className="text-emerald-400" />, label: "Taxa Atendimento", value: `${avgTaxa}%`, color: "text-emerald-400", sub: "últimas 24h" },
        ].map((k, i) => (
          <div key={i} className="bg-card border border-white/8 rounded p-3">
            <div className="text-[10px] uppercase tracking-widest text-white/50 mb-1">{k.label}</div>
            <div className="flex items-center gap-2 mt-1">
              {k.icon}
              <div>
                <div className={`text-2xl font-bold font-mono ${k.color}`}>{k.value}</div>
                <div className="text-[9px] text-white/40">{k.sub}</div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Main grid: Map + Queue Summary + Alerts */}
      <div className="grid gap-2 mb-2" style={{ gridTemplateColumns: "1.2fr 1fr 0.8fr" }}>

        {/* Map */}
        <MatoGrossoMap
          regions={regions}
          selected={selectedRegion}
          onSelectRegion={r => setSelectedRegion(r ? r.regiao : null)}
        />

        {/* Queue Summary */}
        <div className="bg-card border border-white/8 rounded p-3 flex flex-col gap-2">
          <div className="text-[10px] uppercase tracking-widest text-white/50">Resumo da Fila de Espera</div>

          {/* Fila por Regional */}
          <div>
            <div className="text-[9px] text-white/30 mb-1">Fila por Macrorregião</div>
            <ResponsiveContainer width="100%" height={120}>
              <BarChart data={sorted} margin={{ left: -20, right: 5, top: 0, bottom: 0 }}>
                <CartesianGrid key="cg" stroke="rgba(255,255,255,0.05)" horizontal={false} />
                <XAxis key="x" dataKey="regiao" tick={{ fill: "#8a9bb0", fontSize: 8 }} axisLine={false} tickLine={false} />
                <YAxis key="y" tick={{ fill: "#8a9bb0", fontSize: 8 }} axisLine={false} tickLine={false} />
                <Tooltip key="tt" content={<CustomTooltip />} cursor={{ fill: "rgba(255,255,255,0.04)" }} />
                <Bar key="b1" dataKey="fila_total" name="Fila Total" fill="#2a5aa8" radius={[2, 2, 0, 0]} />
                <Bar key="b2" dataKey="urgente" name="Urgente" fill="#ef4444" radius={[2, 2, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>

          {/* Fila por Especialidade */}
          <div>
            <div className="text-[9px] text-white/30 mb-1">Distribuição por Especialidade</div>
            <div className="flex items-center gap-2">
              <PieChart width={80} height={80}>
                <Pie data={specialtyData} cx="50%" cy="50%" innerRadius={22} outerRadius={36} dataKey="value" strokeWidth={0}>
                  {specialtyData.map((e, i) => <Cell key={i} fill={e.color} />)}
                </Pie>
              </PieChart>
              <div className="flex flex-col gap-1">
                {specialtyData.map((s, i) => (
                  <div key={i} className="flex items-center gap-1.5">
                    <span className="w-1.5 h-1.5 rounded-full shrink-0" style={{ backgroundColor: s.color }} />
                    <span className="text-[9px] text-white/60">{s.name}</span>
                    <span className="text-[9px] font-mono text-white/80 ml-auto">{s.value}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-2 gap-2 mt-auto">
            <div className="bg-white/5 rounded p-2 text-center">
              <div className="text-[9px] text-white/40">Distância Disponível</div>
              <div className="text-lg font-bold font-mono text-green-400">{avgTaxa}%</div>
            </div>
            <div className="bg-white/5 rounded p-2 text-center">
              <div className="text-[9px] text-white/40">Taxa de Atend.</div>
              <div className="text-lg font-bold font-mono text-green-400">{avgTaxa}%</div>
            </div>
          </div>
        </div>

        {/* Alerts + Blocked */}
        <div className="flex flex-col gap-2">
          <div className="bg-card border border-white/8 rounded p-3 flex-1">
            <div className="text-[10px] uppercase tracking-widest text-white/50 mb-2">Alertas Críticos</div>
            <div className="flex flex-col gap-1.5">
              {DEFAULT_ALERTS.map((a, i) => {
                const color = a.prioridade === "critica" ? "text-red-400 bg-red-500/10 border-red-500/20"
                  : a.prioridade === "alta" ? "text-orange-400 bg-orange-500/10 border-orange-500/20"
                  : "text-yellow-400 bg-yellow-500/10 border-yellow-500/20";
                return (
                  <div key={i} className={`border rounded p-1.5 ${color}`}>
                    <div className="text-[9px] font-semibold">{a.tipo}</div>
                    <div className="text-[8px] opacity-70 leading-tight">{a.hospital}</div>
                  </div>
                );
              })}
            </div>
          </div>

          <div className="bg-card border border-white/8 rounded p-3">
            <div className="text-[10px] uppercase tracking-widest text-white/50 mb-2">Leitos Bloqueados</div>
            <div className="flex flex-col gap-1">
              {[
                { motivo: "Manutenção — Cama C-10", qt: 3 },
                { motivo: "Manutenção — Cama C-12", qt: 2 },
                { motivo: "Isolamento — Cama C-8", qt: 1 },
              ].map((l, i) => (
                <div key={i} className="flex items-center justify-between text-[9px]">
                  <span className="text-white/60">{l.motivo}</span>
                  <span className="font-mono text-red-400 font-semibold">{l.qt}</span>
                </div>
              ))}
              <div className="border-t border-white/10 mt-1 pt-1 flex justify-between text-[9px]">
                <span className="text-white/40">Total bloqueados</span>
                <span className="font-mono text-red-400 font-bold">6</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom row */}
      <div className="grid gap-2" style={{ gridTemplateColumns: "1fr 1.2fr" }}>

        {/* Top 5 hospitals */}
        <div className="bg-card border border-white/8 rounded p-3">
          <div className="text-[10px] uppercase tracking-widest text-white/50 mb-0.5">Top 5 Hospitais — Maior Fila de Espera</div>
          <div className="text-[9px] text-white/30 mb-2">Unidades com maior volume de solicitações pendentes</div>
          <div className="flex flex-col gap-0">
            <div className="grid grid-cols-[auto_1fr_auto_auto] gap-x-3 pb-1 border-b border-white/8">
              <span className="text-[9px] text-white/30">#</span>
              <span className="text-[9px] text-white/30">Hospital / Unidade</span>
              <span className="text-[9px] text-white/30 text-right">Fila</span>
              <span className="text-[9px] text-white/30 text-right">Urgente</span>
            </div>
            {sorted.slice(0, 5).map((r, i) => {
              const urgColor = r.urgente >= 10 ? "text-red-400" : r.urgente >= 5 ? "text-orange-400" : "text-yellow-400";
              return (
                <Fragment key={i}>
                  <div className="grid grid-cols-[auto_1fr_auto_auto] gap-x-3 py-1.5 border-b border-white/5 items-center">
                    <span className="text-[10px] font-mono text-white/40 w-4">{i + 1}</span>
                    <span className="text-[10px] text-white/70">{r.regiao} — {r.municipio_sede}</span>
                    <span className="text-[10px] font-mono text-white font-semibold text-right">{r.fila_total}</span>
                    <span className={`text-[10px] font-mono font-semibold text-right ${urgColor}`}>{r.urgente}</span>
                  </div>
                </Fragment>
              );
            })}
          </div>
        </div>

        {/* Trend chart */}
        <div className="bg-card border border-white/8 rounded p-3">
          <div className="text-[10px] uppercase tracking-widest text-white/50 mb-0.5">Tendência de Entrada vs. Saída da Fila (7 Dias)</div>
          <div className="flex gap-4 mb-2">
            <span className="flex items-center gap-1 text-[9px] text-white/50">
              <span className="w-4 h-0.5 inline-block rounded" style={{ backgroundColor: "#ef4444" }} /> Novas Solicitações
            </span>
            <span className="flex items-center gap-1 text-[9px] text-white/50">
              <span className="w-4 h-0.5 inline-block rounded" style={{ backgroundColor: "#36b85c" }} /> Vagas Atribuídas
            </span>
          </div>
          <ResponsiveContainer width="100%" height={160}>
            <LineChart data={trend} margin={{ left: -10, right: 10, top: 5, bottom: 0 }}>
              <CartesianGrid key="cg" stroke="rgba(255,255,255,0.05)" vertical={false} />
              <XAxis key="x" dataKey="data" tick={{ fill: "#8a9bb0", fontSize: 9 }} axisLine={false} tickLine={false} />
              <YAxis key="y" tick={{ fill: "#8a9bb0", fontSize: 9 }} axisLine={false} tickLine={false} />
              <Tooltip key="tt" content={<CustomTooltip />} />
              <Line key="l1" type="monotone" dataKey="entradas" name="Novas Solicitações" stroke="#ef4444" strokeWidth={2} dot={{ r: 3, fill: "#ef4444" }} />
              <Line key="l2" type="monotone" dataKey="saidas" name="Vagas Atribuídas" stroke="#36b85c" strokeWidth={2} dot={{ r: 3, fill: "#36b85c" }} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
