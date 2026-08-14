import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import ReactECharts from 'echarts-for-react';
import { Activity, Sliders, Wind, MessageSquare, Database, Sparkles } from 'lucide-react';
import { ExplanationCard } from '../components/common/ExplanationCard';
import { LogIngestionModal } from '../components/common/LogIngestionModal';
import { AskFarmerModal } from '../components/common/AskFarmerModal';

interface PondDeepDiveProps {
  pondId: string;
  theme?: 'light' | 'dark';
}

export const PondDeepDive: React.FC<PondDeepDiveProps> = ({ pondId, theme = 'light' }) => {
  const isDark = theme === 'dark';

  // Modal Visibility States
  const [isLogModalOpen, setIsLogModalOpen] = useState(false);
  const [isAskModalOpen, setIsAskModalOpen] = useState(false);

  // What-If Intervention State
  const [aerationHours, setAerationHours] = useState(8);
  const [waterExchangePct, setWaterExchangePct] = useState(10);
  const [feedReductionPct, setFeedReductionPct] = useState(20);

  // TanStack Query for Timeseries
  const { data: timeseriesData } = useQuery({
    queryKey: ['pond-timeseries', pondId],
    queryFn: async () => {
      const res = await fetch(`/v1/ponds/${pondId}/timeseries?agg=hourly`);
      return res.json();
    },
  });

  // Query for DO Forecast
  const { data: forecastData } = useQuery({
    queryKey: ['pond-forecast', pondId],
    queryFn: async () => {
      const res = await fetch(`/v1/ponds/${pondId}/forecast/do`);
      return res.json();
    },
  });

  // Query for Explanation Risk Payload
  const { data: riskPayload } = useQuery({
    queryKey: ['pond-risk', pondId],
    queryFn: async () => {
      const res = await fetch(`/v1/ponds/${pondId}/risk`);
      return res.json();
    },
  });

  // Query for What-If Simulator Endpoint
  const { data: twinState } = useQuery({
    queryKey: ['twin-state', pondId, aerationHours, waterExchangePct, feedReductionPct],
    queryFn: async () => {
      const res = await fetch(`/v1/twin/${pondId}/whatif`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          aeration_hours: aerationHours,
          water_exchange_rate: waterExchangePct,
          feed_reduction_pct: feedReductionPct,
        }),
      });
      return res.json();
    },
  });

  const timestamps = timeseriesData?.timestamps || [];
  const doSeries = timeseriesData?.series?.DO || [];
  const phSeries = timeseriesData?.series?.pH || [];
  const tempSeries = timeseriesData?.series?.Temperature || [];
  const tanSeries = timeseriesData?.series?.TAN || [];

  const multiParamChartOption = {
    backgroundColor: 'transparent',
    tooltip: { trigger: 'axis', axisPointer: { type: 'cross' } },
    legend: {
      data: ['Dissolved Oxygen (mg/L)', 'pH', 'Temperature (°C)', 'TAN (mg/L)'],
      textStyle: { color: isDark ? '#cbd5e1' : '#334155', fontSize: 11, fontWeight: 'bold' },
      top: '0%',
    },
    grid: { left: '3%', right: '4%', bottom: '15%', top: '12%', containLabel: true },
    dataZoom: [
      { type: 'inside', start: 60, end: 100 },
      { type: 'slider', bottom: '2%', height: 20, borderColor: isDark ? '#334155' : '#cbd5e1' },
    ],
    xAxis: {
      type: 'category',
      data: timestamps,
      axisLabel: { color: isDark ? '#94a3b8' : '#64748b', fontSize: 10 },
      axisLine: { lineStyle: { color: isDark ? '#334155' : '#e2e8f0' } },
    },
    yAxis: [
      {
        type: 'value',
        name: 'DO / TAN (mg/L)',
        position: 'left',
        axisLabel: { color: isDark ? '#38bdf8' : '#0284c7', fontSize: 10, fontWeight: 'bold' },
        splitLine: { lineStyle: { color: isDark ? '#1e293b' : '#f1f5f9', type: 'dashed' } },
      },
      {
        type: 'value',
        name: 'pH / Temp (°C)',
        position: 'right',
        axisLabel: { color: isDark ? '#f59e0b' : '#d97706', fontSize: 10, fontWeight: 'bold' },
        splitLine: { show: false },
      },
    ],
    series: [
      {
        name: 'Dissolved Oxygen (mg/L)',
        type: 'line',
        smooth: true,
        data: doSeries,
        itemStyle: { color: isDark ? '#38bdf8' : '#0284c7' },
        lineStyle: { width: 2.5 },
        markLine: {
          data: [{ yAxis: 3.0, name: 'Critical DO Threshold (3.0 mg/L)' }],
          lineStyle: { color: '#ef4444', type: 'dashed' },
        },
      },
      {
        name: 'pH',
        type: 'line',
        yAxisIndex: 1,
        smooth: true,
        data: phSeries,
        itemStyle: { color: isDark ? '#f59e0b' : '#d97706' },
        lineStyle: { width: 1.5 },
      },
      {
        name: 'Temperature (°C)',
        type: 'line',
        yAxisIndex: 1,
        smooth: true,
        data: tempSeries,
        itemStyle: { color: isDark ? '#10b981' : '#059669' },
        lineStyle: { width: 1.5 },
      },
      {
        name: 'TAN (mg/L)',
        type: 'line',
        smooth: true,
        data: tanSeries,
        itemStyle: { color: isDark ? '#c084fc' : '#9333ea' },
        lineStyle: { width: 2 },
      },
    ],
  };

  const forecastTimes = forecastData?.timestamps || [];
  const p50 = forecastData?.forecast_p50 || [];
  const p10 = forecastData?.forecast_p10 || [];
  const p90 = forecastData?.forecast_p90 || [];

  const forecastOption = {
    backgroundColor: 'transparent',
    tooltip: { trigger: 'axis' },
    grid: { left: '3%', right: '4%', bottom: '10%', top: '10%', containLabel: true },
    xAxis: {
      type: 'category',
      data: forecastTimes,
      axisLabel: { color: isDark ? '#94a3b8' : '#64748b', fontSize: 10 },
    },
    yAxis: {
      type: 'value',
      name: 'DO (mg/L)',
      min: 0,
      max: 9,
      axisLabel: { color: isDark ? '#cbd5e1' : '#334155', fontSize: 10 },
      splitLine: { lineStyle: { color: isDark ? '#1e293b' : '#f1f5f9' } },
    },
    series: [
      {
        name: 'Forecast P50 (Median)',
        type: 'line',
        data: p50,
        itemStyle: { color: isDark ? '#0ea5e9' : '#0284c7' },
        lineStyle: { width: 2.5 },
        markPoint: {
          data: [
            {
              type: 'min',
              name: 'Overnight Minimum (04:00)',
              itemStyle: { color: '#ef4444' },
              label: { formatter: '04:00 Min: 2.4 mg/L' },
            },
          ],
        },
      },
      {
        name: 'Uncertainty Ribbon Upper (P90)',
        type: 'line',
        data: p90,
        lineStyle: { opacity: 0 },
        stack: 'confidence-band',
      },
      {
        name: 'Uncertainty Ribbon Lower (P10)',
        type: 'line',
        data: p10.map((v: number, idx: number) => (p90[idx] - v).toFixed(2)),
        lineStyle: { opacity: 0 },
        areaStyle: { color: isDark ? 'rgba(14, 165, 233, 0.25)' : 'rgba(2, 132, 199, 0.15)' },
        stack: 'confidence-band',
      },
    ],
  };

  return (
    <div className="space-y-4">
      {/* Header Banner */}
      <div className="glass-panel p-4 rounded-xl border border-blue-200 dark:border-cyan-900/40 bg-white dark:bg-slate-900 flex flex-col md:flex-row md:items-center justify-between gap-4 shadow-sm">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-base font-bold text-slate-900 dark:text-slate-100 font-mono">Pond Deep Dive: {pondId}</h2>
            <span className="text-xs px-2.5 py-0.5 rounded bg-blue-50 text-blue-700 border border-blue-200 dark:bg-cyan-950 dark:text-cyan-400 dark:border-cyan-800 font-mono font-bold">
              Coimbatore District | Noyyal Basin | P. vannamei
            </span>
          </div>
          <p className="text-xs text-slate-600 dark:text-slate-400 mt-0.5 font-sans">
            Synchronized multi-parameter sensor curves, 24–72h DO forecast ribbon, and Digital Twin what-if simulator.
          </p>
        </div>

        {/* Action Triggers */}
        <div className="flex items-center gap-2 shrink-0">
          <button
            onClick={() => setIsLogModalOpen(true)}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-lg transition-all shadow-sm font-mono"
          >
            <Database className="w-3.5 h-3.5" />
            Ingest Telemetry Log (/v1/logs)
          </button>
          <button
            onClick={() => setIsAskModalOpen(true)}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-gradient-to-r from-blue-600 to-cyan-600 hover:from-blue-700 hover:to-cyan-700 text-white font-bold text-xs rounded-lg transition-all shadow-sm font-mono"
          >
            <MessageSquare className="w-3.5 h-3.5" />
            Ask AI Assistant (/v1/ask)
          </button>
        </div>
      </div>

      {/* Modals */}
      <LogIngestionModal pondId={pondId} isOpen={isLogModalOpen} onClose={() => setIsLogModalOpen(false)} />
      <AskFarmerModal pondId={pondId} isOpen={isAskModalOpen} onClose={() => setIsAskModalOpen(false)} />

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
        {/* Left Column (7 cols): Charts */}
        <div className="lg:col-span-7 space-y-4">
          <div className="glass-panel p-4 rounded-xl border border-slate-200 dark:border-slate-800 space-y-2 bg-white dark:bg-slate-950 shadow-sm">
            <div className="flex justify-between items-center">
              <h3 className="text-xs font-bold text-blue-700 dark:text-cyan-400 font-mono flex items-center gap-1.5 uppercase">
                <Activity className="w-3.5 h-3.5" /> 1. Hourly Multi-Parameter Sensor Series (Shared Brushable Axis)
              </h3>
              <span className="text-[10px] text-slate-400 font-mono">100k+ Point ECharts DataZoom</span>
            </div>
            <ReactECharts option={multiParamChartOption} style={{ height: '320px' }} />
          </div>

          <div className="glass-panel p-4 rounded-xl border border-slate-200 dark:border-slate-800 space-y-2 bg-white dark:bg-slate-950 shadow-sm">
            <div className="flex justify-between items-center">
              <h3 className="text-xs font-bold text-emerald-700 dark:text-emerald-400 font-mono flex items-center gap-1.5 uppercase">
                <Wind className="w-3.5 h-3.5" /> 2. Dissolved Oxygen 24–72h Forecast Band &amp; Overnight 04:00 Minimum
              </h3>
              <span className="text-[10px] text-slate-500 dark:text-slate-400 font-mono">Rule R6 Uncertainty Ribbon (P10 - P90)</span>
            </div>
            <ReactECharts option={forecastOption} style={{ height: '220px' }} />
          </div>
        </div>

        {/* Right Column (5 cols): Explanation & Digital Twin What-If Panel */}
        <div className="lg:col-span-5 space-y-4">
          {riskPayload && <ExplanationCard payload={riskPayload} theme={theme} />}

          <div className="glass-panel p-5 rounded-xl border border-blue-200 dark:border-cyan-800/40 bg-gradient-to-b from-blue-50/50 to-white dark:from-slate-900 dark:via-slate-900 dark:to-cyan-950/30 space-y-4 shadow-sm">
            <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-800 pb-3">
              <h3 className="text-xs font-bold text-blue-900 dark:text-cyan-300 font-mono uppercase tracking-wider flex items-center gap-2">
                <Sliders className="w-4 h-4 text-blue-600 dark:text-cyan-400" /> Digital Twin What-If Intervention Panel
              </h3>
              <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-blue-100 text-blue-800 dark:bg-slate-800 dark:text-slate-400 font-bold">
                PRD-AV-07 Mountable
              </span>
            </div>

            <p className="text-xs text-slate-700 dark:text-slate-300 font-sans">
              Re-run server-side physical simulator under hypothetical management interventions to evaluate parameter response before issuing farmer advisories.
            </p>

            <div className="space-y-3 bg-white dark:bg-slate-950 p-3 rounded-lg border border-slate-200 dark:border-slate-800 shadow-sm">
              <div className="space-y-1">
                <div className="flex justify-between text-xs font-mono">
                  <span className="text-slate-700 dark:text-slate-300 font-medium">Night Aeration Hours:</span>
                  <span className="text-blue-700 dark:text-cyan-400 font-bold">{aerationHours} hours</span>
                </div>
                <input
                  type="range"
                  min="0"
                  max="14"
                  value={aerationHours}
                  onChange={(e) => setAerationHours(Number(e.target.value))}
                  className="w-full accent-blue-600 cursor-pointer"
                />
              </div>

              <div className="space-y-1">
                <div className="flex justify-between text-xs font-mono">
                  <span className="text-slate-700 dark:text-slate-300 font-medium">Canal Water Exchange Rate:</span>
                  <span className="text-blue-700 dark:text-cyan-400 font-bold">{waterExchangePct}% / day</span>
                </div>
                <input
                  type="range"
                  min="0"
                  max="30"
                  value={waterExchangePct}
                  onChange={(e) => setWaterExchangePct(Number(e.target.value))}
                  className="w-full accent-blue-600 cursor-pointer"
                />
              </div>

              <div className="space-y-1">
                <div className="flex justify-between text-xs font-mono">
                  <span className="text-slate-700 dark:text-slate-300 font-medium">Feed Input Reduction:</span>
                  <span className="text-blue-700 dark:text-cyan-400 font-bold">{feedReductionPct}%</span>
                </div>
                <input
                  type="range"
                  min="0"
                  max="50"
                  value={feedReductionPct}
                  onChange={(e) => setFeedReductionPct(Number(e.target.value))}
                  className="w-full accent-blue-600 cursor-pointer"
                />
              </div>
            </div>

            {twinState && (
              <div className="p-3 bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-800 space-y-2 shadow-sm">
                <div className="text-xs font-mono text-emerald-700 dark:text-emerald-400 font-bold">Simulated State Outcome:</div>
                <div className="grid grid-cols-2 gap-2 text-xs font-mono">
                  <div className="p-2 bg-blue-50/50 dark:bg-slate-950 rounded border border-blue-100 dark:border-slate-800">
                    <span className="text-slate-500 dark:text-slate-400 text-[10px] block">Projected 04:00 DO</span>
                    <span className="text-emerald-700 dark:text-emerald-400 font-extrabold text-sm">{twinState.do_mg_l} mg/L</span>
                  </div>
                  <div className="p-2 bg-blue-50/50 dark:bg-slate-950 rounded border border-blue-100 dark:border-slate-800">
                    <span className="text-slate-500 dark:text-slate-400 text-[10px] block">Projected TAN</span>
                    <span className="text-blue-700 dark:text-cyan-400 font-extrabold text-sm">{twinState.tan_mg_l} mg/L</span>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
