import React, { useState } from 'react';
import { MessageSquare, Send, Volume2, Sparkles, X, Languages, Upload, CheckCircle2 } from 'lucide-react';
import { askApi, mediaApi } from '../../api/client';

interface AskFarmerModalProps {
  pondId: string;
  isOpen: boolean;
  onClose: () => void;
  theme?: 'light' | 'dark';
}

export const AskFarmerModal: React.FC<AskFarmerModalProps> = ({ pondId, isOpen, onClose }) => {
  const [question, setQuestion] = useState('');
  const [targetLang, setTargetLang] = useState<'en' | 'ta' | 'te' | 'hi'>('ta');
  const [enableVoice, setEnableVoice] = useState(true);
  const [isLoading, setIsLoading] = useState(false);
  const [response, setResponse] = useState<any>(null);
  const [mediaFile, setMediaFile] = useState<File | null>(null);
  const [uploadStatus, setUploadStatus] = useState('');

  if (!isOpen) return null;

  const handleAsk = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!question.trim()) return;

    setIsLoading(true);
    try {
      if (mediaFile) {
        setUploadStatus('Generating MinIO presigned URL...');
        const presign = await mediaApi.presignUpload({
          pond_id: pondId,
          filename: mediaFile.name,
          content_type: mediaFile.type || 'image/jpeg',
          category: 'water_sample',
        });
        setUploadStatus('Uploading asset to object storage...');
        await mediaApi.commitUpload({
          pond_id: pondId,
          asset_key: presign.asset_key || 'uploads/asset.jpg',
          caption: question,
        });
        setUploadStatus('Media committed!');
      }

      const res = await askApi.askAssistant({
        pond_id: pondId,
        question,
        lang: targetLang,
        voice_tts: enableVoice,
      });

      setResponse(res);
    } catch (err: any) {
      alert(`Error calling Farmer Assistant API (/v1/ask): ${err.message}`);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 bg-ocean-950/50 backdrop-blur-xs flex items-center justify-center p-4">
      <div className="instrument-card rounded-2xl max-w-xl w-full p-6 shadow-card-elevated space-y-5 animate-fade-in">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-surface-border dark:border-surface-darkBorder pb-3">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-teal-600 flex items-center justify-center text-white font-bold">
              <MessageSquare className="w-4 h-4" />
            </div>
            <div>
              <h3 className="font-bold text-ocean-900 dark:text-slate-100 text-sm font-mono">
                Farmer AI Assistant (/v1/ask)
              </h3>
              <p className="text-xs text-slate-500 font-mono">Pond: {pondId} &bull; vLLM Qwen3-8B + IndicTrans2</p>
            </div>
          </div>
          <button onClick={onClose} className="p-1 text-slate-400 hover:text-ocean-900 dark:hover:text-slate-200">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Options Bar */}
        <div className="flex items-center justify-between text-xs bg-surface-cardSubtle dark:bg-surface-darkCardAlt p-2.5 rounded-xl border border-surface-border dark:border-surface-darkBorder">
          <div className="flex items-center gap-2 font-mono">
            <Languages className="w-4 h-4 text-teal-600" />
            <span className="text-slate-500">Language:</span>
            <select
              value={targetLang}
              onChange={(e) => setTargetLang(e.target.value as any)}
              className="bg-white dark:bg-surface-darkCard border border-surface-border dark:border-surface-darkBorder rounded px-2 py-0.5 font-bold text-teal-700 dark:text-teal-400"
            >
              <option value="ta">Tamil (தமிழ்)</option>
              <option value="en">English</option>
              <option value="te">Telugu (తెలుగు)</option>
              <option value="hi">Hindi (हिंदी)</option>
            </select>
          </div>

          <label className="flex items-center gap-1.5 font-mono text-xs cursor-pointer select-none text-slate-700 dark:text-slate-300">
            <input
              type="checkbox"
              checked={enableVoice}
              onChange={(e) => setEnableVoice(e.target.checked)}
              className="rounded accent-teal-600"
            />
            <Volume2 className="w-4 h-4 text-amber-500" />
            <span>Enable Audio TTS</span>
          </label>
        </div>

        {/* Input Form */}
        <form onSubmit={handleAsk} className="space-y-3">
          <textarea
            rows={3}
            value={question}
            onChange={(e) => setQuestion(e.target.value)}
            placeholder="e.g. What is my overnight dissolved oxygen prediction? Should I turn on aerator 2?"
            className="w-full bg-surface-cardSubtle dark:bg-surface-darkCardAlt border border-surface-border dark:border-surface-darkBorder rounded-lg p-3 text-xs focus:outline-none focus:border-teal-600 font-sans text-ocean-900 dark:text-slate-100"
          />

          {/* Optional Media Attachment */}
          <div className="flex items-center justify-between text-xs font-mono">
            <label className="flex items-center gap-2 text-slate-500 cursor-pointer hover:text-teal-700">
              <Upload className="w-4 h-4 text-teal-600" />
              <span>{mediaFile ? mediaFile.name : 'Attach Image/Video (/v1/media/presign)'}</span>
              <input
                type="file"
                accept="image/*,video/*"
                className="hidden"
                onChange={(e) => setMediaFile(e.target.files?.[0] || null)}
              />
            </label>

            {uploadStatus && <span className="text-[11px] text-teal-700 font-bold">{uploadStatus}</span>}
          </div>

          <button
            type="submit"
            disabled={isLoading || !question.trim()}
            className="w-full py-2.5 bg-teal-600 hover:bg-teal-700 text-white font-mono font-bold text-xs rounded-xl transition-all shadow-sm flex items-center justify-center gap-2 disabled:opacity-40 active:scale-95"
          >
            {isLoading ? (
              <span>Consulting Qwen3-8B Reasoner...</span>
            ) : (
              <>
                <Send className="w-3.5 h-3.5" />
                <span>Submit Query to AI Advisor</span>
              </>
            )}
          </button>
        </form>

        {/* Answer Output */}
        {response && (
          <div className="bg-teal-50/70 dark:bg-teal-950/20 p-4 rounded-xl border border-teal-200 dark:border-teal-900/40 space-y-3 animate-fade-in">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold font-mono text-teal-800 dark:text-teal-300 flex items-center gap-1.5">
                <Sparkles className="w-4 h-4 text-amber-500" /> AI Advisory Response
              </span>
              <span className="text-[11px] font-mono text-slate-500">
                Confidence: {(response.confidence * 100).toFixed(0)}%
              </span>
            </div>

            <p className="text-xs font-medium text-ocean-900 dark:text-slate-100 leading-relaxed font-sans">
              {response.translated_answer || response.answer}
            </p>

            {response.audio_url && (
              <div className="flex items-center gap-2 p-2 bg-white dark:bg-surface-darkCard rounded border border-surface-border dark:border-surface-darkBorder text-xs font-mono text-slate-700 dark:text-slate-300">
                <Volume2 className="w-4 h-4 text-amber-500 animate-pulse" />
                <span>Audio Speech Generated: {response.audio_url}</span>
              </div>
            )}

            <div className="pt-2 border-t border-teal-200 dark:border-teal-900/40 text-[11px] font-mono text-slate-500">
              <strong>Sources:</strong> {response.sources?.join(' • ')}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
