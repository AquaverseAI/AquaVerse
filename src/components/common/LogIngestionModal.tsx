import React, { useState } from 'react';
import { Database, Plus, X, CheckCircle2, AlertCircle } from 'lucide-react';
import { logsApi } from '../../api/client';

interface LogIngestionModalProps {
  pondId: string;
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: () => void;
}

export const LogIngestionModal: React.FC<LogIngestionModalProps> = ({ pondId, isOpen, onClose, onSuccess }) => {
  const [doVal, setDoVal] = useState('4.8');
  const [phVal, setPhVal] = useState('8.1');
  const [tempVal, setTempVal] = useState('28.5');
  const [tanVal, setTanVal] = useState('0.15');
  const [salinityVal, setSalinityVal] = useState('12.0');
  const [source, setSource] = useState<'manual' | 'iot_sensor' | 'drone_flyover'>('manual');
  const [notes, setNotes] = useState('Routine morning water sample titration');
  const [isLoading, setIsLoading] = useState(false);
  const [resultMsg, setResultMsg] = useState('');

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setResultMsg('');

    try {
      const res = await logsApi.ingestLog({
        pond_id: pondId,
        timestamp: new Date().toISOString(),
        do_mg_l: parseFloat(doVal),
        ph: parseFloat(phVal),
        temp_c: parseFloat(tempVal),
        tan_mg_l: parseFloat(tanVal),
        salinity_ppt: parseFloat(salinityVal),
        notes,
        source,
      });

      setResultMsg(`Log ingested successfully! Log ID: ${res.log_id}`);
      if (onSuccess) onSuccess();
      setTimeout(() => {
        onClose();
        setResultMsg('');
      }, 1400);
    } catch (err: any) {
      setResultMsg(`Failed to ingest log: ${err.message}`);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-ocean-950/50 backdrop-blur-xs flex items-center justify-center p-4">
      <div className="instrument-card rounded-2xl max-w-lg w-full p-6 shadow-card-elevated space-y-5 animate-fade-in">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-surface-border dark:border-surface-darkBorder pb-3">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-teal-600 flex items-center justify-center text-white font-bold">
              <Database className="w-4 h-4" />
            </div>
            <div>
              <h3 className="font-bold text-ocean-900 dark:text-slate-100 text-sm font-mono">
                Water-Quality Telemetry Ingestion
              </h3>
              <p className="text-xs text-slate-500 font-mono">Pond: {pondId} &bull; TimescaleDB Ingest</p>
            </div>
          </div>
          <button onClick={onClose} className="p-1 text-slate-400 hover:text-ocean-900 dark:hover:text-slate-200">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Status Message */}
        {resultMsg && (
          <div className="p-3 bg-mint-50 border border-mint-200 text-mint-800 rounded-lg text-xs font-mono flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 text-mint-600 shrink-0" />
            <span>{resultMsg}</span>
          </div>
        )}

        {/* Ingestion Form */}
        <form onSubmit={handleSubmit} className="space-y-4 text-xs font-mono">
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1">
              <label className="text-slate-600 dark:text-slate-300">Dissolved Oxygen (mg/L)</label>
              <input
                type="number"
                step="0.1"
                value={doVal}
                onChange={(e) => setDoVal(e.target.value)}
                required
                className="w-full bg-surface-cardSubtle dark:bg-surface-darkCardAlt border border-surface-border dark:border-surface-darkBorder rounded-lg p-2 font-mono text-ocean-900 dark:text-slate-100 focus:outline-none focus:border-teal-600"
              />
            </div>
            <div className="space-y-1">
              <label className="text-slate-600 dark:text-slate-300">pH Level</label>
              <input
                type="number"
                step="0.1"
                value={phVal}
                onChange={(e) => setPhVal(e.target.value)}
                required
                className="w-full bg-surface-cardSubtle dark:bg-surface-darkCardAlt border border-surface-border dark:border-surface-darkBorder rounded-lg p-2 font-mono text-ocean-900 dark:text-slate-100 focus:outline-none focus:border-teal-600"
              />
            </div>
            <div className="space-y-1">
              <label className="text-slate-600 dark:text-slate-300">Temperature (°C)</label>
              <input
                type="number"
                step="0.1"
                value={tempVal}
                onChange={(e) => setTempVal(e.target.value)}
                required
                className="w-full bg-surface-cardSubtle dark:bg-surface-darkCardAlt border border-surface-border dark:border-surface-darkBorder rounded-lg p-2 font-mono text-ocean-900 dark:text-slate-100 focus:outline-none focus:border-teal-600"
              />
            </div>
            <div className="space-y-1">
              <label className="text-slate-600 dark:text-slate-300">TAN Ammonia (mg/L)</label>
              <input
                type="number"
                step="0.01"
                value={tanVal}
                onChange={(e) => setTanVal(e.target.value)}
                required
                className="w-full bg-surface-cardSubtle dark:bg-surface-darkCardAlt border border-surface-border dark:border-surface-darkBorder rounded-lg p-2 font-mono text-ocean-900 dark:text-slate-100 focus:outline-none focus:border-teal-600"
              />
            </div>
          </div>

          <div className="space-y-1">
            <label className="text-slate-600 dark:text-slate-300">Telemetry Data Source</label>
            <select
              value={source}
              onChange={(e) => setSource(e.target.value as any)}
              className="w-full bg-surface-cardSubtle dark:bg-surface-darkCardAlt border border-surface-border dark:border-surface-darkBorder rounded-lg p-2 font-mono text-ocean-900 dark:text-slate-100 focus:outline-none"
            >
              <option value="manual">Manual Entry (Handheld Probe / Titration)</option>
              <option value="iot_sensor">IoT Solar Buoy Telemetry</option>
              <option value="drone_flyover">Drone Multi-spectral Flyover</option>
            </select>
          </div>

          <div className="space-y-1">
            <label className="text-slate-600 dark:text-slate-300">Field Notes / Observations</label>
            <input
              type="text"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              className="w-full bg-surface-cardSubtle dark:bg-surface-darkCardAlt border border-surface-border dark:border-surface-darkBorder rounded-lg p-2 font-mono text-ocean-900 dark:text-slate-100 focus:outline-none focus:border-teal-600"
            />
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="w-full py-2.5 bg-teal-600 hover:bg-teal-700 text-white font-bold text-xs rounded-xl shadow-sm transition-all flex items-center justify-center gap-2 font-mono active:scale-95"
          >
            <Plus className="w-4 h-4" />
            <span>Ingest Telemetry Log to Database</span>
          </button>
        </form>
      </div>
    </div>
  );
};
