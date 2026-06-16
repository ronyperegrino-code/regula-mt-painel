import { useState, useCallback } from "react";
import { RefreshCw, Filter, Calendar, FileText } from "lucide-react";
import { CSVUpload, type CSVData, type HospitalRow, type DayRow } from "./components/CSVUpload";
import { KPICards } from "./components/KPICards";
import { AprovadosPorHospital, UTIEnfermariaChart } from "./components/HospitalCharts";
import { ResponseTimeTable } from "./components/ResponseTimeTable";
import { ApprovalRateTable } from "./components/ApprovalRateTable";
import { EvolutionChart } from "./components/EvolutionChart";
import { DistributionDonut } from "./components/DistributionDonut";

const DEFAULT_HOSPITALS: HospitalRow[] = [
  { hospital: "H. Metropolitano de Cuiabá", solicitacoes: 512, aprovacoes: 312, uti: 192, enfermaria: 120, tempo_medio: "00:18", mediana: "00:12", pct_atendidas: 92 },
  { hospital: "H. Regional de Rondonópolis", solicitacoes: 318, aprovacoes: 198, uti: 98, enfermaria: 100, tempo_medio: "00:24", mediana: "00:15", pct_atendidas: 88 },
  { hospital: "Santa Casa de Cuiabá", solicitacoes: 292, aprovacoes: 176, uti: 102, enfermaria: 74, tempo_medio: "00:23", mediana: "00:15", pct_atendidas: 84 },
  { hospital: "H. Regional de Sinop", solicitacoes: 214, aprovacoes: 142, uti: 70, enfermaria: 72, tempo_medio: "00:31", mediana: "00:20", pct_atendidas: 78 },
  { hospital: "H. Regional de Cáceres", solicitacoes: 165, aprovacoes: 118, uti: 49, enfermaria: 69, tempo_medio: "00:35", mediana: "00:23", pct_atendidas: 73 },
  { hospital: "H. Regional de Barra do Garças", solicitacoes: 142, aprovacoes: 97, uti: 38, enfermaria: 59, tempo_medio: "00:42", mediana: "00:28", pct_atendidas: 65 },
  { hospital: "H. Regional de Sorriso", solicitacoes: 123, aprovacoes: 82, uti: 27, enfermaria: 55, tempo_medio: "00:48", mediana: "00:32", pct_atendidas: 57 },
  { hospital: "Outras Unidades", solicitacoes: 579, aprovacoes: 328, uti: 164, enfermaria: 164, tempo_medio: "00:29", mediana: "00:19", pct_atendidas: 81 },
];

const DEFAULT_EVOLUTION: DayRow[] = [
  { data: "08/06", solicitacoes: 312, aprovacoes: 215, pendentes: 118 },
  { data: "09/06", solicitacoes: 348, aprovacoes: 228, pendentes: 133 },
  { data: "10/06", solicitacoes: 352, aprovacoes: 247, pendentes: 124 },
  { data: "11/06", solicitacoes: 401, aprovacoes: 263, pendentes: 154 },
  { data: "12/06", solicitacoes: 392, aprovacoes: 245, pendentes: 129 },
  { data: "13/06", solicitacoes: 374, aprovacoes: 231, pendentes: 129 },
  { data: "14/06", solicitacoes: 356, aprovacoes: 261, pendentes: 96 },
];

const DEFAULT_PENDENTES = { uti: 128, enfermaria: 214, hemodinamica: 23, transInterHosp: 45, outros: 16 };

