import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { Database, ShieldAlert, Clock } from 'lucide-react';

interface DataQualityProps {
  theme?: 'light' | 'dark';
}

export const DataQuality: React.FC<DataQualityProps> = ({ theme = 'light' }) => {
  const { data: dqSummary } = useQuery({
    queryKey: ['data-quality'],
    queryFn: async () => {
      const res = await fetch('/v1/data-quality');
      return res.json();
    },
  });

  const { data: alertsList = [] } = useQuery({
    queryKey: ['alerts-feed'],
    queryFn: async () => {
      const res = await fetch('/v1/alerts');
      return res.json();
    },
  });

  const suppressedAlerts = alertsList.filter((a: any) => a.suppressed);

  return (
    <div className="space-y-4">
      {/* Top Banner */}
      <div className="glass-panel p-4 rounded-xl border border-blue-200 dark:border-amber-900/40 bg-gradient-to-r from-blue-50 via-white to-cyan-50 dark:from-slate-900 dark:via-slate-900 dark:to-amber-950/40 flex items-center justify-between shadow-sm">
        <div>
          <h2 className="text-sm font-bold text-blue-900 dark:text-amber-300 font-mono flex items-center gap-2">
            <Database className="w-4 h-4 text-blue-600 dark:text-amber-400" /> Screen 6: Telemetry Data Quality — Coimbatore 3 Lakes Monitor
          </h2>
          <p className="text-xs text-slate-700 dark:text-slate-300 mt-0.5 font-sans font-medium">
            Per-pond missingness, stuck-value detection, calibration-due register for <strong className="text-blue-700 dark:text-cyan-400">Valankulam Tank, Singanallur Lake, and Ukkadam Periyakulam</strong>.
            <span className="text-blue-900 dark:text-amber-300 font-bold ml-1">Rule R5: Suppressed alerts must be visible, or the department will interpret silence as safety.</span>
          </p>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="glass-panel p-4 rounded-xl border border-slate-200 dark:border-slate-800 space-y-1 bg-white dark:bg-slate-900 shadow-sm">
          <span className="text-[11px] text-slate-500 dark:text-slate-400 font-mono font-semibold">Total Ponds Monitored</span>
          <div className="text-2xl font-bold font-mono text-blue-600 dark:text-cyan-400">
            {dqSummary?.total_ponds || 110}
          </div>
          <span className="text-[10px] text-emerald-600 dark:text-emerald-400 font-mono font-bold">108 Active Sensors</span>
        </div>

        <div className="glass-panel p-4 rounded-xl border border-amber-200 dark:border-amber-900/50 space-y-1 bg-amber-50 dark:bg-amber-950/20 shadow-sm">
          <span className="text-[11px] text-amber-800 dark:text-amber-300 font-mono font-semibold">Blind State Ponds (Rule R5)</span>
          <div className="text-2xl font-bold font-mono text-amber-600 dark:text-amber-400">
            {dqSummary?.blind_state_ponds || 2}
          </div>
          <span className="text-[10px] text-amber-700 dark:text-amber-300 font-mono font-bold">Telemetry lost &gt; 12h</span>
        </div>

        <div className="glass-panel p-4 rounded-xl border border-slate-200 dark:border-slate-800 space-y-1 bg-white dark:bg-slate-900 shadow-sm">
          <span className="text-[11px] text-slate-500 dark:text-slate-400 font-mono font-semibold">Sensor Stuck-Value Alerts</span>
          <div className="text-2xl font-bold font-mono text-purple-600 dark:text-purple-400">
            {dqSummary?.stuck_value_alerts || 1}
          </div>
          <span className="text-[10px] text-slate-500 font-mono font-medium">Zero variance detected</span>
        </div>

        <div className="glass-panel p-4 rounded-xl border border-slate-200 dark:border-slate-800 space-y-1 bg-white dark:bg-slate-900 shadow-sm">
          <span className="text-[11px] text-slate-500 dark:text-slate-400 font-mono font-semibold">Calibration-Due Register</span>
          <div className="text-2xl font-bold font-mono text-blue-600 dark:text-cyan-400">
            {dqSummary?.calibration_due_count || 3}
          </div>
          <span className="text-[10px] text-slate-500 font-mono font-medium">DO optical membrane due</span>
        </div>
      </div>

      {/* Main Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
        <div className="lg:col-span-7 glass-panel p-5 rounded-xl border border-amber-200 dark:border-amber-900/40 bg-white dark:bg-slate-950 space-y-4 shadow-sm">
          <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-800 pb-2">
            <h3 className="text-xs font-bold text-amber-800 dark:text-amber-300 font-mono uppercase tracking-wider flex items-center gap-2">
              <ShieldAlert className="w-4 h-4 text-amber-600 dark:text-amber-400" /> Suppressed Alerts Feed (Rule R5 Compliance)
            </h3>
            <span className="text-[10px] font-mono text-amber-800 dark:text-amber-400 px-2 py-0.5 rounded bg-amber-100 dark:bg-amber-950 border border-amber-300 dark:border-amber-800 font-bold">
              Coimbatore Audit View
            </span>
          </div>

          <p className="text-xs text-slate-700 dark:text-slate-300 font-sans">
            When telemetry is lost or sensor readings fail validation checks, alerting is suppressed. These suppressed alerts are explicitly listed here so analysts never mistake missing telemetry for pond safety.
          </p>

          <div className="space-y-3">
            {suppressedAlerts.map((alt: any, i: number) => (
              <div key={i} className="p-3.5 bg-amber-50/50 dark:bg-slate-900/90 rounded-lg border border-amber-200 dark:border-amber-500/30 space-y-2">
                <div className="flex justify-between font-mono text-xs">
                  <span className="font-bold text-amber-900 dark:text-amber-400">{alt.pond_id} ({alt.district})</span>
                  <span className="text-slate-500 dark:text-slate-400 text-[10px]">{new Date(alt.timestamp).toLocaleTimeString()}</span>
                </div>
                <div className="text-xs text-slate-800 dark:text-slate-200 font-semibold">{alt.title}</div>
                <div className="p-2 bg-white dark:bg-slate-950 rounded text-xs text-amber-900 dark:text-amber-200 font-mono border border-amber-200 dark:border-amber-900/40 font-medium">
                  Suppression Reason: {alt.suppression_reason}
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="lg:col-span-5 glass-panel p-5 rounded-xl border border-slate-200 dark:border-slate-800 space-y-4 bg-white dark:bg-slate-950 shadow-sm">
          <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-800 pb-2">
            <h3 className="text-xs font-bold text-slate-900 dark:text-slate-200 font-mono uppercase tracking-wider flex items-center gap-2">
              <Clock className="w-4 h-4 text-blue-600 dark:text-cyan-400" /> Sensor Telemetry Last-Seen Register
            </h3>
          </div>

          <div className="space-y-2 text-xs font-mono">
            <div className="p-2.5 bg-slate-50 dark:bg-slate-900 rounded border border-slate-200 dark:border-slate-800 flex justify-between items-center">
              <div>
                <span className="font-bold text-blue-700 dark:text-cyan-400">CBE-003: Valankulam Tank</span>
                <div className="text-[10px] text-slate-500 dark:text-slate-400">10.9922°N, 76.9721°E | DO, pH, Temp, TAN</div>
              </div>
              <span className="text-emerald-700 dark:text-emerald-400 text-[10px] font-bold">2 mins ago</span>
            </div>

            <div className="p-2.5 bg-slate-50 dark:bg-slate-900 rounded border border-slate-200 dark:border-slate-800 flex justify-between items-center">
              <div>
                <span className="font-bold text-amber-700 dark:text-amber-400">CBE-001: Singanallur Lake</span>
                <div className="text-[10px] text-slate-500 dark:text-slate-400">10.9901°N, 77.0218°E | DO, pH, Temp, TAN</div>
              </div>
              <span className="text-emerald-700 dark:text-emerald-400 text-[10px] font-bold">5 mins ago</span>
            </div>

            <div className="p-2.5 bg-slate-50 dark:bg-slate-900 rounded border border-slate-200 dark:border-slate-800 flex justify-between items-center">
              <div>
                <span className="font-bold text-emerald-700 dark:text-emerald-400">CBE-002: Ukkadam Periyakulam</span>
                <div className="text-[10px] text-slate-500 dark:text-slate-400">10.9826°N, 76.9554°E | DO, pH, Temp, TAN</div>
              </div>
              <span className="text-emerald-700 dark:text-emerald-400 text-[10px] font-bold">8 mins ago</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
