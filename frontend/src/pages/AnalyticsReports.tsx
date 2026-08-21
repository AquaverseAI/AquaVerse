import React, { useState, useEffect } from 'react';
import ReactECharts from 'echarts-for-react';
import { FileText, Download, BarChart2, TrendingUp, Activity, CheckCircle2, Loader2, AlertCircle } from 'lucide-react';

interface AnalyticsReportsProps {
  theme?: 'light' | 'dark';
}

type JobState = {
  jobId: string | null;
  status: 'idle' | 'queued' | 'in_progress' | 'completed' | 'failed';
  downloadUrl: string | null;
  error: string | null;
};

export const AnalyticsReports: React.FC<AnalyticsReportsProps> = ({ theme = 'light' }) => {
  const isDark = theme === 'dark';
  const [exportJob, setExportJob] = useState<JobState>({ jobId: null, status: 'idle', downloadUrl: null, error: null });

  // Async polling effect for export jobs
  useEffect(() => {
    let interval: NodeJS.Timeout;
    
    if (exportJob.jobId && (exportJob.status === 'queued' || exportJob.status === 'in_progress')) {
      interval = setInterval(async () => {
        try {
          const res = await fetch(`/v1/reports/export/${exportJob.jobId}`);
          const data = await res.json();
          if (data.status === 'completed') {
            setExportJob(prev => ({ ...prev, status: 'completed', downloadUrl: data.download_url }));
            clearInterval(interval);
          } else if (data.status === 'failed') {
            setExportJob(prev => ({ ...prev, status: 'failed', error: data.error || 'Export failed.' }));
            clearInterval(interval);
          } else {
            setExportJob(prev => ({ ...prev, status: data.status }));
          }
        } catch (e) {
          // keep polling
        }
      }, 2000);
    }
    
    return () => clearInterval(interval);
  }, [exportJob.jobId, exportJob.status]);

  const handleExport = async (fmt: 'pdf' | 'xlsx') => {
    try {
      setExportJob({ jobId: null, status: 'queued', downloadUrl: null, error: null });
      const res = await fetch(`/v1/reports/export?format=${fmt}`);
      const data = await res.json();
      if (data.job_id) {
        setExportJob({ jobId: data.job_id, status: data.status, downloadUrl: null, error: null });
      } else {
        throw new Error('No job ID returned');
      }
    } catch (e) {
      setExportJob({ jobId: null, status: 'failed', downloadUrl: null, error: 'Network error initiating export.' });
    }
  };

  const fcrOption = {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      backgroundColor: isDark ? '#0e2231' : '#ffffff',
      borderColor: isDark ? 'rgba(255,255,255,0.1)' : '#dce8ec',
      textStyle: { color: isDark ? '#f8fafc' : '#0f3f5c', fontFamily: 'monospace', fontSize: 11 },
    },
    grid: { left: '3%', right: '4%', bottom: '10%', top: '15%', containLabel: true },
    xAxis: {
      type: 'category',
      data: ['1.0-1.2', '1.2-1.4', '1.4-1.6 (Opt)', '1.6-1.8', '1.8-2.0', '> 2.0'],
      axisLabel: { color: isDark ? '#cbd5e1' : '#154c6e', fontSize: 10, fontFamily: 'monospace', fontWeight: 'bold' },
    },
    yAxis: {
      type: 'value',
      name: 'Number of Ponds',
      axisLabel: { color: isDark ? '#64748b' : '#6c8899', fontSize: 10, fontFamily: 'monospace' },
      splitLine: { lineStyle: { color: isDark ? 'rgba(255,255,255,0.07)' : '#e8f1f4' } },
    },
    series: [
      {
        name: 'Ponds Count',
        type: 'bar',
        barWidth: '45%',
        data: [
          { value: 12, itemStyle: { color: isDark ? '#4fbfa0' : '#059669', borderRadius: [4, 4, 0, 0] } },
          { value: 45, itemStyle: { color: isDark ? '#4fbfa0' : '#059669', borderRadius: [4, 4, 0, 0] } },
          { value: 38, itemStyle: { color: isDark ? '#1f8aa6' : '#0284c7', borderRadius: [4, 4, 0, 0] } },
          { value: 10, itemStyle: { color: isDark ? '#e8a33d' : '#d97706', borderRadius: [4, 4, 0, 0] } },
          { value: 4, itemStyle: { color: isDark ? '#dc3545' : '#dc2626', borderRadius: [4, 4, 0, 0] } },
          { value: 1, itemStyle: { color: isDark ? '#dc3545' : '#dc2626', borderRadius: [4, 4, 0, 0] } },
        ],
        markArea: {
          itemStyle: { color: isDark ? 'rgba(220, 53, 69, 0.15)' : 'rgba(220, 38, 38, 0.1)' },
          data: [
            [
              { name: 'Bottom Quartile (Target for Extension)', xAxis: '1.8-2.0' },
              { xAxis: '> 2.0' }
            ]
          ],
          label: { position: 'top', color: isDark ? '#dc3545' : '#dc2626', fontWeight: 'bold', fontFamily: 'monospace', fontSize: 10 }
        }
      },
    ],
  };

  const diseaseIncidenceOption = {
    backgroundColor: 'transparent',
    tooltip: {
      trigger: 'axis',
      backgroundColor: isDark ? '#0e2231' : '#ffffff',
      borderColor: isDark ? 'rgba(255,255,255,0.1)' : '#dce8ec',
      textStyle: { color: isDark ? '#f8fafc' : '#0f3f5c', fontFamily: 'monospace', fontSize: 11 },
    },
    legend: {
      data: ['Current Season WSSV Incidence', 'Historical Baseline (5yr Avg)'],
      textStyle: { color: isDark ? '#cbd5e1' : '#154c6e', fontSize: 11, fontFamily: 'monospace', fontWeight: 'bold' },
    },
    grid: { left: '3%', right: '4%', bottom: '10%', top: '15%', containLabel: true },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
      axisLabel: { color: isDark ? '#64748b' : '#6c8899', fontSize: 10, fontFamily: 'monospace' },
    },
    yAxis: {
      type: 'value',
      name: 'Incidence Cases',
      axisLabel: { color: isDark ? '#64748b' : '#6c8899', fontSize: 10, fontFamily: 'monospace' },
      splitLine: { lineStyle: { color: isDark ? 'rgba(255,255,255,0.07)' : '#e8f1f4' } },
    },
    series: [
      {
        name: 'Current Season WSSV Incidence',
        type: 'line',
        data: [2, 3, 6, 14, 25, 42, 30, 22, 10, 0, 0, 0],
        itemStyle: { color: isDark ? '#dc3545' : '#dc2626' },
        lineStyle: { width: 3 },
        areaStyle: { color: isDark ? 'rgba(220, 53, 69, 0.2)' : 'rgba(220, 38, 38, 0.15)' },
        smooth: true,
      },
      {
        name: 'Historical Baseline (5yr Avg)',
        type: 'line',
        data: [1, 2, 4, 10, 18, 30, 25, 18, 8, 4, 2, 1],
        lineStyle: { color: isDark ? '#64748b' : '#94a3b8', type: 'dashed', width: 2 },
        symbol: 'none',
        smooth: true,
      },
    ],
  };

  return (
    <div className="space-y-4 animate-fade-in p-2 md:p-4">
      {/* Top Banner & Export Actions */}
      <div className="instrument-card p-4 rounded-xl flex flex-col md:flex-row items-start md:items-center justify-between gap-4 shadow-sm">
        <div>
          <h2 className="text-base font-bold text-ocean-900 dark:text-slate-100 font-mono flex items-center gap-2">
            <FileText className="w-5 h-5 text-teal-600" />
            Analytics &amp; State Government Reporting
          </h2>
          <p className="text-xs text-slate-600 dark:text-slate-400 mt-1 font-sans">
            Feed Conversion Ratio (FCR) benchmark distribution, disease incidence baselines, and compliant government PDF exports.
          </p>
        </div>

        <div className="flex flex-col items-end gap-2">
          <div className="flex items-center gap-2 font-mono text-xs">
            <button
              onClick={() => handleExport('pdf')}
              disabled={exportJob.status === 'queued' || exportJob.status === 'in_progress'}
              className="flex items-center gap-1.5 px-4 py-2 bg-ocean-900 hover:bg-ocean-800 disabled:opacity-50 text-white font-bold rounded-lg shadow-sm transition-all active:scale-95"
            >
              <Download className="w-4 h-4" />
              <span>Official Letterhead PDF</span>
            </button>
            <button
              onClick={() => handleExport('xlsx')}
              disabled={exportJob.status === 'queued' || exportJob.status === 'in_progress'}
              className="flex items-center gap-1.5 px-4 py-2 bg-surface-cardSubtle hover:bg-teal-50 dark:bg-surface-darkCardAlt dark:hover:bg-teal-950 disabled:opacity-50 text-teal-700 dark:text-teal-300 font-bold rounded-lg border border-surface-border dark:border-surface-darkBorder transition-all shadow-sm active:scale-95"
            >
              <Download className="w-4 h-4" />
              <span>Excel Raw Dataset</span>
            </button>
          </div>
          
          {/* Status Tracker */}
          {exportJob.status !== 'idle' && (
            <div className="text-[10px] font-mono font-bold flex items-center gap-1.5 px-2 py-1 rounded bg-slate-50 dark:bg-slate-800/50">
              {(exportJob.status === 'queued' || exportJob.status === 'in_progress') && (
                <span className="flex items-center gap-1.5 text-amber-600 dark:text-amber-400"><Loader2 className="w-3 h-3 animate-spin" /> Generating {exportJob.jobId}...</span>
              )}
              {exportJob.status === 'completed' && (
                <span className="flex items-center gap-1.5 text-mint-600 dark:text-mint-400"><CheckCircle2 className="w-3 h-3" /> Ready: <a href={exportJob.downloadUrl!} target="_blank" rel="noreferrer" className="underline hover:text-mint-700">Download</a></span>
              )}
              {exportJob.status === 'failed' && (
                <span className="flex items-center gap-1.5 text-red-600 dark:text-red-400"><AlertCircle className="w-3 h-3" /> {exportJob.error}</span>
              )}
            </div>
          )}
        </div>
      </div>

      {/* Executive Summary Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="instrument-card p-4 rounded-xl space-y-1">
          <span className="text-[11px] text-slate-500 dark:text-slate-400 font-mono font-semibold uppercase tracking-wider">Total Fleet Biomass</span>
          <div className="text-3xl font-bold font-mono text-teal-700 dark:text-teal-400">19.4 MT</div>
          <span className="text-[10px] text-mint-700 font-mono font-bold">+2.4 MT vs Last Month</span>
        </div>

        <div className="instrument-card p-4 rounded-xl space-y-1">
          <span className="text-[11px] text-slate-500 dark:text-slate-400 font-mono font-semibold uppercase tracking-wider">Average Fleet FCR</span>
          <div className="text-3xl font-bold font-mono text-purple-700 dark:text-purple-400">1.48</div>
          <span className="text-[10px] text-purple-700 font-mono font-bold">Optimal Target Bracket</span>
        </div>

        <div className="instrument-card p-4 rounded-xl space-y-1">
          <span className="text-[11px] text-slate-500 dark:text-slate-400 font-mono font-semibold uppercase tracking-wider">Disease Incidence</span>
          <div className="text-3xl font-bold font-mono text-red-600 dark:text-red-400">42 Cases</div>
          <span className="text-[10px] text-red-600 font-mono font-bold">+12 vs Historic Baseline</span>
        </div>

        <div className="instrument-card p-4 rounded-xl space-y-1">
          <span className="text-[11px] text-slate-500 dark:text-slate-400 font-mono font-semibold uppercase tracking-wider">State Economic Value</span>
          <div className="text-3xl font-bold font-mono text-ocean-700 dark:text-ocean-400">&#8377; 87.3L</div>
          <span className="text-[10px] text-ocean-700 font-mono font-bold">Current standing crop</span>
        </div>
      </div>

      {/* Main Analytics Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="instrument-card p-5 rounded-xl space-y-3">
          <div className="flex justify-between items-center border-b border-surface-border dark:border-surface-darkBorder pb-2">
            <h3 className="text-xs font-bold text-ocean-900 dark:text-slate-100 font-mono uppercase tracking-wider flex items-center gap-2">
              <BarChart2 className="w-4 h-4 text-teal-600" /> FCR Benchmark Distribution
            </h3>
            <span className="text-[10px] font-mono text-slate-500">Trailing 90 Days</span>
          </div>

          <ReactECharts option={fcrOption} style={{ height: '320px' }} />

          <p className="text-xs text-slate-600 dark:text-slate-400 font-sans">
            Lower FCR reflects optimal biomass feed assimilation. The bottom quartile (FCR &gt; 1.8) is automatically highlighted for priority targeting by on-ground extension officers.
          </p>
        </div>

        <div className="instrument-card p-5 rounded-xl space-y-3">
          <div className="flex justify-between items-center border-b border-surface-border dark:border-surface-darkBorder pb-2">
            <h3 className="text-xs font-bold text-red-700 dark:text-red-400 font-mono uppercase tracking-wider flex items-center gap-2">
              <Activity className="w-4 h-4 text-red-600" /> Seasonal Disease Incidence (WSSV)
            </h3>
            <span className="text-[10px] font-mono text-slate-500">Year-to-Date vs Baseline</span>
          </div>

          <ReactECharts option={diseaseIncidenceOption} style={{ height: '320px' }} />

          <p className="text-xs text-slate-600 dark:text-slate-400 font-sans">
            Tracks confirmed White Spot Syndrome Virus (WSSV) cases against the 5-year historical baseline to detect epidemic outbreaks early in the season.
          </p>
        </div>
      </div>
    </div>
  );
};