export default function App() {
  const [hospitals, setHospitals] = useState<HospitalRow[]>(DEFAULT_HOSPITALS);
  const [evolution, setEvolution] = useState<DayRow[]>(DEFAULT_EVOLUTION);
  const [pendentes] = useState(DEFAULT_PENDENTES);
  const [lastUpdated, setLastUpdated] = useState(new Date());
  const [showCSVGuide, setShowCSVGuide] = useState(false);
  const [hasCustomData, setHasCustomData] = useState(false);

  const handleData = useCallback((data: CSVData) => {
    if (data.hospitals.length > 0) { setHospitals(data.hospitals); setHasCustomData(true); }
    if (data.evolution.length > 0) { setEvolution(data.evolution); setHasCustomData(true); }
    setLastUpdated(new Date());
  }, []);

  const handleReset = () => {
    setHospitals(DEFAULT_HOSPITALS);
    setEvolution(DEFAULT_EVOLUTION);
    setHasCustomData(false);
    setLastUpdated(new Date());
  };

  const total = hospitals.reduce((s, h) => s + h.solicitacoes, 0);
  const aprovados = hospitals.reduce((s, h) => s + h.aprovacoes, 0);
  const totalPendentes = pendentes.uti + pendentes.enfermaria + pendentes.hemodinamica + pendentes.transInterHosp + pendentes.outros;
  const fmt = (d: Date) => d.toLocaleString("pt-BR", { day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit" });

  return (
    <div className="min-h-screen bg-background text-foreground" style={{ fontFamily: "'Inter', system-ui, sans-serif", fontSize: "13px" }}>
      <header className="border-b border-white/10 bg-[#061828] sticky top-0 z-10">
        <div className="px-4 py-2 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="flex flex-col">
              <span className="font-bold tracking-wider text-sm">
                <span style={{ color: "#dce7f7" }}>REGULA</span><span style={{ color: "#36b85c" }}>MT</span>
              </span>
              <span className="text-[9px] text-white/40 uppercase tracking-widest">Sala Central de Regulação</span>
            </div>
            <div className="w-px h-8 bg-white/10" />
            <div>
              <div className="text-sm font-semibold text-white">Panorama Geral</div>
              <div className="text-[9px] text-white/40 flex items-center gap-1">
                Atualizado em {fmt(lastUpdated)}<RefreshCw size={9} className="text-white/30" />
              </div>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <CSVUpload onData={handleData} hasData={hasCustomData} onReset={handleReset} />
            <button onClick={() => setShowCSVGuide(!showCSVGuide)} className="flex items-center gap-1 px-2 py-1.5 rounded text-[10px] text-white/40 hover:text-white/70 transition-all">
              <FileText size={11} />Formato CSV
            </button>
            <div className="w-px h-5 bg-white/10" />
            <button className="flex items-center gap-1.5 px-3 py-1.5 rounded border border-white/10 text-xs text-white/70 hover:bg-white/5 transition-all"><Filter size={11} />Filtros</button>
            <button className="flex items-center gap-1.5 px-3 py-1.5 rounded border border-white/10 text-xs text-white/70 hover:bg-white/5 transition-all"><Calendar size={11} />14/06/2025</button>
            <span className="text-[10px] text-white/30 border border-white/10 rounded px-2 py-1.5">Período: Hoje</span>
          </div>
        </div>
        {showCSVGuide && (
          <div className="border-t border-white/10 bg-[#051520] px-4 py-3">
            <div className="grid grid-cols-2 gap-6 max-w-4xl">
              <div>
                <div className="text-[10px] font-semibold text-green-400 mb-1.5">📄 hospitais.csv</div>
                <pre className="text-[9px] text-white/50 font-mono bg-white/5 rounded p-2 leading-relaxed overflow-x-auto">{`hospital,solicitacoes,aprovacoes,uti,enfermaria,tempo_medio,mediana,pct_atendidas\nH. Metropolitano de Cuiabá,512,312,192,120,00:18,00:12,92`}</pre>
              </div>
              <div>
                <div className="text-[10px] font-semibold text-blue-400 mb-1.5">📄 evolucao.csv (opcional)</div>
                <pre className="text-[9px] text-white/50 font-mono bg-white/5 rounded p-2 leading-relaxed overflow-x-auto">{`data,solicitacoes,aprovacoes,pendentes\n08/06,312,215,118`}</pre>
              </div>
            </div>
          </div>
        )}
      </header>
      <main className="p-3">
        <KPICards total={total} pendentes={totalPendentes} aprovados={aprovados} uti={pendentes.uti} enfermaria={pendentes.enfermaria} hemodinamica={pendentes.hemodinamica} transInterHosp={pendentes.transInterHosp} outros={pendentes.outros} />
        <div className="grid gap-2 mb-2" style={{ gridTemplateColumns: "1fr 1fr 1fr" }}>
          <AprovadosPorHospital hospitals={hospitals} />
          <UTIEnfermariaChart hospitals={hospitals} />
          <ResponseTimeTable hospitals={hospitals} />
        </div>
        <div className="grid gap-2" style={{ gridTemplateColumns: "1fr 1fr 1fr" }}>
          <ApprovalRateTable hospitals={hospitals} />
          <EvolutionChart data={evolution} />
          <DistributionDonut uti={hospitals.reduce((s,h)=>s+h.uti,0)} enfermaria={hospitals.reduce((s,h)=>s+h.enfermaria,0)} transInterHosp={pendentes.transInterHosp} hemodinamica={pendentes.hemodinamica} outros={pendentes.outros} total={total} />
        </div>
      </main>
      <footer className="px-4 py-2 border-t border-white/5 flex items-center gap-1.5">
        <div className="w-1.5 h-1.5 rounded-full animate-pulse" style={{ backgroundColor: "#36b85c" }} />
        <span className="text-[9px] text-white/30">Dados em tempo real do Sistema Estadual de Regulação — Regula MT</span>
      </footer>
    </div>
  );
}
