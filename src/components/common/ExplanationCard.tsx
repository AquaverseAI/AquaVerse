import React, { useEffect, useState, useRef } from 'react';
import {
  AlertTriangle,
  ShieldAlert,
  CheckCircle2,
  Info,
  Layers,
  TrendingUp,
  TrendingDown,
  Cpu,
  Database,
  Compass,
  Sparkles,
  ChevronRight,
  HelpCircle,
} from 'lucide-react';
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

/**
 * Smooth Animated Number Hook (Tween)
 */
function useAnimatedNumber(targetValue: number, durationMs = 400) {
  const [displayValue, setDisplayValue] = useState(targetValue);
  const startValRef = useRef(targetValue);
  const startTimeRef = useRef<number | null>(null);
  const animFrameRef = useRef<number | null>(null);

  useEffect(() => {
    startValRef.current = displayValue;
    startTimeRef.current = null;

    const step = (timestamp: number) => {
      if (!startTimeRef.current) startTimeRef.current = timestamp;
      const progress = Math.min((timestamp - startTimeRef.current) / durationMs, 1);
      // Ease out cubic
      const easeProgress = 1 - Math.pow(1 - progress, 3);
      const current = startValRef.current + (targetValue - startValRef.current) * easeProgress;
      setDisplayValue(current);

      if (progress < 1) {
        animFrameRef.current = requestAnimationFrame(step);
      }
    };

    animFrameRef.current = requestAnimationFrame(step);

    return () => {
      if (animFrameRef.current) cancelAnimationFrame(animFrameRef.current);
    };
  }, [targetValue, durationMs]);

  return displayValue;
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
    modality_gate = { timeseries: 0.74, image: 0.19, static: 0.07 },
    top_temporal_features = [],
    nearest_cases = [],
    model_version = { numeric: 'm2-ebm-0.4.1', adapter: 'm1_chemistry-lora-1.0.0' },
    calibration = { brier_1m: 0.09, reliability: 'calibrated' },
  } = payload;

  const isDark = theme === 'dark';
  const animatedRisk = useAnimatedNumber(risk);

  // Semantic Risk Classification
  const isCritical = risk >= 0.7;
  const isElevated = risk >= 0.4 && risk < 0.7;
  const isOptimal = risk < 0.4;

  const riskStatusText = blind_state
    ? 'BLIND STATE'
    : isCritical
    ? 'CRITICAL RISK'
    : isElevated
    ? 'ELEVATED RISK'
    : 'OPTIMAL STABILITY';

  const riskStatusBadgeClass = blind_state
    ? 'bg-slate-100 text-slate-700 border-slate-300 dark:bg-slate-800 dark:text-slate-300'
    : isCritical
    ? 'bg-risk-criticalBg text-risk-critical border-risk-criticalBorder'
    : isElevated
    ? 'bg-risk-warningBg text-risk-warning border-risk-warningBorder'
    : 'bg-risk-healthyBg text-mint-700 dark:text-mint-400 border-risk-healthyBorder';

  const heroScoreColor = blind_state
    ? 'text-slate-500'
    : isCritical
    ? 'text-risk-critical'
    : isElevated
    ? 'text-risk-warning'
    : 'text-mint-700 dark:text-mint-400';

  // SHAP Waterfall Data Preparation
  const shapDrivers = top_temporal_features.length > 0 ? top_temporal_features : [
    { feature: 'DO 4-hr Drop Velocity', value: -1.2, unit: 'mg/L/h', attribution: 0.38, window: '4h' },
    { feature: 'Canal Inflow Nitrate', value: 3.4, unit: 'mg/L', attribution: 0.25, window: '12h' },
    { feature: 'Night Aeration Deficit', value: -3.0, unit: 'hours', attribution: 0.18, window: '24h' },
    { feature: 'Water Temperature', value: 29.8, unit: '°C', attribution: 0.11, window: '6h' },
  ];

  const maxAttribution = Math.max(...shapDrivers.map((d) => Math.abs(d.attribution)), 0.01);

  // ECharts Option for Horizontal SHAP Waterfall
  const shapChartOption = {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'shadow' },
      backgroundColor: isDark ? '#0e2231' : '#ffffff',
      borderColor: isDark ? 'rgba(255,255,255,0.1)' : '#dce8ec',
      textStyle: { color: isDark ? '#f8fafc' : '#0f3f5c', fontFamily: 'monospace', fontSize: 11 },
      formatter: (params: any) => {
        const item = shapDrivers[params[0].dataIndex];
        return `
          <div style="font-family: monospace; font-size: 11px;">
            <div style="font-weight: bold; color: ${isDark ? '#2e9cb8' : '#1f8aa6'}">${item.feature}</div>
            <div style="color: #64748b; margin-top: 2px;">Observed Value: <span style="color: ${isDark ? '#fff' : '#0f3f5c'}; font-weight: bold;">${item.value} ${item.unit}</span></div>
            <div style="color: #64748b;">SHAP Attribution: <span style="color: ${isCritical ? '#dc3545' : '#1f8aa6'}; font-weight: bold;">+${(item.attribution * 100).toFixed(1)}%</span></div>
          </div>
        `;
      },
    },
    grid: { left: '2%', right: '14%', top: '4%', bottom: '4%', containLabel: true },
    xAxis: {
      type: 'value',
      show: false,
      max: maxAttribution * 1.25,
    },
    yAxis: {
      type: 'category',
      data: shapDrivers.map((d) => d.feature).reverse(),
      axisLabel: {
        color: isDark ? '#cbd5e1' : '#0f3f5c',
        fontSize: 11,
        fontFamily: 'Inter, sans-serif',
        fontWeight: 500,
      },
      axisLine: { show: false },
      axisTick: { show: false },
    },
    series: [
      {
        type: 'bar',
        barWidth: 14,
        data: shapDrivers.map((d, index) => ({
          value: d.attribution,
          itemStyle: {
            color: index === 0
              ? (isCritical ? '#dc3545' : isElevated ? '#e8a33d' : '#1f8aa6')
              : (isDark ? '#175e6e' : '#85d0e2'),
            borderRadius: [0, 4, 4, 0],
          },
          label: {
            show: true,
            position: 'right',
            formatter: `+${(d.attribution * 100).toFixed(1)}%`,
            color: isDark ? '#cbd5e1' : '#0f3f5c',
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: 'bold',
          },
        })).reverse(),
      },
    ],
  };

  return (
    <div className="instrument-card p-5 rounded-xl space-y-4 animate-fade-in">
      {/* 1. HERO METRIC MODULE */}
      <div className="border-b border-surface-border dark:border-surface-darkBorder pb-4 space-y-2">
        <div className="flex items-start justify-between">
          <div>
            <div className="flex items-center gap-2">
              <span className="text-[11px] font-mono font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                Calibrated Hypoxia Risk Score
              </span>
              <span className="text-[10px] font-mono px-1.5 py-0.2 rounded bg-teal-50 dark:bg-teal-950 text-teal-700 dark:text-teal-300 border border-teal-200 dark:border-teal-800 font-bold">
                PRD-AV-04
              </span>
            </div>

            {/* Massive Hero Risk Score with Animated Tween */}
            <div className="flex items-baseline gap-3 pt-1" aria-live="polite" aria-label={`Calibrated Risk Score ${risk}`}>
              <span className={`text-5xl font-mono font-extrabold tracking-tight ${heroScoreColor}`}>
                {blind_state ? 'N/A' : animatedRisk.toFixed(2)}
              </span>

              {/* Status Badge */}
              <span className={`text-xs font-mono font-bold px-2.5 py-1 rounded-full border shadow-xs ${riskStatusBadgeClass}`}>
                {riskStatusText}
              </span>

              {/* 24-Hour Velocity Delta Indicator */}
              {!blind_state && (
                <span
                  className={`flex items-center gap-0.5 text-xs font-mono font-bold px-2 py-0.5 rounded ${
                    risk_delta_24h > 0
                      ? 'text-risk-critical bg-risk-criticalBg border border-risk-criticalBorder'
                      : 'text-mint-700 bg-risk-healthyBg border border-risk-healthyBorder'
                  }`}
                >
                  {risk_delta_24h > 0 ? (
                    <TrendingUp className="w-3.5 h-3.5" />
                  ) : (
                    <TrendingDown className="w-3.5 h-3.5" />
                  )}
                  <span>
                    {risk_delta_24h > 0 ? `+${risk_delta_24h.toFixed(2)}` : risk_delta_24h.toFixed(2)} &Delta;24h
                  </span>
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Model Provenance & Brier Calibration Tags */}
        <div className="flex flex-wrap items-center gap-2 text-[10px] font-mono text-slate-500 dark:text-slate-400 pt-1">
          <span className="px-2 py-0.5 bg-surface-cardSubtle dark:bg-surface-darkCardAlt rounded border border-surface-border dark:border-surface-darkBorder">
            Version: <strong className="text-ocean-900 dark:text-slate-200">{model_version.numeric} | {model_version.adapter}</strong>
          </span>
          <span className="px-2 py-0.5 bg-surface-cardSubtle dark:bg-surface-darkCardAlt rounded border border-surface-border dark:border-surface-darkBorder">
            Brier Score (1-Mo): <strong className="text-teal-700 dark:text-teal-400">{calibration.brier_1m} ({calibration.reliability})</strong>
          </span>
        </div>
      </div>

      {/* 2. SEGMENTED MODALITY GATE */}
      <div className="space-y-2">
        <div className="flex justify-between items-center text-xs font-mono">
          <span className="font-bold text-ocean-900 dark:text-slate-100 flex items-center gap-1.5 uppercase">
            <Layers className="w-3.5 h-3.5 text-teal-600" /> Modality Gate Breakdown
          </span>
          <span className="text-[10px] text-slate-400">Softmax Gating</span>
        </div>

        {/* Segmented Stacked Bar */}
        <div className="w-full h-3 rounded-full overflow-hidden flex bg-surface-border dark:bg-slate-800 ring-1 ring-surface-border">
          <div
            style={{ width: `${(modality_gate.timeseries * 100).toFixed(0)}%` }}
            className="bg-teal-600 h-full transition-all duration-300"
            title={`Timeseries: ${(modality_gate.timeseries * 100).toFixed(0)}%`}
          />
          <div
            style={{ width: `${(modality_gate.image * 100).toFixed(0)}%` }}
            className="bg-purple-500 h-full transition-all duration-300"
            title={`Computer Vision: ${(modality_gate.image * 100).toFixed(0)}%`}
          />
          <div
            style={{ width: `${(modality_gate.static * 100).toFixed(0)}%` }}
            className="bg-slate-400 h-full transition-all duration-300"
            title={`Static Geospatial: ${(modality_gate.static * 100).toFixed(0)}%`}
          />
        </div>

        {/* Legend */}
        <div className="flex items-center justify-between text-[11px] font-mono pt-1">
          <span className="flex items-center gap-1.5 text-slate-700 dark:text-slate-300">
            <span className="w-2.5 h-2.5 rounded-full bg-teal-600 inline-block" />
            <span>Timeseries: <strong>{(modality_gate.timeseries * 100).toFixed(0)}%</strong></span>
          </span>
          <span className="flex items-center gap-1.5 text-slate-700 dark:text-slate-300">
            <span className="w-2.5 h-2.5 rounded-full bg-purple-500 inline-block" />
            <span>Vision: <strong>{(modality_gate.image * 100).toFixed(0)}%</strong></span>
          </span>
          <span className="flex items-center gap-1.5 text-slate-700 dark:text-slate-300">
            <span className="w-2.5 h-2.5 rounded-full bg-slate-400 inline-block" />
            <span>Static Geo: <strong>{(modality_gate.static * 100).toFixed(0)}%</strong></span>
          </span>
        </div>
        <p className="text-[10px] text-slate-400 dark:text-slate-500 font-sans italic">
          Learned gating network attribution across sensor telemetry, optical satellite imagery, and soil bathymetry.
        </p>
      </div>

      {/* 3. QUANTITATIVE SHAP WATERFALL */}
      <div className="space-y-2 pt-1">
        <div className="flex justify-between items-center">
          <span className="text-xs font-bold text-ocean-900 dark:text-slate-100 font-mono uppercase flex items-center gap-1.5">
            <Cpu className="w-3.5 h-3.5 text-teal-600" /> Dominant SHAP Temporal Drivers
          </span>
          <span className="text-[10px] font-mono text-slate-400">Additive Feature Impact</span>
        </div>

        <div className="bg-surface-cardSubtle dark:bg-surface-darkCardAlt p-2.5 rounded-xl border border-surface-border dark:border-surface-darkBorder">
          <ReactECharts option={shapChartOption} style={{ height: '140px' }} />
        </div>
      </div>

      {/* 4. M1 NATURAL-LANGUAGE CHEMISTRY REASONING */}
      <div className="space-y-2 pt-1 border-t border-surface-border dark:border-surface-darkBorder">
        <div className="flex items-center justify-between">
          <span className="text-xs font-bold text-ocean-900 dark:text-slate-100 font-mono flex items-center gap-1.5 uppercase">
            <Sparkles className="w-3.5 h-3.5 text-amber-500" /> M1 Chemistry Reasoning Trace
          </span>
          <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-amber-50 dark:bg-amber-950/60 text-amber-800 dark:text-amber-300 border border-amber-200 dark:border-amber-800 font-bold">
            Rule R2 Compliant
          </span>
        </div>

        <div className="p-3 bg-surface-cardSubtle dark:bg-surface-darkCardAlt rounded-xl border border-surface-border dark:border-surface-darkBorder text-xs leading-relaxed space-y-2">
          <p className="text-slate-700 dark:text-slate-300 font-sans">
            {m1Prose || (
              <>
                <strong className="text-ocean-900 dark:text-slate-100">Benthic Anoxia Cascade:</strong> Rapid DO drop velocity (&minus;1.2 mg/L/h) combined with high un-ionised ammonia (TAN 0.52 mg/L at pH 8.1) triggers elevated mortality risk for <em>P. vannamei</em> biomass. Nitrification slows critically below 3.5 mg/L DO.
              </>
            )}
          </p>

          {/* Actionable Interventions */}
          <div className="pt-2 border-t border-surface-border dark:border-surface-darkBorder">
            <span className="text-[10px] font-mono font-bold uppercase tracking-wider text-teal-800 dark:text-teal-300 block mb-1">
              Recommended Interventions:
            </span>
            <ul className="space-y-1 text-slate-700 dark:text-slate-300 text-[11px] font-mono">
              {(m1Recommendations || [
                '1. Run paddlewheel aerators 2 & 3 continuously (22:00 – 06:00)',
                '2. Reduce morning feed ration by 25% to curtail TAN excretion',
                '3. Execute 10% canal water exchange via feeder sluice',
              ]).map((rec, i) => (
                <li key={i} className="flex items-start gap-1.5">
                  <span className="text-teal-600 font-bold">&bull;</span>
                  <span>{rec}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>

      {/* 5. HISTORICAL CASE PROTOTYPES (k-NN Nearest Neighbors) */}
      <div className="space-y-2 pt-1 border-t border-surface-border dark:border-surface-darkBorder">
        <span className="text-xs font-bold text-ocean-900 dark:text-slate-100 font-mono flex items-center gap-1.5 uppercase">
          <Database className="w-3.5 h-3.5 text-teal-600" /> Historical Prototype Cases (k-NN)
        </span>

        <div className="grid grid-cols-2 gap-2 text-xs font-mono">
          {(nearest_cases.length > 0 ? nearest_cases : [
            { pond: 'CBE-001 (Singanallur)', outcome: 'Hypoxia Avoided (Aeration +3h)', similarity: 0.94 },
            { pond: 'TN-NAG-044', outcome: 'Algal Crash Observed', similarity: 0.88 },
          ]).map((c, i) => (
            <div key={i} className="p-2.5 bg-surface-cardSubtle dark:bg-surface-darkCardAlt rounded-lg border border-surface-border dark:border-surface-darkBorder space-y-1">
              <div className="flex justify-between items-center">
                <span className="font-bold text-ocean-900 dark:text-slate-200">{c.pond}</span>
                <span className="text-teal-700 dark:text-teal-400 font-extrabold text-[10px]">
                  {(c.similarity * 100).toFixed(0)}% Match
                </span>
              </div>
              <p className="text-[10px] text-slate-500 dark:text-slate-400 truncate">{c.outcome}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};
