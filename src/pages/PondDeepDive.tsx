import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import ReactECharts from 'echarts-for-react';
import { Activity, Sliders, Wind, MessageSquare, Database, Sparkles, ArrowDown, Droplets, ChevronRight } from 'lucide-react';
import { ExplanationCard } from '../components/common/ExplanationCard';
import { LogIngestionModal } from '../components/common/LogIngestionModal';
import { AskFarmerModal } from '../components/common/AskFarmerModal';
import { PondDigitalTwin3D } from '../components/common/PondDigitalTwin3D';
import { RiskStatusBadge } from '../components/common/RiskStatusBadge';

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

  // ECharts Theme Colors for Light / Dark
  const chartColors = {
    do: isDark ? '#2e9cb8' : '#1f8aa6',
    ph: isDark ? '#f59e0b' : '#e8a33d',
    temp: isDark ? '#4fbfa0' : '#2e9c7a',
    tan: isDark ? '#c084fc' : '#8b5cf6',
    grid: isDark ? 'rgba(255, 255, 255, 0.07)' : '#e8f1f4',
    text: isDark ? '#cbd5e1' : '#154c6e',
    textMuted: isDark ? '#64748b' : '#6c8899',
    bg: 'transparent',
    tooltipBg: isDark ? '#0e2231' : '#ffffff',
    tooltipBorder: isDark ? 'rgba(255,255,255,0.1)' : '#dce8ec',
  };

  const multiParamChartOption = {
    backgroundColor: chartColors.bg,
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'cross' },
      backgroundColor: chartColors.tooltipBg,
      borderColor: chartColors.tooltipBorder,
      textStyle: { color: chartColors.text, fontFamily: 'monospace', fontSize: 11 },
    },
    legend: {
      data: ['DO (mg/L)', 'pH Level', 'Temp (°C)', 'TAN (mg/L)'],
      textStyle: { color: chartColors.text, fontSize: 11, fontFamily: 'monospace', fontWeight: 'bold' },
      top: '0%',
      icon: 'roundRect',
    },
    grid: { left: '3%', right: '4%', bottom: '15%', top: '12%', containLabel: true },
    dataZoom: [
      { type: 'inside', start: 60, end: 100 },
      { type: 'slider', bottom: '2%', height: 18, borderColor: chartColors.tooltipBorder },
    ],
    xAxis: {
      type: 'category',
      data: timestamps,
      axisLabel: { color: chartColors.textMuted, fontSize: 10, fontFamily: 'monospace' },
      axisLine: { lineStyle: { color: chartColors.grid } },
    },
    yAxis: [
      {
        type: 'value',
        name: 'DO / TAN (mg/L)',
        position: 'left',
        axisLabel: { color: chartColors.do, fontSize: 10, fontFamily: 'monospace', fontWeight: 'bold' },
        splitLine: { lineStyle: { color: chartColors.grid, type: 'dashed' } },
      },
      {
        type: 'value',
        name: 'pH / Temp (°C)',
        position: 'right',
        axisLabel: { color: chartColors.ph, fontSize: 10, fontFamily: 'monospace', fontWeight: 'bold' },
        splitLine: { show: false },
      },
    ],
    series: [
      {
        name: 'DO (mg/L)',
        type: 'line',
        smooth: true,
        data: doSeries,
        itemStyle: { color: chartColors.do },
        lineStyle: { width: 2.5 },
        markLine: {
          data: [{ yAxis: 3.0, name: 'Critical Hypoxia (3.0)' }],
          lineStyle: { color: '#dc3545', type: 'dashed' },
        },
      },
      {
        name: 'pH Level',
        type: 'line',
        yAxisIndex: 1,
        smooth: true,
        data: phSeries,
        itemStyle: { color: chartColors.ph },
        lineStyle: { width: 1.5 },
      },
      {
        name: 'Temp (°C)',
        type: 'line',
        yAxisIndex: 1,
        smooth: true,
        data: tempSeries,
        itemStyle: { color: chartColors.temp },
        lineStyle: { width: 1.5 },
      },
      {
        name: 'TAN (mg/L)',
        type: 'line',
        smooth: true,
        data: tanSeries,
        itemStyle: { color: chartColors.tan },
        lineStyle: { width: 2 },
      },
    ],
  };

  const forecastTimes = forecastData?.timestamps || [];
  const p50 = forecastData?.forecast_p50 || [];
  const p10 = forecastData?.forecast_p10 || [];
  const p90 = forecastData?.forecast_p90 || [];

  const forecastOption = {
    backgroundColor: chartColors.bg,
    tooltip: {
      trigger: 'axis',
      backgroundColor: chartColors.tooltipBg,
      borderColor: chartColors.tooltipBorder,
      textStyle: { color: chartColors.text, fontFamily: 'monospace', fontSize: 11 },
    },
    grid: { left: '3%', right: '4%', bottom: '10%', top: '10%', containLabel: true },
    xAxis: {
      type: 'category',
      data: forecastTimes,
      axisLabel: { color: chartColors.textMuted, fontSize: 10, fontFamily: 'monospace' },
    },
    yAxis: {
      type: 'value',
      name: 'DO (mg/L)',
      min: 0,
      max: 9,
      axisLabel: { color: chartColors.text, fontSize: 10, fontFamily: 'monospace' },
      splitLine: { lineStyle: { color: chartColors.grid } },
    },
    series: [
      {
        name: 'Forecast P50 (Median)',
        type: 'line',
        data: p50,
        itemStyle: { color: chartColors.do },
        lineStyle: { width: 2.5 },
        markPoint: {
          data: [
            {
              type: 'min',
              name: '04:00 Overnight Min',
              itemStyle: { color: '#dc3545' },
              label: { formatter: '04:00 Min: 2.1 mg/L', fontFamily: 'monospace', fontSize: 10 },
            },
          ],
        },
      },
      {
        name: 'Ribbon Upper (P90)',
        type: 'line',
        data: p90,
        lineStyle: { opacity: 0 },
        stack: 'confidence-band',
      },
      {
        name: 'Ribbon Lower (P10)',
        type: 'line',
        data: p10.map((v: number, idx: number) => (p90[idx] - v).toFixed(2)),
        lineStyle: { opacity: 0 },
        areaStyle: { color: isDark ? 'rgba(46, 156, 184, 0.2)' : 'rgba(31, 138, 166, 0.15)' },
        stack: 'confidence-band',
      },
    ],
  };

  return (
    <div className="space-y-4 animate-fade-in">
      {/* Top Banner: Pond Identification & Quick Telemetry Ingestion Actions */}
      <div className="instrument-card p-4 rounded-xl flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-base font-bold text-ocean-900 dark:text-slate-100 font-mono tracking-tight">
              Pond Deep Dive &amp; 3D Digital Twin: {pondId}
            </h2>
            <span className="text-[10px] px-2 py-0.5 rounded bg-teal-50 text-teal-800 dark:bg-teal-950/60 dark:text-teal-300 border border-teal-200 dark:border-teal-800 font-mono font-bold">
              Coimbatore Basin &bull; P. vannamei
            </span>
          </div>
          <p className="text-xs text-slate-600 dark:text-slate-400 mt-1 font-sans">
            Multi-parameter telemetry series, 24–72h DO forecast ribbon, and physics-informed What-If simulator.
          </p>
        </div>

        {/* Action Triggers */}
        <div className="flex items-center gap-2.5 shrink-0 font-mono text-xs">
          <button
            onClick={() => setIsLogModalOpen(true)}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-mint-600 hover:bg-mint-700 text-white font-bold rounded-lg transition-all shadow-sm active:scale-95"
          >
            <Database className="w-3.5 h-3.5" />
            <span>Ingest Telemetry Log</span>
          </button>
          <button
            onClick={() => setIsAskModalOpen(true)}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-teal-600 hover:bg-teal-700 text-white font-bold rounded-lg transition-all shadow-sm active:scale-95"
          >
            <MessageSquare className="w-3.5 h-3.5" />
            <span>Ask AI Assistant</span>
          </button>
        </div>
      </div>

      {/* Modals */}
      <LogIngestionModal pondId={pondId} isOpen={isLogModalOpen} onClose={() => setIsLogModalOpen(false)} />
      <AskFarmerModal pondId={pondId} isOpen={isAskModalOpen} onClose={() => setIsAskModalOpen(false)} />

      {/* Row 1: 3D Digital Twin & What-If Simulation Row */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
        {/* 3D Digital Twin Canvas (7 cols) */}
        <div className="lg:col-span-7 flex flex-col">
          <PondDigitalTwin3D
            pondId={pondId}
            theme={theme}
            aerationHours={aerationHours}
            waterExchangePct={waterExchangePct}
            feedReductionPct={feedReductionPct}
            simulatedDO={twinState?.do_mg_l ?? 4.6}
            simulatedTAN={twinState?.tan_mg_l ?? 0.52}
          />
        </div>

        {/* Digital Twin What-If Intervention Panel (5 cols) - STRICT INPUTS/OUTPUTS SEPARATION */}
        <div className="lg:col-span-5 flex flex-col">
          <div className="instrument-card p-5 rounded-xl flex-1 flex flex-col justify-between space-y-3.5">
            {/* Header */}
            <div className="border-b border-surface-border dark:border-surface-darkBorder pb-2.5">
              <div className="flex items-center justify-between">
                <h3 className="text-xs font-bold text-ocean-900 dark:text-slate-100 font-mono uppercase tracking-wider flex items-center gap-2">
                  <Sliders className="w-4 h-4 text-teal-600 dark:text-teal-400" /> Digital Twin What-If Simulator
                </h3>
                <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-teal-50 dark:bg-teal-950 text-teal-700 dark:text-teal-300 border border-teal-200 dark:border-teal-800 font-bold">
                  PRD-AV-07
                </span>
              </div>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-1 font-sans">
                Adjust physical intervention parameters to simulate benthic response in the 3D twin.
              </p>
            </div>

            {/* SECTION 1: SIMULATOR INPUTS (CARD 1) */}
            <div className="p-3.5 bg-surface-cardSubtle dark:bg-surface-darkCardAlt rounded-xl border border-surface-border dark:border-surface-darkBorder space-y-3">
              <div className="text-[11px] font-mono font-bold uppercase tracking-wider text-ocean-900 dark:text-teal-300 flex items-center gap-1.5">
                <span className="w-1.5 h-1.5 rounded-full bg-teal-600" /> 1. Hypothetical Management Interventions
              </div>

              {/* Slider 1 */}
              <div className="space-y-1">
                <div className="flex justify-between text-xs font-mono">
                  <span className="text-slate-600 dark:text-slate-300">Night Aeration Hours:</span>
                  <span className="text-teal-700 dark:text-teal-400 font-bold">{aerationHours} hours</span>
                </div>
                <input
                  type="range"
                  min="0"
                  max="14"
                  value={aerationHours}
                  onChange={(e) => setAerationHours(Number(e.target.value))}
                  className="w-full accent-teal-600 cursor-pointer"
                />
              </div>

              {/* Slider 2 */}
              <div className="space-y-1">
                <div className="flex justify-between text-xs font-mono">
                  <span className="text-slate-600 dark:text-slate-300">Canal Water Exchange Rate:</span>
                  <span className="text-teal-700 dark:text-teal-400 font-bold">{waterExchangePct}% / day</span>
                </div>
                <input
                  type="range"
                  min="0"
                  max="30"
                  value={waterExchangePct}
                  onChange={(e) => setWaterExchangePct(Number(e.target.value))}
                  className="w-full accent-teal-600 cursor-pointer"
                />
              </div>

              {/* Slider 3 */}
              <div className="space-y-1">
                <div className="flex justify-between text-xs font-mono">
                  <span className="text-slate-600 dark:text-slate-300">Feed Input Reduction:</span>
                  <span className="text-teal-700 dark:text-teal-400 font-bold">{feedReductionPct}%</span>
                </div>
                <input
                  type="range"
                  min="0"
                  max="50"
                  value={feedReductionPct}
                  onChange={(e) => setFeedReductionPct(Number(e.target.value))}
                  className="w-full accent-teal-600 cursor-pointer"
                />
              </div>
            </div>

            {/* CAUSALITY CONNECTOR DIVIDER */}
            <div className="flex items-center justify-center gap-2 py-0.5 text-[10px] font-mono font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider">
              <span className="h-[1px] flex-1 bg-surface-border dark:bg-surface-darkBorder" />
              <span className="flex items-center gap-1 text-teal-700 dark:text-teal-400">
                <ArrowDown className="w-3 h-3 text-teal-600" /> Simulates Physical Response
              </span>
              <span className="h-[1px] flex-1 bg-surface-border dark:bg-surface-darkBorder" />
            </div>

            {/* SECTION 2: 3D SIMULATED PHYSICAL OUTCOME (CARD 2) */}
            {twinState && (
              <div className="p-3.5 bg-mint-50/70 dark:bg-mint-950/20 rounded-xl border border-mint-200 dark:border-mint-900/50 space-y-2.5">
                <div className="text-[11px] font-mono font-bold text-mint-800 dark:text-mint-300 flex items-center justify-between">
                  <span className="flex items-center gap-1.5">
                    <Sparkles className="w-3.5 h-3.5 text-mint-600" /> 2. 3D Simulated Physical Outcome
                  </span>
                  <span className="text-[9px] px-1.5 py-0.2 bg-mint-100 text-mint-800 dark:bg-mint-900 dark:text-mint-200 rounded font-mono">
                    Live Coupling
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-2 text-xs font-mono">
                  <div className="p-2.5 bg-white dark:bg-surface-darkCard rounded-lg border border-mint-200 dark:border-mint-900/40 shadow-xs">
                    <span className="text-slate-500 dark:text-slate-400 text-[10px] block">Projected 04:00 DO</span>
                    <span className="text-mint-700 dark:text-mint-400 font-extrabold text-base">
                      {twinState.do_mg_l} mg/L
                    </span>
                  </div>
                  <div className="p-2.5 bg-white dark:bg-surface-darkCard rounded-lg border border-mint-200 dark:border-mint-900/40 shadow-xs">
                    <span className="text-slate-500 dark:text-slate-400 text-[10px] block">Projected TAN</span>
                    <span className="text-teal-700 dark:text-teal-400 font-extrabold text-base">
                      {twinState.tan_mg_l} mg/L
                    </span>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Row 2: Telemetry Sensor Series & Risk Explanation Hero Card */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
        {/* Left Column (7 cols): Charts */}
        <div className="lg:col-span-7 space-y-4">
          <div className="instrument-card p-4 rounded-xl space-y-2">
            <div className="flex justify-between items-center border-b border-surface-border dark:border-surface-darkBorder pb-2">
              <h3 className="text-xs font-bold text-ocean-900 dark:text-slate-100 font-mono flex items-center gap-1.5 uppercase">
                <Activity className="w-3.5 h-3.5 text-teal-600" /> 1. Hourly Multi-Parameter Sensor Series
              </h3>
              <span className="text-[10px] text-slate-400 font-mono">100k+ Point DataZoom</span>
            </div>
            <ReactECharts option={multiParamChartOption} style={{ height: '300px' }} />
          </div>

          <div className="instrument-card p-4 rounded-xl space-y-2">
            <div className="flex justify-between items-center border-b border-surface-border dark:border-surface-darkBorder pb-2">
              <h3 className="text-xs font-bold text-ocean-900 dark:text-slate-100 font-mono flex items-center gap-1.5 uppercase">
                <Wind className="w-3.5 h-3.5 text-mint-600" /> 2. Dissolved Oxygen 24–72h Forecast Band &amp; 04:00 Minimum
              </h3>
              <span className="text-[10px] text-slate-400 font-mono">Rule R6 Quantile Ribbon (P10 - P90)</span>
            </div>
            <ReactECharts option={forecastOption} style={{ height: '220px' }} />
          </div>
        </div>

        {/* Right Column (5 cols): Calibrated Explanation Hero Card */}
        <div className="lg:col-span-5 space-y-4">
          {riskPayload && <ExplanationCard payload={riskPayload} theme={theme} />}
        </div>
      </div>
    </div>
  );
};
