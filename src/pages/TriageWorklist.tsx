import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  AlertCircle,
  ArrowUpRight,
  ArrowDownRight,
  Send,
  CheckCircle2,
  UserPlus,
  Filter,
  ShieldAlert,
  Search,
  ChevronRight,
  Sparkles,
} from 'lucide-react';

interface TriageWorklistProps {
  onSelectPondForDeepDive: (pondId: string) => void;
  onOpenBroadcaster: (pondId: string) => void;
  theme?: 'light' | 'dark';
}

export const TriageWorklist: React.FC<TriageWorklistProps> = ({
  onSelectPondForDeepDive,
  onOpenBroadcaster,
  theme = 'light',
}) => {
  const [selectedPonds, setSelectedPonds] = useState<string[]>([]);
  const [searchTerm, setSearchTerm] = useState('');

  const { data: triageItems = [] } = useQuery({
    queryKey: ['triage-worklist'],
    queryFn: async () => {
      const res = await fetch('/v1/risk/worklist');
      return res.json();
    },
  });

  const handleSelectAll = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.checked) {
      setSelectedPonds(triageItems.map((item: any) => item.pond_id));
    } else {
      setSelectedPonds([]);
    }
  };

  const handleToggleSelect = (pondId: string) => {
    setSelectedPonds((prev) =>
      prev.includes(pondId) ? prev.filter((id) => id !== pondId) : [...prev, pondId]
    );
  };

  const filteredItems = triageItems.filter(
    (item: any) =>
      item.pond_id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.farmer_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      item.district.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-4 animate-fade-in">
      {/* Top Banner - Priority Philosophy */}
      <div className="instrument-card p-4 rounded-xl flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div>
          <h2 className="text-base font-bold text-ocean-900 dark:text-slate-100 font-mono flex items-center gap-2">
            <AlertCircle className="w-4 h-4 text-teal-600" />
            Fleet Triage: Priority Worklist (Risk &times; Biomass-at-Stake)
          </h2>
          <p className="text-xs text-slate-600 dark:text-slate-400 mt-1 font-sans">
            Sorted by urgency velocity: <span className="font-mono text-teal-700 dark:text-teal-400 font-bold">&Delta;24h rate of change</span> prioritizes field interventions.
          </p>
        </div>

        {/* Batch Operations Bar */}
        <div className="flex items-center gap-2 font-mono text-xs">
          <span className="text-slate-500 text-xs">
            Selected: <strong className="text-teal-700 dark:text-teal-400">{selectedPonds.length}</strong>
          </span>
          <button
            disabled={selectedPonds.length === 0}
            onClick={() => onOpenBroadcaster(selectedPonds[0] || 'CBE-003')}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-teal-600 hover:bg-teal-700 text-white font-bold rounded-lg transition-all disabled:opacity-40 shadow-sm active:scale-95"
          >
            <Send className="w-3.5 h-3.5" />
            <span>Broadcast Batch Advisory</span>
          </button>
        </div>
      </div>

      {/* Search & Filter Bar */}
      <div className="flex items-center justify-between gap-3 bg-surface-cardSubtle dark:bg-surface-darkCardAlt p-2.5 rounded-xl border border-surface-border dark:border-surface-darkBorder">
        <div className="relative flex-1 max-w-md">
          <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Search pond ID, lake name, or district..."
            className="w-full pl-9 pr-3 py-1.5 text-xs font-mono bg-white dark:bg-surface-darkCard border border-surface-border dark:border-surface-darkBorder rounded-lg focus:outline-none focus:border-teal-600 text-ocean-900 dark:text-slate-100"
          />
        </div>

        <div className="flex items-center gap-2 text-xs font-mono text-slate-500">
          <span>Showing {filteredItems.length} ponds</span>
        </div>
      </div>

      {/* Table Container */}
      <div className="instrument-card rounded-xl overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs font-mono">
            <thead className="bg-surface-cardSubtle dark:bg-surface-darkCardAlt text-slate-600 dark:text-slate-400 border-b border-surface-border dark:border-surface-darkBorder font-semibold">
              <tr>
                <th className="p-3 w-10">
                  <input
                    type="checkbox"
                    checked={selectedPonds.length > 0 && selectedPonds.length === triageItems.length}
                    onChange={handleSelectAll}
                    className="w-4 h-4 accent-teal-600 rounded cursor-pointer"
                  />
                </th>
                <th className="p-3">Pond &amp; Lake ID</th>
                <th className="p-3">Farmer / Location</th>
                <th className="p-3">Risk Score</th>
                <th className="p-3">&Delta;24h Velocity</th>
                <th className="p-3">Biomass at Stake</th>
                <th className="p-3">Primary SHAP Driver</th>
                <th className="p-3 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-border dark:divide-surface-darkBorder bg-white dark:bg-surface-darkCard">
              {filteredItems.map((item: any) => {
                const isSelected = selectedPonds.includes(item.pond_id);
                const isCritical = item.risk >= 0.7;
                const isWarning = item.risk >= 0.5 && item.risk < 0.7;

                return (
                  <tr
                    key={item.pond_id}
                    className={`hover:bg-surface-cardSubtle dark:hover:bg-surface-darkCardAlt transition-colors ${
                      isSelected ? 'bg-teal-50/50 dark:bg-teal-950/20' : ''
                    }`}
                  >
                    <td className="p-3">
                      <input
                        type="checkbox"
                        checked={isSelected}
                        onChange={() => handleToggleSelect(item.pond_id)}
                        className="w-4 h-4 accent-teal-600 rounded cursor-pointer"
                      />
                    </td>
                    <td className="p-3 font-bold text-ocean-900 dark:text-slate-100">
                      <div>{item.pond_id}</div>
                      <div className="text-[10px] text-slate-500 font-normal">{item.species}</div>
                    </td>
                    <td className="p-3 text-slate-700 dark:text-slate-300">
                      <div>{item.farmer_name}</div>
                      <div className="text-[10px] text-slate-500">{item.district}</div>
                    </td>
                    <td className="p-3">
                      <span
                        className={`inline-block px-2 py-0.5 rounded-full font-bold text-xs border ${
                          isCritical
                            ? 'bg-risk-criticalBg text-risk-critical border-risk-criticalBorder'
                            : isWarning
                            ? 'bg-risk-warningBg text-risk-warning border-risk-warningBorder'
                            : 'bg-risk-healthyBg text-mint-700 border-risk-healthyBorder'
                        }`}
                      >
                        {item.risk.toFixed(2)}
                      </span>
                    </td>
                    <td className="p-3">
                      <span
                        className={`flex items-center gap-1 font-bold ${
                          item.risk_delta_24h > 0 ? 'text-risk-critical' : 'text-mint-700'
                        }`}
                      >
                        {item.risk_delta_24h > 0 ? (
                          <ArrowUpRight className="w-3.5 h-3.5" />
                        ) : (
                          <ArrowDownRight className="w-3.5 h-3.5" />
                        )}
                        <span>{item.risk_delta_24h > 0 ? `+${item.risk_delta_24h.toFixed(2)}` : item.risk_delta_24h.toFixed(2)}</span>
                      </span>
                    </td>
                    <td className="p-3 text-slate-700 dark:text-slate-300 font-semibold">
                      {item.biomass_kg.toLocaleString()} kg
                    </td>
                    <td className="p-3 text-slate-600 dark:text-slate-400 text-[11px]">
                      {item.primary_driver || 'DO Rapid Drop Velocity'}
                    </td>
                    <td className="p-3 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <button
                          onClick={() => onSelectPondForDeepDive(item.pond_id)}
                          className="px-2.5 py-1 bg-surface-cardSubtle hover:bg-teal-50 dark:bg-surface-darkCardAlt dark:hover:bg-teal-950 text-teal-700 dark:text-teal-300 rounded border border-surface-border dark:border-surface-darkBorder font-bold text-[11px] transition-all"
                        >
                          3D Twin
                        </button>
                        <button
                          onClick={() => onOpenBroadcaster(item.pond_id)}
                          className="p-1 text-slate-500 hover:text-teal-600 rounded transition-colors"
                          title="Compose Advisory"
                        >
                          <Send className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
