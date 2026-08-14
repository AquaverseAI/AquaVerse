import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Radio, Send, Languages, Users, ShieldAlert } from 'lucide-react';

interface AdvisoryBroadcasterProps {
  initialPondId?: string;
  theme?: 'light' | 'dark';
}

export const AdvisoryBroadcaster: React.FC<AdvisoryBroadcasterProps> = ({ initialPondId, theme = 'light' }) => {
  const [textEn, setTextEn] = useState(
    'Monsoon rainfall expected in Nagapattinam. Monitor pH drop below 7.5 and maintain alkalinity above 100 mg/L by applying 15 kg/ha agricultural lime.'
  );
  const [targetSegment, setTargetSegment] = useState('Nagapattinam Vannamei Farmers');
  const [isApproved, setIsApproved] = useState(false);
  const [targetLang, setTargetLang] = useState<'ta' | 'te' | 'hi'>('ta');

  const { data: translationData, isLoading: isTranslating } = useQuery({
    queryKey: ['translate', textEn, targetLang],
    queryFn: async () => {
      const res = await fetch('/v1/translate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: textEn, target_lang: targetLang }),
      });
      return res.json();
    },
    enabled: !!textEn,
  });

  const { data: advisoriesHistory = [], refetch: refetchHistory } = useQuery({
    queryKey: ['advisories-history'],
    queryFn: async () => {
      const res = await fetch('/v1/advisories');
      return res.json();
    },
  });

  const handleBroadcast = async () => {
    if (!isApproved) {
      alert('Human approval gate check required! Please check the approval sign-off box before broadcasting.');
      return;
    }

    try {
      const res = await fetch('/v1/advisories/broadcast', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          target_segment: targetSegment,
          text_en: textEn,
          approved_by: 'Suchit (Extension Lead)',
        }),
      });
      const data = await res.json();
      alert(`Advisory Broadcast Successful!\nBroadcast ID: ${data.broadcast_id}\nTarget: ${data.target_segment}`);
      refetchHistory();
    } catch (e) {
      alert('Broadcast request submitted.');
    }
  };

  const templates = [
    {
      title: 'Monsoon Rainfall & pH Protection',
      text: 'Heavy rainfall forecasted in coastal districts. Monitor pH diurnal drop below 7.5 and apply 15 kg/ha agricultural lime (CaCO3).',
    },
    {
      title: 'Overnight Hypoxemia & Aeration Trigger',
      text: 'Projected 04:00 DO minimum of 2.4 mg/L. Run paddlewheel aerators between 23:00 and 06:00 and cut morning feed by 20%.',
    },
    {
      title: 'Un-ionised Ammonia (NH3) Risk',
      text: 'High temperature and pH 8.4 detected. Cut feed by 25% to prevent un-ionised toxic ammonia spike.',
    },
  ];

  return (
    <div className="space-y-4">
      {/* Top Banner */}
      <div className="glass-panel p-4 rounded-xl border border-blue-200 dark:border-cyan-900/40 bg-white dark:bg-slate-900 flex items-center justify-between shadow-sm">
        <div>
          <h2 className="text-sm font-bold text-blue-900 dark:text-cyan-300 font-mono flex items-center gap-2">
            <Radio className="w-4 h-4 text-blue-600 dark:text-cyan-400" /> Screen 5: Advisory Broadcaster with IndicTrans2 Translation &amp; Approval Gate
          </h2>
          <p className="text-xs text-slate-600 dark:text-slate-300 mt-0.5 font-sans">
            Compose in English &rarr; M1 Reasoning Adapter draft &rarr; IndicTrans2 translation preview &rarr; Human Approval Gate &rarr; Push to Segment.
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
        {/* Left Column (7 cols): Composition & Translation */}
        <div className="lg:col-span-7 space-y-4">
          <div className="glass-panel p-5 rounded-xl border border-slate-200 dark:border-slate-800 space-y-4 bg-white dark:bg-slate-950 shadow-sm">
            <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-800 pb-2">
              <h3 className="text-xs font-bold text-slate-900 dark:text-slate-200 font-mono uppercase tracking-wider">
                1. English Advisory Composition
              </h3>
              <select
                value={targetSegment}
                onChange={(e) => setTargetSegment(e.target.value)}
                className="bg-slate-50 dark:bg-slate-900 text-slate-800 dark:text-slate-200 border border-slate-300 dark:border-slate-700 rounded px-2.5 py-1 text-xs font-mono font-medium"
              >
                <option value="Nagapattinam Vannamei Farmers">Nagapattinam Vannamei Segment</option>
                <option value="Thanjavur Inland Rohu Farmers">Thanjavur Rohu/Catla Segment</option>
                <option value="All High Risk Ponds (>0.65)">All High Risk Ponds (&gt;0.65)</option>
              </select>
            </div>

            <textarea
              rows={4}
              value={textEn}
              onChange={(e) => setTextEn(e.target.value)}
              className="w-full bg-slate-50 dark:bg-slate-900 text-slate-900 dark:text-slate-100 border border-slate-300 dark:border-slate-700 rounded-lg p-3 text-xs focus:outline-none focus:border-blue-600 font-sans leading-relaxed"
              placeholder="Enter advisory text in English..."
            />

            <div className="space-y-1.5">
              <span className="text-[11px] text-slate-500 dark:text-slate-400 font-mono font-semibold">Seasonal Advisory Templates:</span>
              <div className="flex flex-wrap gap-2">
                {templates.map((tmpl, i) => (
                  <button
                    key={i}
                    onClick={() => setTextEn(tmpl.text)}
                    className="px-2.5 py-1 bg-blue-50 hover:bg-blue-100 dark:bg-slate-900 dark:hover:bg-slate-800 border border-blue-200 dark:border-slate-700 text-blue-700 dark:text-slate-300 text-[11px] rounded transition-all font-mono font-semibold"
                  >
                    + {tmpl.title}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <div className="glass-panel p-5 rounded-xl border border-purple-200 dark:border-purple-900/40 bg-white dark:bg-slate-950 space-y-3 shadow-sm">
            <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-800 pb-2">
              <h3 className="text-xs font-bold text-purple-900 dark:text-purple-300 font-mono uppercase tracking-wider flex items-center gap-2">
                <Languages className="w-4 h-4 text-purple-600 dark:text-purple-400" /> 2. IndicTrans2 Neural Translation Preview
              </h3>
              <div className="flex items-center gap-2">
                <span className="text-[11px] text-slate-500 dark:text-slate-400 font-mono font-semibold">Target Language:</span>
                <select
                  value={targetLang}
                  onChange={(e) => setTargetLang(e.target.value as any)}
                  className="bg-slate-50 dark:bg-slate-900 text-purple-700 dark:text-purple-300 border border-purple-200 dark:border-purple-800 rounded px-2 py-0.5 text-xs font-mono font-semibold"
                >
                  <option value="ta">Tamil (தமிழ்)</option>
                  <option value="te">Telugu (తెలుగు)</option>
                  <option value="hi">Hindi (हिन्दी)</option>
                </select>
              </div>
            </div>

            <div className="p-3 bg-purple-50 dark:bg-purple-950/30 border border-purple-200 dark:border-purple-900/50 rounded-lg text-xs text-purple-900 dark:text-purple-100 font-sans leading-relaxed min-h-[70px] font-medium">
              {isTranslating ? (
                <span className="text-slate-400 font-mono">Translating via IndicTrans2 model...</span>
              ) : (
                translationData?.translated_text || 'Translation preview will appear here.'
              )}
            </div>

            <div className="p-4 bg-amber-50 dark:bg-slate-900 rounded-xl border border-amber-300 dark:border-amber-500/40 space-y-3 shadow-sm">
              <div className="flex items-start gap-2">
                <ShieldAlert className="w-4 h-4 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
                <div className="text-xs text-slate-800 dark:text-slate-300">
                  <span className="font-bold text-amber-900 dark:text-amber-300">Human Approval Gate Mandate:</span> Advisories generated by LLM reasoning adapters must be verified by a human analyst before edge deployment.
                </div>
              </div>

              <label className="flex items-center gap-2.5 cursor-pointer bg-white dark:bg-slate-950 p-2.5 rounded border border-slate-200 dark:border-slate-800">
                <input
                  type="checkbox"
                  checked={isApproved}
                  onChange={(e) => setIsApproved(e.target.checked)}
                  className="w-4 h-4 accent-blue-600 rounded cursor-pointer"
                />
                <span className="text-xs font-mono text-slate-800 dark:text-slate-200 font-bold">
                  I approve this advisory translation &amp; scientific correctness (Signed: Suchit)
                </span>
              </label>

              <button
                onClick={handleBroadcast}
                className="w-full py-2.5 bg-gradient-to-r from-blue-600 to-cyan-600 hover:from-blue-700 hover:to-cyan-700 text-white font-bold text-xs rounded-lg transition-all shadow flex items-center justify-center gap-2 font-mono"
              >
                <Send className="w-4 h-4" />
                Broadcast Advisory to Segment ({targetSegment})
              </button>
            </div>
          </div>
        </div>

        {/* Right Column (5 cols): Sent History Log */}
        <div className="lg:col-span-5 glass-panel p-5 rounded-xl border border-slate-200 dark:border-slate-800 space-y-3 bg-white dark:bg-slate-950 shadow-sm">
          <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-800 pb-2">
            <h3 className="text-xs font-bold text-slate-900 dark:text-slate-200 font-mono uppercase tracking-wider flex items-center gap-2">
              <Users className="w-4 h-4 text-blue-600 dark:text-cyan-400" /> Sent Advisory History &amp; Read Receipts
            </h3>
          </div>

          <div className="space-y-3">
            {advisoriesHistory.map((adv: any, i: number) => (
              <div key={i} className="p-3 bg-slate-50 dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-800 space-y-2 text-xs">
                <div className="flex justify-between font-mono">
                  <span className="font-bold text-blue-700 dark:text-cyan-400">{adv.target_segment}</span>
                  <span className="text-slate-400 text-[10px]">{new Date(adv.timestamp).toLocaleDateString()}</span>
                </div>
                <p className="text-slate-800 dark:text-slate-300 text-xs font-medium">{adv.text_en}</p>
                <div className="p-2 bg-white dark:bg-slate-950 rounded text-[11px] font-mono text-purple-700 dark:text-purple-300 border border-slate-200 dark:border-transparent font-medium">
                  {adv.text_ta}
                </div>
                <div className="flex justify-between items-center text-[10px] font-mono text-slate-500 border-t border-slate-200 dark:border-slate-800 pt-1.5">
                  <span>Approved by: {adv.approved_by}</span>
                  <span className="text-emerald-700 dark:text-emerald-400 font-bold">
                    Delivered: {adv.delivered_count} | Read: {adv.read_count}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};
