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
  const [notes, setNotes] = useState('Morning routine water sample test');
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
      }, 1500);
    } catch (err: any) {
      setResultMsg(`Failed to ingest log: ${err.message}`);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl max-w-lg w-full p-6 shadow-2xl space-y-5 animate-in fade-in zoom-in-95 duration-200">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-800 pb-3">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-emerald-600 flex items-center justify-center text-white font-bold">
              <Database className="w-4 h-4" />
            </div>
            <div>
              <h3 className="font-bold text-slate-900 dark:text-slate-100 text-sm">
                Water-Quality Log Ingestion (/v1/logs)
              </h3>
              <p className="text-xs text-slate-500 font-mono">Pond ID: {pondId} • TimescaleDB Telemetry Ingest</p>
            </div>
          </div>
          <button onClick={onClose} className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Status Message */}
        {resultMsg && (
          <div className="p-3 bg-emerald-50 dark:bg-emerald-950/80 border border-emerald-200 dark:border-emerald-800 text-emerald-800 dark:text-emerald-300 rounded-xl text-xs font-mono flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 text-emerald-600" />
            <span>{resultMsg}</span>
          </div>
        )}

        {/* Ingestion Form */}
        <form onSubmit={handleSubmit} className="space-y-4 text-xs font-mono">
          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1">
              <label className="font-semibold text-slate-700 dark:text-slate-300">Dissolved Oxygen (mg/L)</label>
              <input
                type="number"
                step="0.1"
                value={doVal}
                onChange={(e) => setDoVal(e.target.value)}
                required
                className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-300 dark:border-slate-700 rounded-lg p-2 font-mono"
              />
            </div>
            <div className="space-y-1">
              <label className="font-semibold text-slate-700 dark:text-slate-300">pH Level</label>
              <input
                type="number"
                step="0.1"
                value={phVal}
                onChange={(e) => setPhVal(e.target.value)}
                required
                className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-300 dark:border-slate-700 rounded-lg p-2 font-mono"
              />
            </div>
            <div className="space-y-1">
              <label className="font-semibold text-slate-700 dark:text-slate-300">Temperature (°C)</label>
              <input
                type="number"
                step="0.1"
                value={tempVal}
                onChange={(e) => setTempVal(e.target.value)}
                required
                className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-300 dark:border-slate-700 rounded-lg p-2 font-mono"
              />
            </div>
            <div className="space-y-1">
              <label className="font-semibold text-slate-700 dark:text-slate-300">TAN Ammonia (mg/L)</label>
              <input
                type="number"
                step="0.01"
                value={tanVal}
                onChange={(e) => setTanVal(e.target.value)}
                required
                className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-300 dark:border-slate-700 rounded-lg p-2 font-mono"
              />
            </div>
          </div>

          <div className="space-y-1">
            <label className="font-semibold text-slate-700 dark:text-slate-300">Telemetry Data Source</label>
            <select
              value={source}
              onChange={(e) => setSource(e.target.value as any)}
              className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-300 dark:border-slate-700 rounded-lg p-2 font-mono"
            >
              <option value="manual">Manual Entry (Handheld Probe / Titration)</option>
              <option value="iot_sensor">IoT Solar Buoy Telemetry</option>
              <option value="drone_flyover">Drone Multi-spectral Flyover</option>
            </select>
          </div>

          <div className="space-y-1">
            <label className="font-semibold text-slate-700 dark:text-slate-300">Field Notes / Observations</label>
            <input
              type="text"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-300 dark:border-slate-700 rounded-lg p-2 font-mono"
            />
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="w-full py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-xl shadow-md transition-all flex items-center justify-center gap-2 font-sans"
          >
            <Plus className="w-4 h-4" />
            <span>Ingest Telemetry Log to Database</span>
          </button>
        </form>
      </div>
    </div>
  );
};
