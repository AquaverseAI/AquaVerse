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
      // If media file present, presign & commit
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
    <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-sm flex items-center justify-center p-4">
      <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl max-w-xl w-full p-6 shadow-2xl space-y-5 animate-in fade-in zoom-in-95 duration-200">
        {/* Header */}
        <div className="flex items-center justify-between border-b border-slate-200 dark:border-slate-800 pb-3">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center text-white font-bold">
              <MessageSquare className="w-4 h-4" />
            </div>
            <div>
              <h3 className="font-bold text-slate-900 dark:text-slate-100 text-sm">
                Farmer AI Advisory Assistant (/v1/ask)
              </h3>
              <p className="text-xs text-slate-500 font-mono">Pond ID: {pondId} • vLLM Qwen3-8B + IndicTrans2</p>
            </div>
          </div>
          <button onClick={onClose} className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Options Bar */}
        <div className="flex items-center justify-between text-xs bg-slate-50 dark:bg-slate-950 p-2.5 rounded-xl border border-slate-200 dark:border-slate-800">
          <div className="flex items-center gap-2 font-mono">
            <Languages className="w-4 h-4 text-blue-600 dark:text-cyan-400" />
            <span>Language:</span>
            <select
              value={targetLang}
              onChange={(e) => setTargetLang(e.target.value as any)}
              className="bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded px-2 py-1 font-bold text-blue-600 dark:text-cyan-400"
            >
              <option value="ta">Tamil (தமிழ்)</option>
              <option value="en">English</option>
              <option value="te">Telugu (తెలుగు)</option>
              <option value="hi">Hindi (हिंदी)</option>
            </select>
          </div>

          <label className="flex items-center gap-1.5 font-mono text-xs cursor-pointer select-none">
            <input
              type="checkbox"
              checked={enableVoice}
              onChange={(e) => setEnableVoice(e.target.checked)}
              className="rounded text-blue-600 focus:ring-blue-500"
            />
            <Volume2 className="w-4 h-4 text-amber-500" />
            Enable Audio TTS
          </label>
        </div>

        {/* Input Form */}
        <form onSubmit={handleAsk} className="space-y-3">
          <textarea
            rows={3}
            value={question}
            onChange={(e) => setQuestion(e.target.value)}
            placeholder="e.g., How is my dissolved oxygen level looking for tonight? Should I run aerator 2?"
            className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-300 dark:border-slate-700 rounded-xl p-3 text-xs focus:outline-none focus:border-blue-600 font-sans"
          />

          {/* Optional Media Attachment */}
          <div className="flex items-center justify-between text-xs">
            <label className="flex items-center gap-2 text-slate-600 dark:text-slate-400 cursor-pointer hover:text-blue-600 font-mono">
              <Upload className="w-4 h-4 text-blue-600" />
              <span>{mediaFile ? mediaFile.name : 'Attach Image/Video (/v1/media/presign)'}</span>
              <input
                type="file"
                accept="image/*,video/*"
                className="hidden"
                onChange={(e) => setMediaFile(e.target.files?.[0] || null)}
              />
            </label>

            {uploadStatus && <span className="font-mono text-[11px] text-cyan-500">{uploadStatus}</span>}
          </div>

          <button
            type="submit"
            disabled={isLoading || !question.trim()}
            className="w-full py-2.5 bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs rounded-xl transition-all shadow-md flex items-center justify-center gap-2 disabled:opacity-50"
          >
            {isLoading ? (
              <span>Consulting Qwen3-8B Reasoner...</span>
            ) : (
              <>
                <Send className="w-4 h-4" />
                <span>Submit Query to AI Advisor</span>
              </>
            )}
          </button>
        </form>

        {/* Answer Output Display */}
        {response && (
          <div className="bg-blue-50/70 dark:bg-slate-950 p-4 rounded-xl border border-blue-200 dark:border-cyan-900 space-y-3 animate-in fade-in duration-200">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold font-mono text-blue-700 dark:text-cyan-400 flex items-center gap-1.5">
                <Sparkles className="w-4 h-4 text-amber-500" /> AI Advisory Response
              </span>
              <span className="text-[11px] font-mono text-slate-500">
                Confidence: {(response.confidence * 100).toFixed(0)}%
              </span>
            </div>

            <p className="text-xs font-semibold text-slate-800 dark:text-slate-200 leading-relaxed font-sans">
              {response.translated_answer || response.answer}
            </p>

            {response.audio_url && (
              <div className="flex items-center gap-2 p-2 bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-800 text-xs font-mono">
                <Volume2 className="w-4 h-4 text-amber-500 animate-pulse" />
                <span>Audio Speech Generated: {response.audio_url}</span>
              </div>
            )}

            <div className="pt-2 border-t border-slate-200 dark:border-slate-800 text-[11px] font-mono text-slate-500">
              <strong>Sources:</strong> {response.sources?.join(' • ')}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
