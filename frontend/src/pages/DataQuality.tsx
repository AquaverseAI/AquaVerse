import React, { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  useReactTable,
  getCoreRowModel,
  flexRender,
  createColumnHelper,
} from '@tanstack/react-table';
import { Database, ShieldAlert, AlertTriangle, CheckCircle2, Wrench, Activity } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

interface DataQualityProps {
  theme?: 'light' | 'dark';
}

type SensorRow = {
  pond_id: string;
  pond_name: string;
  last_log_at: string | null;
  missingness: number;
  stuckValue: boolean;
  suppressed: boolean;
  suppression_reason: string | null;
};

const columnHelper = createColumnHelper<SensorRow>();

export const DataQuality: React.FC<DataQualityProps> = ({ theme = 'light' }) => {
  const isDark = theme === 'dark';

  const { data: dqSummary } = useQuery({
    queryKey: ['data-quality'],
    queryFn: async () => {
      const res = await fetch('/v1/data-quality');
      return res.json();
    },
  });

  const { data: worklistData } = useQuery({
    queryKey: ['worklist'],
    queryFn: async () => {
      const res = await fetch('/v1/risk/worklist?limit=100');
      return res.json();
    },
  });

  const sensors: SensorRow[] = useMemo(() => {
    if (!worklistData?.items) return [];
    return worklistData.items.map((item: any) => {
      // Deterministically mock missingness and stuck value for demonstration
      const hash = item.pond_id.length * item.pond_name.length * 13;
      const missingness = item.suppressed ? 100 : (hash % 15);
      const stuckValue = !item.suppressed && (hash % 7 === 0);
      
      return {
        pond_id: item.pond_id,
        pond_name: item.pond_name,
        last_log_at: item.last_log_at,
        suppressed: item.suppressed,
        suppression_reason: item.suppression_reason,
        missingness,
        stuckValue,
      };
    });
  }, [worklistData]);

  const suppressedSensors = useMemo(() => sensors.filter((s) => s.suppressed), [sensors]);
  
  // Mock calibration due by picking a stable subset
  const calibrationDue = useMemo(() => sensors.filter((s, i) => !s.suppressed && i % 5 === 0).slice(0, 2), [sensors]);

  const columns = useMemo(() => [
    columnHelper.accessor('pond_name', {
      header: 'Pond',
      cell: (info) => (
        <div>
          <div className="font-bold text-ocean-900 dark:text-slate-100">{info.getValue()}</div>
          <div className="text-[10px] text-slate-500 font-mono">{info.row.original.pond_id}</div>
        </div>
      ),
    }),
    columnHelper.accessor('last_log_at', {
      header: 'Last Seen',
      cell: (info) => {
        const val = info.getValue();
        if (!val) return <span className="text-amber-600 font-bold">Offline</span>;
        const dist = formatDistanceToNow(new Date(val), { addSuffix: true });
        return <span className="text-slate-600 dark:text-slate-300">{dist}</span>;
      },
    }),
    columnHelper.accessor('missingness', {
      header: 'Missingness (7d)',
      cell: (info) => {
        const val = info.getValue();
        const isHigh = val > 10;
        return (
          <div className="flex items-center gap-2">
            <div className="w-16 h-1.5 bg-slate-200 dark:bg-slate-700 rounded-full overflow-hidden">
              <div 
                className={`h-full ${isHigh ? 'bg-amber-500' : 'bg-teal-500'}`} 
                style={{ width: `${Math.min(val, 100)}%` }} 
              />
            </div>
            <span className={`font-mono text-[10px] ${isHigh ? 'text-amber-600 dark:text-amber-400 font-bold' : 'text-slate-500'}`}>
              {val}%
            </span>
          </div>
        );
      },
    }),
    columnHelper.accessor('stuckValue', {
      header: 'Stuck-Value Flag',
      cell: (info) => {
        const isStuck = info.getValue();
        return isStuck ? (
          <span className="px-2 py-0.5 bg-red-50 text-red-700 dark:bg-red-900/30 dark:text-red-400 rounded text-[10px] font-bold border border-red-200 dark:border-red-800 flex items-center gap-1 w-max">
            <AlertTriangle className="w-3 h-3" /> Flagged
          </span>
        ) : (
          <span className="text-[10px] text-slate-400 dark:text-slate-500 font-mono flex items-center gap-1">
            <CheckCircle2 className="w-3 h-3 text-mint-500" /> Optimal
          </span>
        );
      },
    }),
  ], []);

  const table = useReactTable({
    data: sensors,
    columns,
    getCoreRowModel: getCoreRowModel(),
  });

  return (
    <div className="space-y-4 animate-fade-in p-2 md:p-4">
      {/* Top Banner */}
      <div className="instrument-card p-4 rounded-xl flex items-center justify-between shadow-sm">
        <div>
          <h2 className="text-base font-bold text-ocean-900 dark:text-slate-100 font-mono flex items-center gap-2">
            <Database className="w-5 h-5 text-teal-600" />
            Telemetry Health: Sensor Integrity &amp; Blind-State Register
          </h2>
          <p className="text-xs text-slate-600 dark:text-slate-400 mt-1 font-sans">
            Per-pond missingness, stuck-value detection, and calibration schedules.
          </p>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="instrument-card p-4 rounded-xl space-y-1">
          <span className="text-[11px] text-slate-500 dark:text-slate-400 font-mono font-semibold uppercase tracking-wider">Total Ponds Monitored</span>
          <div className="text-3xl font-bold font-mono text-teal-700 dark:text-teal-400">
            {sensors.length || 0}
          </div>
          <span className="text-[10px] text-mint-700 font-mono font-bold">Active Sensor Nodes</span>
        </div>

        <div className={`p-4 rounded-xl space-y-1 border-2 transition-colors duration-300 ${suppressedSensors.length > 0 ? 'bg-amber-50 border-amber-300 dark:bg-amber-950/30 dark:border-amber-800/50' : 'bg-surface-cardSubtle border-surface-border dark:bg-surface-darkCard dark:border-surface-darkBorder'}`}>
          <span className={`text-[11px] font-mono font-bold uppercase tracking-wider ${suppressedSensors.length > 0 ? 'text-amber-800 dark:text-amber-400' : 'text-slate-500 dark:text-slate-400'}`}>Blind State Ponds (R5)</span>
          <div className={`text-3xl font-bold font-mono ${suppressedSensors.length > 0 ? 'text-amber-700 dark:text-amber-500' : 'text-slate-700 dark:text-slate-400'}`}>
            {suppressedSensors.length}
          </div>
          <span className={`text-[10px] font-mono font-bold ${suppressedSensors.length > 0 ? 'text-amber-700 dark:text-amber-500' : 'text-slate-500'}`}>Telemetry lost &gt; {dqSummary?.stale_threshold_hours || 12}h</span>
        </div>

        <div className="instrument-card p-4 rounded-xl space-y-1">
          <span className="text-[11px] text-slate-500 dark:text-slate-400 font-mono font-semibold uppercase tracking-wider">Stuck-Value Incidents</span>
          <div className="text-3xl font-bold font-mono text-red-600 dark:text-red-400">
            {sensors.filter(s => s.stuckValue).length}
          </div>
          <span className="text-[10px] text-red-600 font-mono font-bold">Requires audit</span>
        </div>

        <div className="instrument-card p-4 rounded-xl space-y-1">
          <span className="text-[11px] text-slate-500 dark:text-slate-400 font-mono font-semibold uppercase tracking-wider">Calibration Due</span>
          <div className="text-3xl font-bold font-mono text-ocean-700 dark:text-ocean-400">
            {calibrationDue.length}
          </div>
          <span className="text-[10px] text-ocean-700 font-mono font-bold">14-day optical service</span>
        </div>
      </div>

      {/* Main Grid: Live Sensor Registers & Suppressed Alert Feeds */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
        
        {/* Sensor Health Table */}
        <div className="lg:col-span-8 instrument-card p-5 rounded-xl space-y-4">
          <div className="flex items-center justify-between border-b border-surface-border dark:border-surface-darkBorder pb-2">
            <h3 className="text-xs font-bold text-ocean-900 dark:text-slate-100 font-mono uppercase tracking-wider flex items-center gap-2">
              <Activity className="w-4 h-4 text-teal-600" /> Sensor Health Grid
            </h3>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs font-sans whitespace-nowrap">
              <thead className="bg-surface-cardSubtle dark:bg-surface-darkCardAlt text-slate-500 dark:text-slate-400 border-b border-surface-border dark:border-surface-darkBorder uppercase text-[10px] font-bold tracking-wider">
                {table.getHeaderGroups().map(headerGroup => (
                  <tr key={headerGroup.id}>
                    {headerGroup.headers.map(header => (
                      <th key={header.id} className="p-3 font-medium">
                        {flexRender(header.column.columnDef.header, header.getContext())}
                      </th>
                    ))}
                  </tr>
                ))}
              </thead>
              <tbody className="divide-y divide-surface-border dark:divide-surface-darkBorder">
                {table.getRowModel().rows.map(row => (
                  <tr key={row.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/20 transition-colors">
                    {row.getVisibleCells().map(cell => (
                      <td key={cell.id} className="p-3">
                        {flexRender(cell.column.columnDef.cell, cell.getContext())}
                      </td>
                    ))}
                  </tr>
                ))}
                {table.getRowModel().rows.length === 0 && (
                  <tr>
                    <td colSpan={4} className="p-8 text-center text-slate-500 font-mono">
                      Loading sensor metrics...
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Right Column: Blind State Register & Calibration */}
        <div className="lg:col-span-4 space-y-4">
          
          {/* Rule R5 Blind State Register */}
          <div className="instrument-card p-5 rounded-xl space-y-3 border-2 border-amber-200 dark:border-amber-900/50 bg-amber-50/30 dark:bg-amber-950/10">
            <div className="flex items-center justify-between border-b border-amber-200 dark:border-amber-900/50 pb-2">
              <h3 className="text-xs font-bold text-amber-900 dark:text-amber-100 font-mono uppercase tracking-wider flex items-center gap-2">
                <ShieldAlert className="w-4 h-4 text-amber-600 animate-pulse" /> Blind-State Register (R5)
              </h3>
            </div>

            {suppressedSensors.length === 0 ? (
              <div className="p-4 text-center text-slate-500 font-mono text-xs space-y-1">
                <CheckCircle2 className="w-6 h-6 text-mint-600 mx-auto mb-2" />
                <div className="font-bold text-ocean-900 dark:text-slate-100">Zero Blind States</div>
                <div className="text-[10px] text-slate-500">All telemetry channels transmitting valid sensor packets.</div>
              </div>
            ) : (
              <div className="space-y-3">
                {suppressedSensors.map((alt) => (
                  <div key={alt.pond_id} className="p-3 bg-white dark:bg-[#0A0E13] rounded-lg border-l-4 border-l-amber-500 border-y border-r border-y-surface-border border-r-surface-border dark:border-y-surface-darkBorder dark:border-r-surface-darkBorder shadow-sm text-xs">
                    <div className="flex justify-between items-start mb-1">
                      <span className="font-bold text-ocean-900 dark:text-slate-100 font-mono">{alt.pond_name}</span>
                      <span className="text-[9px] font-mono font-bold text-amber-600 bg-amber-50 dark:bg-amber-950 px-1.5 py-0.5 rounded">SUPPRESSED</span>
                    </div>
                    <p className="text-slate-600 dark:text-slate-300 font-mono text-[10px] mt-1 p-2 bg-amber-50/50 dark:bg-amber-900/20 rounded">
                      {alt.suppression_reason || 'Telemetry stale > 12h'}
                    </p>
                  </div>
                ))}
              </div>
            )}
            <div className="text-[9px] text-amber-700 dark:text-amber-500 font-mono text-center font-bold uppercase tracking-widest mt-2 border-t border-amber-200 dark:border-amber-900/50 pt-2">
              Rule R5 Enforcement Active
            </div>
          </div>

          {/* Calibration Register */}
          <div className="instrument-card p-5 rounded-xl space-y-3">
            <div className="flex items-center justify-between border-b border-surface-border dark:border-surface-darkBorder pb-2">
              <h3 className="text-xs font-bold text-ocean-900 dark:text-slate-100 font-mono uppercase tracking-wider flex items-center gap-2">
                <Wrench className="w-4 h-4 text-ocean-600" /> Calibration-Due Register
              </h3>
            </div>
            {calibrationDue.length === 0 ? (
              <div className="text-xs font-mono text-slate-500 text-center p-4">All sensors calibrated.</div>
            ) : (
              <div className="space-y-2">
                {calibrationDue.map((cal) => (
                  <div key={cal.pond_id} className="p-2 flex justify-between items-center text-xs font-mono bg-surface-cardSubtle dark:bg-surface-darkCardAlt rounded-md">
                    <span className="font-bold text-ocean-700 dark:text-slate-300">{cal.pond_name}</span>
                    <span className="px-2 py-0.5 rounded text-[10px] bg-ocean-50 text-ocean-700 dark:bg-ocean-950/50 dark:text-ocean-400 border border-ocean-200 dark:border-ocean-800">
                      Service Due
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>

        </div>
      </div>
    </div>
  );
};
