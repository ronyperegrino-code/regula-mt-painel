import { useRef } from "react";
import { Upload, X } from "lucide-react";

export type HospitalRow = {
  hospital: string;
  solicitacoes: number;
  aprovacoes: number;
  uti: number;
  enfermaria: number;
  tempo_medio: string;
  mediana: string;
  pct_atendidas: number;
};

export type DayRow = {
  data: string;
  solicitacoes: number;
  aprovacoes: number;
  pendentes: number;
};

export type CSVData = {
  hospitals: HospitalRow[];
  evolution: DayRow[];
};

function parseHospitals(text: string): HospitalRow[] {
  const lines = text.trim().split("\n");
  const header = lines[0].toLowerCase();
  if (!header.includes("hospital")) return [];
  return lines.slice(1).map((line) => {
    const cols = line.split(",").map((c) => c.trim());
    return {
      hospital: cols[0] ?? "",
      solicitacoes: Number(cols[1]) || 0,
      aprovacoes: Number(cols[2]) || 0,
      uti: Number(cols[3]) || 0,
      enfermaria: Number(cols[4]) || 0,
      tempo_medio: cols[5] ?? "00:00",
      mediana: cols[6] ?? "00:00",
      pct_atendidas: Number((cols[7] ?? "0").replace("%", "")) || 0,
    };
  });
}

function parseEvolution(text: string): DayRow[] {
  const lines = text.trim().split("\n");
  const header = lines[0].toLowerCase();
  if (!header.includes("data") && !header.includes("date")) return [];
  return lines.slice(1).map((line) => {
    const cols = line.split(",").map((c) => c.trim());
    return {
      data: cols[0] ?? "",
      solicitacoes: Number(cols[1]) || 0,
      aprovacoes: Number(cols[2]) || 0,
      pendentes: Number(cols[3]) || 0,
    };
  });
}

interface Props {
  onData: (data: CSVData) => void;
  hasData: boolean;
  onReset: () => void;
}

export function CSVUpload({ onData, hasData, onReset }: Props) {
  const hospRef = useRef<HTMLInputElement>(null);
  const evoRef = useRef<HTMLInputElement>(null);

  async function handleHosp(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    const text = await file.text();
    const hospitals = parseHospitals(text);
    onData({ hospitals, evolution: [] });
  }

  async function handleEvo(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    const text = await file.text();
    const evolution = parseEvolution(text);
    onData({ hospitals: [], evolution });
  }

  return (
    <div className="flex items-center gap-2">
      <input ref={hospRef} type="file" accept=".csv" className="hidden" onChange={handleHosp} />
      <input ref={evoRef} type="file" accept=".csv" className="hidden" onChange={handleEvo} />

      <button
        onClick={() => hospRef.current?.click()}
        className="flex items-center gap-1.5 px-3 py-1.5 rounded text-xs border border-white/15 text-white/70 hover:text-white hover:border-green-500/50 hover:bg-green-500/10 transition-all"
      >
        <Upload size={12} />
        Hospitais CSV
      </button>

      <button
        onClick={() => evoRef.current?.click()}
        className="flex items-center gap-1.5 px-3 py-1.5 rounded text-xs border border-white/15 text-white/70 hover:text-white hover:border-blue-500/50 hover:bg-blue-500/10 transition-all"
      >
        <Upload size={12} />
        Evolução CSV
      </button>

      {hasData && (
        <button
          onClick={onReset}
          className="flex items-center gap-1 px-2 py-1.5 rounded text-xs text-red-400 hover:text-red-300 hover:bg-red-500/10 transition-all"
        >
          <X size={12} />
          Resetar
        </button>
      )}
    </div>
  );
}
