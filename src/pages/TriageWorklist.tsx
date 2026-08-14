import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { AlertCircle, ArrowUpRight, ArrowDownRight, Send, CheckCircle2, UserPlus, Filter, ShieldAlert } from 'lucide-react';

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
    <div className="space-y-4">
      {/* Top Banner - Explaining Δ24h Priority Philosophy */}
      <div className="glass-panel p-4 rounded-xl border border-blue-200 dark:border-amber-900/40 bg-gradient-to-r from-blue-50 via-white to-cyan-50 dark:from-slate-900 dark:via-slate-900 dark:to-amber-950/30 flex items-center justify-between shadow-sm">
        <div>
          <h2 className="text-sm font-bold text-blue-900 dark:text-amber-300 font-mono flex items-center gap-2">
            <AlertCircle className="w-4 h-4 text-blue-600 dark:text-amber-400" /> Screen 2: Analyst Triage Worklist
          </h2>
          <p className="text-xs text-slate-700 dark:text-slate-300 mt-0.5 font-sans">
            Sorted by <span className="font-mono text-blue-700 dark:text-cyan-300 font-bold">Risk × Biomass-at-Stake</span>.
            <span className="text-blue-900 dark:text-amber-300 font-bold ml-1">
              Δ24h matters more than static risk level — a pond moving 0.3 &rarr; 0.6 needs a call today; a pond sitting at 0.7 for a fortnight does not.
            </span>
          </p>
        </div>

        {/* Bulk Action Controls */}
        <div className="flex items-center gap-2">
          <button
            disabled={selectedPonds.length === 0}
            onClick={() => onOpenBroadcaster(selectedPonds[0] || 'NGP-004')}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-blue-600 hover:bg-blue-700 disabled:opacity-40 disabled:cursor-not-allowed text-white text-xs font-semibold rounded-lg transition-all shadow-sm font-mono"
          >
            <Send className="w-3.5 h-3.5" />
            Send Bulk Advisory ({selectedPonds.length})
          </button>
          <button
            disabled={selectedPonds.length === 0}
            onClick={() => alert(`Assigned ${selectedPonds.length} ponds to Extension Officer Vijay.`)}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-white hover:bg-slate-100 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 text-xs font-semibold rounded-lg border border-slate-300 dark:border-slate-700 transition-all font-mono"
          >
            <UserPlus className="w-3.5 h-3.5 text-blue-600 dark:text-cyan-400" />
            Assign Officer
          </button>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="glass-panel p-3 rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 flex items-center justify-between gap-4 text-xs shadow-sm">
        <input
          type="text"
          placeholder="Search by Pond ID, Farmer Name, or District..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="bg-slate-50 dark:bg-slate-900 text-slate-800 dark:text-slate-200 border border-slate-300 dark:border-slate-700 rounded-lg px-3 py-1.5 w-80 focus:outline-none focus:border-blue-600 font-mono"
        />
        <div className="text-slate-600 dark:text-slate-400 font-mono text-[11px] font-medium">
          Showing <span className="text-blue-600 dark:text-cyan-400 font-bold">{filteredItems.length}</span> prioritized ponds
        </div>
      </div>

      {/* TanStack Table Virtualized Worklist */}
      <div className="glass-panel rounded-xl border border-slate-200 dark:border-slate-800 overflow-hidden bg-white dark:bg-slate-900 shadow-sm">
        <table className="w-full text-left text-xs text-slate-800 dark:text-slate-300">
          <thead className="bg-slate-50 dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800 font-mono text-[11px] text-slate-600 dark:text-slate-400 uppercase font-semibold">
            <tr>
              <th className="p-3 w-10 text-center">
                <input
                  type="checkbox"
                  onChange={handleSelectAll}
                  checked={selectedPonds.length === triageItems.length && triageItems.length > 0}
                  className="accent-blue-600 rounded cursor-pointer"
                />
              </th>
              <th className="p-3">Pond ID &amp; Farmer</th>
              <th className="p-3">Species / DOC</th>
              <th className="p-3">Biomass at Stake</th>
              <th className="p-3">Current Risk</th>
              <th className="p-3">Δ24h Risk Delta</th>
              <th className="p-3">Top Attributed Driver (Plain Words)</th>
              <th className="p-3">Data Health</th>
              <th className="p-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-200 dark:divide-slate-800/60 font-sans">
            {filteredItems.map((item: any) => {
              const isSelected = selectedPonds.includes(item.pond_id);
              const isDeltaCritical = item.risk_delta_24h >= 0.15;
              const isBlind = item.blind_state;

              return (
                <tr
                  key={item.pond_id}
                  className={`hover:bg-blue-50/50 dark:hover:bg-slate-800/50 transition-colors ${
                    isSelected ? 'bg-blue-50 dark:bg-cyan-950/30' : ''
                  }`}
                >
                  <td className="p-3 text-center">
                    <input
                      type="checkbox"
                      checked={isSelected}
                      onChange={() => handleToggleSelect(item.pond_id)}
                      className="accent-blue-600 rounded cursor-pointer"
                    />
                  </td>
                  <td className="p-3">
                    <button
                      onClick={() => onSelectPondForDeepDive(item.pond_id)}
                      className="font-mono font-bold text-blue-600 dark:text-cyan-400 hover:underline block"
                    >
                      {item.pond_id}
                    </button>
                    <span className="text-slate-500 dark:text-slate-400 text-[11px] font-medium">{item.farmer_name}</span>
                  </td>
                  <td className="p-3">
                    <div className="font-medium">{item.species}</div>
                    <span className="text-[10px] font-mono text-slate-500">DOC {item.doc} days</span>
                  </td>
                  <td className="p-3 font-mono font-bold text-slate-800 dark:text-slate-200">
                    {(item.biomass_kg / 1000).toFixed(1)} MT
                    <div className="text-[10px] text-slate-500 font-sans font-normal">Score: {item.risk_biomass_score}</div>
                  </td>
                  <td className="p-3 font-mono font-bold">
                    {isBlind ? (
                      <span className="px-2 py-0.5 bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 rounded text-[11px] border border-slate-200 dark:border-transparent">
                        -- (Rule R5)
                      </span>
                    ) : (
                      <span
                        className={`px-2 py-0.5 rounded text-[11px] font-bold ${
                          item.risk > 0.65
                            ? 'bg-red-100 text-red-700 border border-red-200 dark:bg-red-950 dark:text-red-300 dark:border-red-800'
                            : item.risk > 0.35
                            ? 'bg-amber-100 text-amber-800 border border-amber-200 dark:bg-amber-950 dark:text-amber-300 dark:border-amber-800'
                            : 'bg-emerald-100 text-emerald-800 border border-emerald-200 dark:bg-emerald-950 dark:text-emerald-300 dark:border-emerald-800'
                        }`}
                      >
                        {item.risk.toFixed(2)}
                      </span>
                    )}
                  </td>
                  <td className="p-3 font-mono font-bold">
                    {isBlind ? (
                      <span className="text-slate-400 text-[11px]">--</span>
                    ) : (
                      <span
                        className={`flex items-center gap-0.5 ${
                          isDeltaCritical
                            ? 'text-red-600 dark:text-red-400 font-extrabold animate-pulse'
                            : item.risk_delta_24h > 0
                            ? 'text-amber-600 dark:text-amber-400'
                            : 'text-emerald-600 dark:text-emerald-400'
                        }`}
                      >
                        {item.risk_delta_24h > 0 ? (
                          <ArrowUpRight className="w-3.5 h-3.5" />
                        ) : (
                          <ArrowDownRight className="w-3.5 h-3.5" />
                        )}
                        {item.risk_delta_24h > 0 ? `+${item.risk_delta_24h.toFixed(2)}` : item.risk_delta_24h.toFixed(2)}
                      </span>
                    )}
                  </td>
                  <td className="p-3 text-slate-700 dark:text-slate-200 max-w-xs font-sans text-xs font-normal">
                    {item.top_driver}
                  </td>
                  <td className="p-3">
                    {isBlind ? (
                      <span className="px-2 py-0.5 bg-amber-50 text-amber-800 dark:bg-slate-800 dark:text-slate-400 rounded text-[10px] flex items-center gap-1 font-mono border border-amber-200 dark:border-transparent font-bold">
                        <ShieldAlert className="w-3 h-3 text-amber-600 dark:text-amber-400" /> Blind
                      </span>
                    ) : (
                      <span className="px-2 py-0.5 bg-emerald-50 text-emerald-800 border border-emerald-200 dark:bg-emerald-950 dark:text-emerald-300 dark:border-transparent rounded text-[10px] font-mono font-bold">
                        {item.data_health}
                      </span>
                    )}
                  </td>
                  <td className="p-3 text-right">
                    <button
                      onClick={() => onSelectPondForDeepDive(item.pond_id)}
                      className="px-2.5 py-1 bg-blue-50 hover:bg-blue-100 dark:bg-slate-800 dark:hover:bg-slate-700 text-blue-700 dark:text-cyan-300 text-[11px] font-bold rounded border border-blue-200 dark:border-slate-700 transition-all font-mono shadow-sm"
                    >
                      Deep Dive &rarr;
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
};
