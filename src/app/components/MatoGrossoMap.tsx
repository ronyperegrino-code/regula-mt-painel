import { useState } from "react";

export type RegionData = {
  regiao: string;
  municipio_sede: string;
  fila_total: number;
  urgente: number;
  tempo_resposta_min: number;
  leitos_disponiveis: number;
  taxa_atendimento: number;
};

interface Props {
  regions: RegionData[];
  onSelectRegion?: (r: RegionData | null) => void;
  selected?: string | null;
}

const REGIONS_SVG = [
  {
    id: "Sinop",
    label: "Norte",
    sede: "Sinop",
    path: "M 65,25 L 210,8 L 365,22 L 395,85 L 385,165 L 300,175 L 210,178 L 120,168 L 58,155 L 45,90 Z",
    labelX: 215,
    labelY: 95,
  },
  {
    id: "Barra do Garças",
    label: "Leste",
    sede: "Barra do Garças",
    path: "M 300,175 L 385,165 L 392,250 L 378,330 L 340,375 L 285,365 L 268,285 L 295,225 Z",
    labelX: 338,
    labelY: 265,
  },
  {
    id: "Cuiabá",
    label: "Centro-Sul",
    sede: "Cuiabá",
    path: "M 120,168 L 210,178 L 300,175 L 295,225 L 268,285 L 225,335 L 162,340 L 122,295 L 108,230 Z",
    labelX: 205,
    labelY: 255,
  },
  {
    id: "Cáceres",
    label: "Oeste",
    sede: "Cáceres",
    path: "M 45,90 L 58,155 L 120,168 L 108,230 L 122,295 L 78,355 L 55,335 L 28,305 L 22,225 L 32,140 Z",
    labelX: 72,
    labelY: 215,
  },
  {
    id: "Rondonópolis",
    label: "Sudeste",
    sede: "Rondonópolis",
    path: "M 122,295 L 162,340 L 225,335 L 268,285 L 285,365 L 340,375 L 310,420 L 235,432 L 155,410 L 78,355 Z",
    labelX: 205,
    labelY: 385,
  },
];

function intensityColor(fila: number, max: number, selected: boolean) {
  const ratio = max > 0 ? fila / max : 0;
  const alpha = selected ? 0.95 : 0.75;
  if (ratio > 0.7) return `rgba(239,68,68,${alpha})`;
  if (ratio > 0.4) return `rgba(245,158,11,${alpha})`;
  if (ratio > 0.2) return `rgba(54,184,92,${alpha})`;
  return `rgba(42,90,168,${alpha})`;
}

function intensityLabel(fila: number, max: number) {
  const ratio = max > 0 ? fila / max : 0;
  if (ratio > 0.7) return { text: "CRÍTICO", color: "#ef4444" };
  if (ratio > 0.4) return { text: "ALTO", color: "#f59e0b" };
  if (ratio > 0.2) return { text: "MÉDIO", color: "#36b85c" };
  return { text: "BAIXO", color: "#2a5aa8" };
}

