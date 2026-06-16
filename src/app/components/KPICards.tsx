import { CheckCircle, Users } from "lucide-react";
import { PieChart, Pie, Cell, ResponsiveContainer } from "recharts";

interface Props {
  total: number; pendentes: number; aprovados: number;
  uti: number; enfermaria: number; hemodinamica: number; transInterHosp: number; outros: number;
}

export function KPICards({ total, pendentes, aprovados, uti, enfermaria, hemodinamica, transInterHosp, outros }: Props) {
  const taxaAprovacao = total > 0 ? Math.round((aprovados / total) * 1000) / 10 : 0;
  const donutData = [{ value: taxaAprovacao }, { value: 100 - taxaAprovacao }];

  return (
    <div className="grid grid-cols-5 gap-2 mb-2">
      <div className="bg-card border border-white/8 rounded p-3">
        <div className="text-[10px] uppercase tracking-widest text-white/50 mb-1">Solicitações Reguladas</div>
        <div className="text-[10px] text-white/40 mb-2">Total geral</div>
        <div className="text-3xl font-bold text-white font-mono">{total.toLocaleString("pt-BR")}</div>
        <div className="text-[10px] text-white/40 mt-1">No período</div>
      </div>
      <div className="bg-card border border-white/8 rounded p-3">
        <div className="text-[10px] uppercase tracking-widest text-white/50 mb-1">Pendentes de Avaliação</div>
        <div className="flex items-center gap-2 mt-2">
          <div className="w-10 h-10 rounded-full bg-yellow-500/20 flex items-center justify-center">
            <Users size={18} className="text-yellow-400" />
          </div>
          <div>
            <div className="text-3xl font-bold text-yellow-400 font-mono">{pendentes.toLocaleString("pt-BR")}</div>
            <div className="text-[10px] text-white/40">Em fila de avaliação</div>
          </div>
        </div>
      </div>
      <div className="bg-card border border-white/8 rounded p-3">
        <div className="text-[10px] uppercase tracking-widest text-white/50 mb-2">Pendentes por Tipo de Solicitação</div>
        <div className="grid grid-cols-5 gap-1">
          {[{ label: "UTI", value: uti }, { label: "Enfermaria", value: enfermaria }, { label: "Hemodinâmica", value: hemodinamica }, { label: "Trans. Inter-Hosp", value: transInterHosp }, { label: "Outros", value: outros }].map((item) => (
            <div key={item.label} className="text-center">
              <div className="text-lg font-bold text-white font-mono">{item.value}</div>
              <div className="text-[9px] text-white/40 leading-tight">{item.label}</div>
            </div>
          ))}
        </div>
      </div>
      <div className="bg-card border border-white/8 rounded p-3">
        <div className="text-[10px] uppercase tracking-widest text-white/50 mb-1">Aprovados</div>
        <div className="flex items-center gap-2 mt-2">
          <CheckCircle size={28} className="text-green-400 shrink-0" />
          <div>
            <div className="text-3xl font-bold text-green-400 font-mono">{aprovados.toLocaleString("pt-BR")}</div>
            <div className="text-[10px] text-white/40">No período</div>
          </div>
        </div>
      </div>
      <div className="bg-card border border-white/8 rounded p-3">
        <div className="text-[10px] uppercase tracking-widest text-white/50 mb-1">Taxa Geral de Aprovação</div>
        <div className="flex items-center gap-2">
          <div className="w-14 h-14 relative">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={donutData} innerRadius={18} outerRadius={26} startAngle={90} endAngle={-270} dataKey="value" strokeWidth={0}>
                  <Cell fill="#36b85c" /><Cell fill="#0d3350" />
                </Pie>
              </PieChart>
            </ResponsiveContainer>
            <div className="absolute inset-0 flex items-center justify-center">
              <span className="text-[9px] text-green-400 font-bold">{taxaAprovacao.toFixed(0)}%</span>
            </div>
          </div>
          <div>
            <div className="text-2xl font-bold text-green-400 font-mono">{taxaAprovacao.toFixed(1).replace(".", ",")}%</div>
            <div className="text-[10px] text-white/40">Aprovações / Total</div>
          </div>
        </div>
      </div>
    </div>
  );
}
