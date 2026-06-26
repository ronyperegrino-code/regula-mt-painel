import { useState, useEffect, useCallback } from "react";
import { RefreshCw, Filter, Calendar, LayoutDashboard, Map } from "lucide-react";
import { BedsMonitorPanel } from "./components/BedsMonitorPanel";
import type { HospitalRow, DayRow } from "./components/CSVUpload";
import { KPICards } from "./components/KPICards";
import { AprovadosPorHospital, UTIEnfermariaChart } from "./components/HospitalCharts";
import { ResponseTimeTable } from "./components/ResponseTimeTable";
import { ApprovalRateTable } from "./components/ApprovalRateTable";
import { EvolutionChart } from "./components/EvolutionChart";
import { DistributionDonut } from "./components/DistributionDonut";

function parseHospitalsCSV(text: string): HospitalRow[] {
  const lines = text.replace(/^﻿/, "").trim().split("\n");
  if (lines.length < 2) return [];
  return lines.slice(1).map((line) => {
    const cols = line.split(",").map((c) => c.trim());
    return {
      hospital: cols[0] ?? "",
      solicitacoes: Number(cols[1]) || 0,
      aprovacoes: Number(cols[2]) || 0,
      uti: Number(cols[3]) || 0,
      enfermaria: Number(cols[4]) || 0,
      tempo_medio: cols[5] ?? "- d",
      mediana: cols[6] ?? "- d",
      pct_atendidas: Number((cols[7] ?? "0").replace("%", "")) || 0,
    };
  }).filter((h) => h.hospital.length > 0);
}

function parseEvolutionCSV(text: string): DayRow[] {
  const lines = text.replace(/^﻿/, "").trim().split("\n");
  if (lines.length < 2) return [];
  return lines.slice(1).map((line) => {
    const cols = line.split(",").map((c) => c.trim());
    return {
      data: cols[0] ?? "",
      solicitacoes: Number(cols[1]) || 0,
      aprovacoes: Number(cols[2]) || 0,
      pendentes: Number(cols[3]) || 0,
    };
  }).filter((r) => r.data.length > 0);
}

