import React, { useState } from 'react';
import { Lock, Mail, ArrowRight, Sparkles, Sun, Moon } from 'lucide-react';

interface LoginPageProps {
  onLoginSuccess: (user: { username: string; role: string; token: string }) => void;
  theme?: 'light' | 'dark';
  onToggleTheme?: () => void;
}

export const LoginPage: React.FC<LoginPageProps> = ({ onLoginSuccess, theme = 'light', onToggleTheme }) => {
  const [username, setUsername] = useState('suchit.analyst@aquaverse.gov.tn');
  const [password, setPassword] = useState('••••••••••••');
  const [role, setRole] = useState<'analyst' | 'extension_officer' | 'department_admin'>('analyst');
  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const handleFillDemo = () => {
    setUsername('suchit.analyst@aquaverse.gov.tn');
    setPassword('AquaVerse2026!');
    setRole('analyst');
    setErrorMsg('');
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setErrorMsg('');

    try {
      const res = await fetch('/v1/auth/token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      });

      if (!res.ok) {
        throw new Error('Invalid credentials or unauthorized Keycloak realm');
      }

      const data = await res.json();
      onLoginSuccess({
        username: username.split('@')[0] || 'analyst',
        role: data.role || role,
        token: data.access_token || 'mock-jwt-token-12345',
      });
    } catch (err: any) {
      setErrorMsg(err.message || 'Authentication failed. Please verify credentials.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 dark:bg-slate-950 dark:text-slate-100 flex items-center justify-center p-4 relative overflow-hidden font-sans transition-colors duration-200">
      {/* Background Animated Ocean Blue Glow Gradients */}
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-blue-400/20 dark:bg-cyan-600/20 rounded-full blur-3xl pointer-events-none animate-pulse"></div>
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-cyan-400/20 dark:bg-blue-600/15 rounded-full blur-3xl pointer-events-none"></div>

      {/* Theme Toggle Button in Corner */}
      {onToggleTheme && (
        <button
          onClick={onToggleTheme}
          className="absolute top-6 right-6 p-2 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl shadow-md text-slate-700 dark:text-slate-200 hover:bg-slate-100 transition-all"
        >
          {theme === 'light' ? <Moon className="w-5 h-5 text-blue-600" /> : <Sun className="w-5 h-5 text-amber-400" />}
        </button>
      )}

      {/* Main Glass Card Container */}
      <div className="w-full max-w-md bg-white/90 dark:bg-slate-900/90 backdrop-blur-xl p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-xl relative z-10 space-y-6">
        {/* Header Logo & Branding */}
        <div className="text-center space-y-2">
          <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-blue-600 to-cyan-500 flex items-center justify-center font-bold text-white shadow-lg glow-blue font-mono mx-auto text-2xl">
            AV
          </div>
          <div className="flex items-center justify-center gap-2 pt-2">
            <h1 className="font-bold text-2xl text-blue-950 dark:text-slate-100 tracking-tight">AquaVerse AI</h1>
            <span className="text-[10px] uppercase font-mono px-2 py-0.5 rounded bg-blue-50 text-blue-700 border border-blue-200 dark:bg-cyan-950 dark:text-cyan-400 dark:border-cyan-800 font-semibold">
              Keycloak OAuth2
            </span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">
            Analyst &amp; Extension Officer Secure Portal (PRD-AV-01)
          </p>
        </div>

        {/* Error Callout */}
        {errorMsg && (
          <div className="p-3 bg-red-50 dark:bg-red-950/60 border border-red-200 dark:border-red-800/80 rounded-lg text-xs text-red-700 dark:text-red-300 font-mono text-center">
            {errorMsg}
          </div>
        )}

        {/* Login Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Username / Staff Email */}
          <div className="space-y-1.5">
            <label className="text-xs font-mono text-slate-700 dark:text-slate-300 font-semibold">Staff Email / Keycloak ID</label>
            <div className="relative">
              <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
              <input
                type="email"
                required
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="name@aquaverse.gov.tn"
                className="w-full bg-slate-50 dark:bg-slate-900 text-slate-900 dark:text-slate-100 border border-slate-300 dark:border-slate-700 rounded-lg pl-9 pr-3 py-2.5 text-xs focus:outline-none focus:border-blue-600 font-mono transition-all"
              />
            </div>
          </div>

          {/* Password */}
          <div className="space-y-1.5">
            <label className="text-xs font-mono text-slate-700 dark:text-slate-300 font-semibold">Keycloak Password</label>
            <div className="relative">
              <Lock className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••••••"
                className="w-full bg-slate-50 dark:bg-slate-900 text-slate-900 dark:text-slate-100 border border-slate-300 dark:border-slate-700 rounded-lg pl-9 pr-3 py-2.5 text-xs focus:outline-none focus:border-blue-600 font-mono transition-all"
              />
            </div>
          </div>

          {/* Role Selection */}
          <div className="space-y-1.5">
            <label className="text-xs font-mono text-slate-700 dark:text-slate-300 font-semibold">Role-Scoped Realm</label>
            <select
              value={role}
              onChange={(e) => setRole(e.target.value as any)}
              className="w-full bg-slate-50 dark:bg-slate-900 text-slate-900 dark:text-slate-100 border border-slate-300 dark:border-slate-700 rounded-lg px-3 py-2.5 text-xs focus:outline-none focus:border-blue-600 font-mono font-medium"
            >
              <option value="analyst">Analyst (Fleet Manager &amp; Reasoner Lead)</option>
              <option value="extension_officer">Extension Officer (Field Operations)</option>
              <option value="department_admin">Department Official (State Director)</option>
            </select>
          </div>

          {/* Submit Button */}
          <button
            type="submit"
            disabled={isLoading}
            className="w-full py-3 bg-gradient-to-r from-blue-600 to-cyan-600 hover:from-blue-700 hover:to-cyan-700 text-white font-bold text-xs rounded-xl transition-all shadow-md flex items-center justify-center gap-2 font-mono disabled:opacity-50"
          >
            {isLoading ? (
              <span>Authenticating Keycloak...</span>
            ) : (
              <>
                <span>Sign In to Analyst Dashboard</span>
                <ArrowRight className="w-4 h-4" />
              </>
            )}
          </button>
        </form>

        {/* Demo Fill Helper */}
        <div className="pt-2 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
          <span className="text-[11px] text-slate-500 font-mono">Quick Access:</span>
          <button
            onClick={handleFillDemo}
            className="text-[11px] font-mono text-blue-600 dark:text-cyan-400 font-semibold hover:underline flex items-center gap-1"
          >
            <Sparkles className="w-3.5 h-3.5 text-blue-600 dark:text-cyan-400" />
            Fill Staff Demo Credentials
          </button>
        </div>

        {/* Disclaimer Footer */}
        <div className="text-[10px] text-center text-slate-400 font-mono">
          AquaVerse AI — Department of Fisheries, Govt of Tamil Nadu. Authorized staff access only.
        </div>
      </div>
    </div>
  );
};
