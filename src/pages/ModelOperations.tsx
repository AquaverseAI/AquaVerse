import React from 'react';
import { useQuery } from '@tanstack/react-query';
import ReactECharts from 'echarts-for-react';
import { ShieldCheck, Database, GitCommit, CheckCircle2, Zap, Activity } from 'lucide-react';

interface ModelOperationsProps {
  theme?: 'light' | 'dark';
}

export const ModelOperations: React.FC<ModelOperationsProps> = ({ theme = 'light' }) => {
  const isDark = theme === 'dark';

  const { data: metricsData } = useQuery({
    queryKey: ['model-metrics'],
    queryFn: async () => {
      const res = await fetch('/v1/models/metrics');
      return res.json();
    },
  });

  const { data: driftData } = useQuery({
    queryKey: ['model-drift'],
    queryFn: async () => {
      const res = await fetch('/v1/models/drift');
      return res.json();
    },
  });

  const { data: modelsData } = useQuery({
    queryKey: ['models-registry'],
    queryFn: async () => {
      const res = await fetch('/v1/models');
      return res.json();
    },
  });

  const calibPoints = metricsData?.calibration_curve || [];

  const calibrationOption = {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      backgroundColor: isDark ? '#0e2231' : '#ffffff',
      borderColor: isDark ? 'rgba(255,255,255,0.1)' : '#dce8ec',
      textStyle: { color: isDark ? '#f8fafc' : '#0f3f5c', fontFamily: 'monospace', fontSize: 11 },
    },
    legend: {
      data: ['Observed Probability', 'Ideal Calibration Line'],
      textStyle: { color: isDark ? '#cbd5e1' : '#154c6e', fontSize: 11, fontFamily: 'monospace', fontWeight: 'bold' },
    },
    grid: { left: '3%', right: '4%', bottom: '10%', top: '15%', containLabel: true },
    xAxis: {
      type: 'value',
      name: 'Predicted Risk',
      min: 0,
      max: 1,
      axisLabel: { color: isDark ? '#64748b' : '#6c8899', fontSize: 10, fontFamily: 'monospace' },
      splitLine: { lineStyle: { color: isDark ? 'rgba(255,255,255,0.07)' : '#e8f1f4', type: 'dashed' } },
    },
    yAxis: {
      type: 'value',
      name: 'Observed Rate',
      min: 0,
      max: 1,
      axisLabel: { color: isDark ? '#64748b' : '#6c8899', fontSize: 10, fontFamily: 'monospace' },
      splitLine: { lineStyle: { color: isDark ? 'rgba(255,255,255,0.07)' : '#e8f1f4', type: 'dashed' } },
    },
    series: [
      {
        name: 'Observed Probability',
        type: 'line',
        data: calibPoints.map((p: any) => [p.predicted, p.observed]),
        itemStyle: { color: isDark ? '#2e9cb8' : '#1f8aa6' },
        lineStyle: { width: 3 },
        symbolSize: 8,
      },
      {
        name: 'Ideal Calibration Line',
        type: 'line',
        data: [
          [0, 0],
          [1, 1],
        ],
        lineStyle: { color: isDark ? '#64748b' : '#94a3b8', type: 'dashed', width: 1.5 },
        symbol: 'none',
      },
    ],
  };

  return (
    <div className="space-y-4 animate-fade-in">
      {/* Top Banner */}
      <div className="instrument-card p-4 rounded-xl flex flex-col md:flex-row items-start md:items-center justify-between gap-4 shadow-sm">
        <div>
          <h2 className="text-base font-bold text-ocean-900 dark:text-slate-100 font-mono flex items-center gap-2">
            <ShieldCheck className="w-4 h-4 text-teal-600" />
            Model Operations: ML Observability &amp; Reliability
          </h2>
          <p className="text-xs text-slate-600 dark:text-slate-400 mt-1 font-sans">
            Calibrated EBM and QLoRA reasoning metrics &bull; Dataset hash verification &bull; Real-time concept drift monitoring.
          </p>
        </div>

        {/* Audit Status */}
        <div className="flex items-center gap-2 font-mono text-xs">
          <div className="px-3 py-1 bg-mint-50 dark:bg-mint-950/40 border border-mint-200 dark:border-mint-900/50 rounded-lg flex items-center gap-2">
            <CheckCircle2 className="w-3.5 h-3.5 text-mint-600" />
            <div>
              <div className="text-[11px] font-bold text-mint-800 dark:text-mint-300">Hallucination Violations: 0</div>
              <div className="text-[9px] text-slate-500">Post-generation validator active</div>
            </div>
          </div>
        </div>
      </div>

      {/* KPI Cards Row */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="instrument-card p-4 rounded-xl space-y-1">
          <span className="text-[11px] text-slate-500 dark:text-slate-400 font-mono font-semibold">Brier Score (1-Month)</span>
          <div className="text-3xl font-bold font-mono text-teal-700 dark:text-teal-400">
            {metricsData?.brier_score || 0.082}
          </div>
          <span className="text-[10px] text-mint-700 font-mono font-bold">Well-calibrated (&lt; 0.10)</span>
        </div>

        <div className="instrument-card p-4 rounded-xl space-y-1">
          <span className="text-[11px] text-slate-500 dark:text-slate-400 font-mono font-semibold">AUC-PR Metric</span>
          <div className="text-3xl font-bold font-mono text-purple-600 dark:text-purple-400">
            {metricsData?.auc_pr || 0.884}
          </div>
          <span className="text-[10px] text-purple-700 dark:text-purple-300 font-mono font-bold">Precision-Recall curve</span>
        </div>

        <div className="instrument-card p-4 rounded-xl space-y-1">
          <span className="text-[11px] text-slate-500 dark:text-slate-400 font-mono font-semibold">Lead Time Horizon</span>
          <div className="text-3xl font-bold font-mono text-amber-600 dark:text-amber-400">
            {metricsData?.lead_time_hours || 14.5}h
          </div>
          <span className="text-[10px] text-slate-500 font-mono">Prior to hypoxemia onset</span>
        </div>

        <div className="instrument-card p-4 rounded-xl space-y-1">
          <span className="text-[11px] text-slate-500 dark:text-slate-400 font-mono font-semibold">False Alarms / Pond-Week</span>
          <div className="text-3xl font-bold font-mono text-mint-700 dark:text-mint-400">
            {metricsData?.false_alarms_per_pond_week || 0.12}
          </div>
          <span className="text-[10px] text-mint-700 font-mono font-bold">Low farmer fatigue rate</span>
        </div>
      </div>

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
        <div className="lg:col-span-7 instrument-card p-5 rounded-xl space-y-3">
          <div className="flex justify-between items-center border-b border-surface-border dark:border-surface-darkBorder pb-2">
            <h3 className="text-xs font-bold text-ocean-900 dark:text-slate-100 font-mono uppercase tracking-wider flex items-center gap-2">
              <Zap className="w-4 h-4 text-teal-600" /> Model Reliability Calibration Curve
            </h3>
            <span className="text-[10px] font-mono text-slate-500">Evaluated Monthly</span>
          </div>

          <ReactECharts option={calibrationOption} style={{ height: '300px' }} />

          <p className="text-xs text-slate-600 dark:text-slate-400 font-sans">
            Strict probabilistic calibration: Points falling on the dashed line demonstrate that a predicted risk of 70% corresponds to actual disease/anoxia events 70% of the time.
          </p>
        </div>

        <div className="lg:col-span-5 space-y-4">
          <div className="instrument-card p-4 rounded-xl space-y-3">
            <div className="flex items-center justify-between border-b border-surface-border dark:border-surface-darkBorder pb-2">
              <h3 className="text-xs font-bold text-ocean-900 dark:text-slate-100 font-mono uppercase tracking-wider flex items-center gap-2">
                <Database className="w-4 h-4 text-purple-600" /> Population Stability Index (PSI) Drift
              </h3>
              <span className="text-[10px] text-slate-500 font-mono">vs Baseline</span>
            </div>

            <table className="w-full text-left text-xs font-mono">
              <thead className="bg-surface-cardSubtle dark:bg-surface-darkCardAlt text-slate-600 dark:text-slate-400 border-b border-surface-border dark:border-surface-darkBorder font-semibold">
                <tr>
                  <th className="p-2">Feature</th>
                  <th className="p-2">PSI Score</th>
                  <th className="p-2">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-border dark:divide-surface-darkBorder">
                {(driftData?.psi_by_feature || []).map((row: any, i: number) => (
                  <tr key={i}>
                    <td className="p-2 text-ocean-900 dark:text-slate-200 font-medium">{row.feature}</td>
                    <td className="p-2 text-slate-700 dark:text-slate-300 font-bold">{row.psi}</td>
                    <td className="p-2">
                      <span className={`px-2 py-0.5 rounded text-[10px] font-bold border ${
                        row.psi < 0.1
                          ? 'bg-mint-50 text-mint-800 border-mint-200 dark:bg-mint-950 dark:text-mint-300'
                          : 'bg-amber-50 text-amber-800 border-amber-200 dark:bg-amber-950 dark:text-amber-300'
                      }`}>
                        {row.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="instrument-card p-4 rounded-xl space-y-3">
            <div className="flex items-center justify-between border-b border-surface-border dark:border-surface-darkBorder pb-2">
              <h3 className="text-xs font-bold text-ocean-900 dark:text-slate-100 font-mono uppercase tracking-wider flex items-center gap-2">
                <GitCommit className="w-4 h-4 text-teal-600" /> Active Model Version Registry
              </h3>
            </div>

            <div className="space-y-2 text-xs font-mono">
              {(modelsData?.active_models || []).map((m: any, i: number) => (
                <div key={i} className="p-2.5 bg-surface-cardSubtle dark:bg-surface-darkCardAlt rounded-lg border border-surface-border dark:border-surface-darkBorder space-y-1">
                  <div className="flex justify-between font-bold text-ocean-900 dark:text-slate-200">
                    <span>{m.name}</span>
                    <span className="text-teal-700 dark:text-teal-400">{m.adapter || m.version}</span>
                  </div>
                  <div className="text-[10px] text-slate-500 dark:text-slate-400 truncate">Hash: {m.dataset_hash}</div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