export default function App() {
  const [hospitals, setHospitals] = useState<HospitalRow[]>([]);
  const [evolution, setEvolution] = useState<DayRow[]>([]);
  const [lastUpdated, setLastUpdated] = useState(new Date());
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<"panorama" | "leitos">("panorama");

  const carregarDados = useCallback(async () => {
    setLoading(true);
    try {
      const [rH, rE] = await Promise.all([
        fetch("/hospitais.csv?t=" + Date.now()),
        fetch("/evolucao.csv?t=" + Date.now()),
      ]);
      if (rH.ok) {
        const parsed = parseHospitalsCSV(await rH.text());
        if (parsed.length > 0) setHospitals(parsed);
      }
      if (rE.ok) {
        const parsed = parseEvolutionCSV(await rE.text());
        if (parsed.length > 0) setEvolution(parsed);
      }
      setLastUpdated(new Date());
    } catch {
      // arquivos não disponíveis — mantém estado atual
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { carregarDados(); }, [carregarDados]);

  const total     = hospitals.reduce((s, h) => s + h.solicitacoes, 0);
  const aprovados = hospitals.reduce((s, h) => s + h.aprovacoes, 0);
  const totalUTI  = hospitals.reduce((s, h) => s + h.uti, 0);
  const totalEnf  = hospitals.reduce((s, h) => s + h.enfermaria, 0);

  const totalPend = Math.max(0, total - aprovados);
  const pendentes = {
    uti:            aprovados > 0 ? Math.round(totalPend * (totalUTI / aprovados)) : 0,
    enfermaria:     aprovados > 0 ? Math.round(totalPend * (totalEnf / aprovados)) : 0,
    hemodinamica:   0,
    transInterHosp: 0,
    outros:         0,
  };
  pendentes.outros = Math.max(0, totalPend - pendentes.uti - pendentes.enfermaria);
  const totalPendentes = totalPend;

  const fmt = (d: Date) =>
    d.toLocaleString("pt-BR", { day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit" });

  return (
    <div className="min-h-screen bg-background text-foreground" style={{ fontFamily: "'Inter', system-ui, sans-serif", fontSize: "13px" }}>
      {/* Header */}
      <header className="border-b border-white/10 bg-[#061828] sticky top-0 z-10">
        <div className="px-4 py-2 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="flex flex-col">
              <span className="font-bold tracking-wider text-sm">
                <span style={{ color: "#dce7f7" }}>REGULA</span>
                <span style={{ color: "#36b85c" }}>MT</span>
              </span>
              <span className="text-[9px] text-white/40 uppercase tracking-widest">Sala Central de Regulação</span>
            </div>
            <div className="w-px h-8 bg-white/10" />
            {/* Tabs */}
            <div className="flex items-center gap-1">
              <button
                onClick={() => setActiveTab("panorama")}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded text-xs transition-all ${activeTab === "panorama" ? "bg-white/10 text-white font-semibold" : "text-white/50 hover:text-white/80"}`}
              >
                <LayoutDashboard size={12} />Panorama Geral
              </button>
              <button
                onClick={() => setActiveTab("leitos")}
                className={`flex items-center gap-1.5 px-3 py-1.5 rounded text-xs transition-all ${activeTab === "leitos" ? "bg-white/10 text-white font-semibold" : "text-white/50 hover:text-white/80"}`}
              >
                <Map size={12} />Monitoramento de Leitos
              </button>
            </div>
            <div className="w-px h-8 bg-white/10" />
            <div>
              <div className="text-sm font-semibold text-white">
                {activeTab === "panorama" ? "Panorama Geral" : "Monitoramento de Leitos"}
              </div>
              <div className="text-[9px] text-white/40 flex items-center gap-1">
                {loading ? "Carregando..." : `Atualizado em ${fmt(lastUpdated)}`}
                <RefreshCw size={9} className={loading ? "text-green-400 animate-spin" : "text-white/30"} />
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={carregarDados}
              disabled={loading}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded border border-white/10 text-xs text-white/70 hover:bg-white/5 hover:text-white transition-all disabled:opacity-40"
            >
              <RefreshCw size={11} className={loading ? "animate-spin" : ""} />
              Recarregar
            </button>

            <div className="w-px h-5 bg-white/10" />

            <button className="flex items-center gap-1.5 px-3 py-1.5 rounded border border-white/10 text-xs text-white/70 hover:bg-white/5 transition-all">
              <Filter size={11} />
              Filtros
            </button>
            <button className="flex items-center gap-1.5 px-3 py-1.5 rounded border border-white/10 text-xs text-white/70 hover:bg-white/5 transition-all">
              <Calendar size={11} />
              {evolution.length > 0 ? evolution[evolution.length - 1].data : "--/--"}
            </button>
            <span className="text-[10px] text-white/30 border border-white/10 rounded px-2 py-1.5">
              {hospitals.length} hospitais
            </span>
          </div>
        </div>
      </header>

      {/* Dashboard Body */}
      <main>
        {loading && hospitals.length === 0 ? (
          <div className="flex items-center justify-center h-64 text-white/40 text-sm">
            Carregando dados...
          </div>
        ) : hospitals.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-64 gap-2 text-white/40 text-sm">
            <span>Nenhum dado disponível.</span>
            <span className="text-[11px]">Execute <code className="bg-white/10 px-1 rounded">gerar_dados_painel.py</code> para gerar os arquivos CSV.</span>
          </div>
        ) : activeTab === "panorama" ? (
          <div className="p-3">
            <KPICards
              total={total}
              pendentes={totalPendentes}
              aprovados={aprovados}
              uti={pendentes.uti}
              enfermaria={pendentes.enfermaria}
              hemodinamica={pendentes.hemodinamica}
              transInterHosp={pendentes.transInterHosp}
              outros={pendentes.outros}
            />
            {/* Linha 2 — Gráficos de barra (2 colunas iguais) */}
            <div className="grid gap-2 mb-2" style={{ gridTemplateColumns: "1fr 1fr" }}>
              <AprovadosPorHospital hospitals={hospitals} />
              <UTIEnfermariaChart hospitals={hospitals} />
            </div>
            {/* Linha 3 — Componentes menores (3 colunas) */}
            <div className="grid gap-2" style={{ gridTemplateColumns: "1fr 1fr 1fr" }}>
              <ApprovalRateTable hospitals={hospitals} />
              <EvolutionChart data={evolution} />
              <div className="flex flex-col gap-2">
                <DistributionDonut
                  uti={totalUTI}
                  enfermaria={totalEnf}
                  transInterHosp={pendentes.transInterHosp}
                  hemodinamica={pendentes.hemodinamica}
                  outros={pendentes.outros}
                  total={total}
                />
                <ResponseTimeTable hospitals={hospitals} />
              </div>
            </div>
          </div>
        ) : (
          <BedsMonitorPanel />
        )}
      </main>

      <footer className="px-4 py-2 border-t border-white/5 flex items-center gap-1.5">
        <div className="w-1.5 h-1.5 rounded-full animate-pulse" style={{ backgroundColor: "#36b85c" }} />
        <span className="text-[9px] text-white/30">Dados do Sistema Estadual de Regulação — Regula MT · SES-MT</span>
      </footer>
    </div>
  );
}
