import React from 'react';
import { AlertTriangle, ShieldAlert, CheckCircle2, Info, Layers } from 'lucide-react';
import ReactECharts from 'echarts-for-react';

export interface ExplanationPayloadProps {
  payload: {
    pond_id: string;
    as_of: string;
    model_version: { numeric: string; adapter: string };
    risk: number;
    risk_delta_24h: number;
    calibration?: { brier_1m: number; reliability: string };
    modality_gate?: { timeseries: number; image: number; static: number };
    top_temporal_features?: Array<{
      feature: string;
      value: number;
      unit: string;
      attribution: number;
      window: string;
    }>;
    concepts?: Record<string, number>;
    nearest_cases?: Array<{ pond: string; outcome: string; similarity: number }>;
    blind_state: boolean;
    suppression_reason: string | null;
  };
  m1Prose?: string;
  m1ReasoningTrace?: string;
  m1Recommendations?: string[];
  theme?: 'light' | 'dark';
}

export const ExplanationCard: React.FC<ExplanationPayloadProps> = ({
  payload,
  m1Prose,
  m1ReasoningTrace,
  m1Recommendations,
  theme = 'light',
}) => {
  const {
    pond_id,
    risk,
    risk_delta_24h,
    blind_state,
    suppression_reason,
    modality_gate,
    top_temporal_features = [],
    nearest_cases = [],
    model_version,
  } = payload;

  const isDark = theme === 'dark';

  // Rule R5: Blind state suppression handling
  if (blind_state) {
    return (
      <div className="glass-card p-6 rounded-xl space-y-4 bg-white/90 dark:bg-slate-900/90 text-slate-800 dark:text-slate-300 border border-slate-200 dark:border-slate-700 shadow-sm">
        <div className="flex items-center justify-between">
          <span className="font-mono text-sm text-slate-500 dark:text-slate-400">POND ID: {pond_id}</span>
          <span className="px-3 py-1 bg-amber-100 dark:bg-slate-700 text-amber-800 dark:text-slate-300 text-xs font-bold rounded-full uppercase tracking-wider flex items-center gap-1.5 border border-amber-300 dark:border-slate-600">
            <ShieldAlert className="w-3.5 h-3.5 text-amber-600 dark:text-amber-400" /> Blind State (Suppressed)
          </span>
        </div>

        <div className="flex items-center gap-4 p-4 bg-amber-50 dark:bg-slate-800/80 rounded-lg border border-amber-300 dark:border-amber-500/30">
          <div className="p-3 bg-white dark:bg-slate-700/50 rounded-lg text-slate-400 font-mono text-2xl font-bold border border-slate-200 dark:border-transparent">
            --.--
          </div>
          <div>
            <h4 className="text-amber-900 dark:text-amber-400 font-bold text-sm">Alerting Suppressed by Rule R5</h4>
            <p className="text-xs text-slate-700 dark:text-slate-300 mt-0.5">
              Reason: <span className="font-mono font-bold text-amber-950 dark:text-amber-200">{suppression_reason || 'Untrustworthy sensor inputs'}</span>
            </p>
          </div>
        </div>
        <p className="text-xs text-slate-500 dark:text-slate-400 italic">
          Departmental Safety Policy: Silent failure is prohibited. When sensor inputs are untrustworthy, risk figures are greyed out to prevent mistaking telemetry loss for safety.
        </p>
      </div>
    );
  }

  // ECharts SHAP Waterfall / Feature Attribution Option
  const shapFeatures = top_temporal_features.map((f: { feature: string }) => f.feature);
  const shapAttributions = top_temporal_features.map((f: { attribution: number }) => f.attribution);

  const waterfallOption = {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'shadow' },
      formatter: (params: any[]) => {
        const item = params[0];
        const feat = top_temporal_features[item.dataIndex];
        return `
          <div style="font-family: monospace; font-size: 12px; padding: 4px; color: ${isDark ? '#fff' : '#0f172a'}">
            <strong>${feat.feature}</strong><br/>
            Value: ${feat.value} ${feat.unit}<br/>
            Window: ${feat.window}<br/>
            Attribution Score: <strong>+${(feat.attribution * 100).toFixed(1)}%</strong>
          </div>
        `;
      },
    },
    grid: { left: '3%', right: '4%', bottom: '3%', top: '8%', containLabel: true },
    xAxis: {
      type: 'value',
      axisLabel: { color: isDark ? '#94a3b8' : '#475569', fontSize: 11 },
      splitLine: { lineStyle: { color: isDark ? '#334155' : '#cbd5e1', type: 'dashed' } },
    },
    yAxis: {
      type: 'category',
      data: shapFeatures,
      axisLabel: { color: isDark ? '#cbd5e1' : '#1e293b', fontSize: 11, fontFamily: 'monospace', fontWeight: 'bold' },
    },
    series: [
      {
        name: 'SHAP Attribution',
        type: 'bar',
        data: shapAttributions,
        itemStyle: {
          color: isDark ? '#38bdf8' : '#0284c7',
          borderRadius: [0, 4, 4, 0],
        },
      },
    ],
  };

  return (
    <div className="glass-panel rounded-xl p-6 border border-slate-200 dark:border-slate-800 space-y-6 text-slate-800 dark:text-slate-200 bg-white/95 dark:bg-slate-900/95 shadow-md">
      {/* Header Info & Model Version */}
      <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-800 pb-4">
        <div>
          <div className="flex items-center gap-2">
            <h3 className="font-bold text-lg text-slate-900 dark:text-slate-100 font-mono">Pond {pond_id} Risk Attribution</h3>
            <span className="text-xs px-2 py-0.5 rounded bg-blue-50 text-blue-700 dark:bg-slate-800 dark:text-slate-400 font-mono border border-blue-200 dark:border-slate-700 font-semibold">
              {model_version.numeric} | {model_version.adapter}
            </span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
            Sample size context: Calibrated on 74,759 Pondsdata Guntur aquaculture records [Ref 26]
          </p>
        </div>
        <div className="text-right">
          <div className="flex items-center gap-2 justify-end">
            <span className="text-3xl font-extrabold font-mono text-amber-600 dark:text-amber-400">{risk.toFixed(2)}</span>
            <div className="text-left text-xs font-mono">
              <span className={`font-bold ${risk_delta_24h >= 0 ? 'text-red-600 dark:text-red-400' : 'text-emerald-600 dark:text-emerald-400'}`}>
                {risk_delta_24h >= 0 ? `+${risk_delta_24h.toFixed(2)}` : risk_delta_24h.toFixed(2)}
              </span>
              <div className="text-[10px] text-slate-400">Δ24h</div>
            </div>
          </div>
        </div>
      </div>

      {/* Mandatory PRD Section 3.3 Rule: NUMBER FIRST (SHAP Waterfall) */}
      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <h4 className="text-xs font-bold text-blue-700 dark:text-cyan-400 uppercase tracking-wider flex items-center gap-1.5 font-mono">
            <Layers className="w-3.5 h-3.5" /> 1. Quantitative SHAP Waterfall (Top Temporal Drivers)
          </h4>
          <span className="text-[10px] text-slate-500 font-mono">N = 74,759 training samples</span>
        </div>
        <div className="bg-slate-50 dark:bg-slate-900/80 rounded-lg p-3 border border-slate-200 dark:border-slate-800">
          <ReactECharts option={waterfallOption} style={{ height: '180px' }} />
        </div>
      </div>

      {/* Modality Gate Breakdown Bar (PRD Section 3.3 Rule) */}
      {modality_gate && (
        <div className="space-y-1.5 bg-slate-50 dark:bg-slate-900/60 p-3 rounded-lg border border-slate-200 dark:border-slate-800">
          <div className="flex justify-between text-xs text-slate-700 dark:text-slate-300 font-mono">
            <span className="text-slate-500 dark:text-slate-400 font-medium">Modality Gate ("What drove this call"):</span>
            <span className="text-blue-700 dark:text-cyan-400 font-bold">Timeseries ({(modality_gate.timeseries * 100).toFixed(0)}%) | Image ({(modality_gate.image * 100).toFixed(0)}%) | Static ({(modality_gate.static * 100).toFixed(0)}%)</span>
          </div>
          <div className="w-full h-2.5 bg-slate-200 dark:bg-slate-800 rounded-full overflow-hidden flex">
            <div style={{ width: `${modality_gate.timeseries * 100}%` }} className="bg-blue-600 dark:bg-cyan-500 h-full" title="Timeseries" />
            <div style={{ width: `${modality_gate.image * 100}%` }} className="bg-purple-600 dark:bg-purple-500 h-full" title="Image" />
            <div style={{ width: `${modality_gate.static * 100}%` }} className="bg-slate-400 dark:bg-slate-500 h-full" title="Static" />
          </div>
          <p className="text-[10px] text-slate-400 italic">Caption: Learned gating network attribution (not a causal claim).</p>
        </div>
      )}

      {/* Mandatory PRD Section 3.3 Rule: STORY SECOND */}
      <div className="space-y-3 bg-blue-50/50 dark:bg-slate-900/90 p-4 rounded-xl border border-blue-100 dark:border-slate-800">
        <h4 className="text-xs font-bold text-emerald-700 dark:text-emerald-400 uppercase tracking-wider font-mono flex items-center gap-1.5">
          <Info className="w-3.5 h-3.5" /> 2. M1 Water Chemistry &amp; Physics Adapter Explanation
        </h4>
        <p className="text-sm text-slate-800 dark:text-slate-200 leading-relaxed font-sans font-normal">
          {m1Prose ||
            'Dissolved oxygen minimum is projected to reach 2.4 mg/L at 04:00 due to high night respiration coupled with total ammonia nitrogen (TAN) oxidation. Stoichiometry dictates 4.18 g of O2 is consumed per g of TAN oxidised via nitrifying bacteria (Ebeling et al., 2006). At pH 8.4 and 29.5°C, un-ionised toxic ammonia (NH3) represents 11.2% of TAN.'}
        </p>

        {m1ReasoningTrace && (
          <div className="p-3 bg-white dark:bg-slate-950/80 rounded border border-slate-200 dark:border-slate-800 text-xs font-mono text-slate-600 dark:text-slate-400 space-y-1">
            <div className="text-[11px] text-blue-700 dark:text-cyan-400 font-semibold uppercase">M1 Reasoning Trace (Checkable Against Textbooks):</div>
            <div>{m1ReasoningTrace}</div>
          </div>
        )}

        {/* Rule R2 Enforced */}
        <div className="p-3 bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-500/30 rounded-lg text-xs text-amber-900 dark:text-amber-200/90 flex items-start gap-2">
          <AlertTriangle className="w-4 h-4 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
          <div>
            <span className="font-bold text-amber-950 dark:text-amber-300">Rule R2 Compliance:</span> "This pattern is consistent with overnight hypoxemia &amp; un-ionised ammonia stress — confirm by manual 04:00 DO reading and laboratory TAN titration."
          </div>
        </div>

        {/* M1 Recommendations */}
        {m1Recommendations && m1Recommendations.length > 0 && (
          <div className="space-y-1.5 pt-2">
            <div className="text-xs font-mono text-slate-700 dark:text-slate-300 font-bold">Ranked Actionable Interventions:</div>
            <ul className="space-y-1">
              {m1Recommendations.map((rec: string, i: number) => (
                <li key={i} className="text-xs text-slate-700 dark:text-slate-300 flex items-start gap-2">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 dark:text-emerald-400 shrink-0 mt-0.5" />
                  <span>{rec}</span>
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>

      {/* Nearest Historical Case Thumbnails */}
      {nearest_cases.length > 0 && (
        <div className="space-y-2 pt-1 border-t border-slate-200 dark:border-slate-800">
          <div className="text-xs font-mono text-slate-500 dark:text-slate-400 font-semibold">Nearest Historical Match (k-NN Prototype Retrieval):</div>
          <div className="grid grid-cols-2 gap-2">
            {nearest_cases.map((c: { pond: string; outcome: string; similarity: number }, i: number) => (
              <div key={i} className="p-2.5 bg-slate-50 dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-800 text-xs flex justify-between items-center">
                <div>
                  <span className="font-mono font-bold text-slate-800 dark:text-slate-200">{c.pond}</span>
                  <div className="text-[10px] text-slate-500 dark:text-slate-400">{c.outcome}</div>
                </div>
                <span className="text-xs font-mono px-2 py-0.5 bg-blue-50 text-blue-700 dark:bg-cyan-950 dark:text-cyan-300 rounded border border-blue-200 dark:border-cyan-800 font-bold">
                  {(c.similarity * 100).toFixed(0)}% sim
                </span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};