export function MatoGrossoMap({ regions, onSelectRegion, selected }: Props) {
  const [hovered, setHovered] = useState<string | null>(null);
  const maxFila = Math.max(...regions.map(r => r.fila_total), 1);

  function getRegionData(id: string) {
    return regions.find(r => r.regiao === id || r.municipio_sede === id);
  }

  return (
    <div className="bg-card border border-white/8 rounded p-3 h-full flex flex-col">
      <div className="text-[10px] uppercase tracking-widest text-white/50 mb-0.5">Mapa do Estado — Mato Grosso</div>
      <div className="text-[9px] text-white/30 mb-2">Intensidade da fila por macrorregião de saúde</div>

      <div className="flex gap-2 mb-2 flex-wrap">
        {[
          { label: "Crítico", color: "#ef4444" },
          { label: "Alto", color: "#f59e0b" },
          { label: "Médio", color: "#36b85c" },
          { label: "Baixo", color: "#2a5aa8" },
        ].map(l => (
          <span key={l.label} className="flex items-center gap-1 text-[9px] text-white/50">
            <span className="w-2.5 h-2.5 rounded-sm inline-block" style={{ backgroundColor: l.color }} />
            {l.label}
          </span>
        ))}
      </div>

      <div className="flex-1 flex items-center justify-center">
        <svg viewBox="0 0 430 450" className="w-full max-h-[320px]" style={{ filter: "drop-shadow(0 2px 8px rgba(0,0,0,0.4))" }}>
          {/* State border shadow */}
          <path
            d="M 65,25 L 210,8 L 365,22 L 395,85 L 392,250 L 378,330 L 340,375 L 310,420 L 235,432 L 155,410 L 78,355 L 55,335 L 28,305 L 22,225 L 32,140 Z"
            fill="none" stroke="rgba(255,255,255,0.05)" strokeWidth="12"
          />

          {REGIONS_SVG.map(region => {
            const data = getRegionData(region.id);
            const fila = data?.fila_total ?? 0;
            const isSelected = selected === region.id;
            const isHovered = hovered === region.id;
            const fill = intensityColor(fila, maxFila, isSelected || isHovered);
            const intensity = data ? intensityLabel(fila, maxFila) : { text: "S/D", color: "#8a9bb0" };

            return (
              <g
                key={region.id}
                style={{ cursor: "pointer" }}
                onClick={() => onSelectRegion?.(isSelected ? null : (data ?? null))}
                onMouseEnter={() => setHovered(region.id)}
                onMouseLeave={() => setHovered(null)}
              >
                <path
                  d={region.path}
                  fill={fill}
                  stroke={isSelected ? "#ffffff" : isHovered ? "rgba(255,255,255,0.5)" : "rgba(255,255,255,0.15)"}
                  strokeWidth={isSelected ? 2 : 1}
                  style={{ transition: "all 0.2s" }}
                />
                {/* Region label */}
                <text
                  x={region.labelX}
                  y={region.labelY - 8}
                  textAnchor="middle"
                  fill="rgba(255,255,255,0.9)"
                  fontSize="9"
                  fontWeight="600"
                  fontFamily="Inter, sans-serif"
                  style={{ pointerEvents: "none" }}
                >
                  {region.label}
                </text>
                <text
                  x={region.labelX}
                  y={region.labelY + 4}
                  textAnchor="middle"
                  fill="rgba(255,255,255,0.6)"
                  fontSize="7.5"
                  fontFamily="Inter, sans-serif"
                  style={{ pointerEvents: "none" }}
                >
                  {region.sede}
                </text>
                {data && (
                  <>
                    <text
                      x={region.labelX}
                      y={region.labelY + 16}
                      textAnchor="middle"
                      fill="rgba(255,255,255,0.9)"
                      fontSize="11"
                      fontWeight="700"
                      fontFamily="JetBrains Mono, monospace"
                      style={{ pointerEvents: "none" }}
                    >
                      {fila}
                    </text>
                    <text
                      x={region.labelX}
                      y={region.labelY + 26}
                      textAnchor="middle"
                      fill={intensity.color}
                      fontSize="7"
                      fontWeight="600"
                      fontFamily="Inter, sans-serif"
                      style={{ pointerEvents: "none" }}
                    >
                      {intensity.text}
                    </text>
                  </>
                )}
              </g>
            );
          })}

          {/* MT label */}
          <text x="210" y="465" textAnchor="middle" fill="rgba(255,255,255,0.2)" fontSize="8" fontFamily="Inter, sans-serif">
            MATO GROSSO
          </text>
        </svg>
      </div>

      {/* Tooltip for selected region */}
      {selected && (() => {
        const data = getRegionData(selected);
        if (!data) return null;
        const intensity = intensityLabel(data.fila_total, maxFila);
        return (
          <div className="mt-2 border border-white/10 rounded p-2 bg-white/5">
            <div className="flex items-center justify-between mb-1">
              <span className="text-[10px] font-semibold text-white">{data.regiao}</span>
              <span className="text-[9px] font-semibold px-1.5 py-0.5 rounded" style={{ backgroundColor: intensity.color + "33", color: intensity.color }}>
                {intensity.text}
              </span>
            </div>
            <div className="grid grid-cols-3 gap-2">
              <div className="text-center"><div className="text-[9px] text-white/40">Fila</div><div className="text-sm font-mono font-bold text-white">{data.fila_total}</div></div>
              <div className="text-center"><div className="text-[9px] text-white/40">Urgente</div><div className="text-sm font-mono font-bold text-red-400">{data.urgente}</div></div>
              <div className="text-center"><div className="text-[9px] text-white/40">Leitos</div><div className="text-sm font-mono font-bold text-green-400">{data.leitos_disponiveis}</div></div>
            </div>
          </div>
        );
      })()}
    </div>
  );
}
