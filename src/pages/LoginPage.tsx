import React, { useState } from 'react';
import { Lock, Mail, ArrowRight, Sparkles, Sun, Moon, ShieldCheck, Phone } from 'lucide-react';

interface LoginPageProps {
  onLoginSuccess: (user: { username: string; role: string; token: string }) => void;
  theme?: 'light' | 'dark';
  onToggleTheme?: () => void;
}

export const LoginPage: React.FC<LoginPageProps> = ({ onLoginSuccess, theme = 'light', onToggleTheme }) => {
  const [authMode, setAuthMode] = useState<'keycloak' | 'otp'>('keycloak');
  const [username, setUsername] = useState('suchit.analyst@aquaverse.gov.tn');
  const [password, setPassword] = useState('••••••••••••');
  const [phone, setPhone] = useState('9876543210');
  const [otpCode, setOtpCode] = useState('');
  const [txnId, setTxnId] = useState('');
  const [otpSent, setOtpSent] = useState(false);
  const [role, setRole] = useState<'analyst' | 'extension_officer' | 'farmer'>('analyst');
  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState('');

  const handleRequestOtp = async () => {
    setIsLoading(true);
    setErrorMsg('');
    try {
      const res = await fetch('/v1/auth/otp/request', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone }),
      });
      const data = await res.json();
      setTxnId(data.txn_id || `txn_${Date.now()}`);
      setOtpSent(true);
    } catch (err: any) {
      setErrorMsg('Failed to send OTP code');
    } finally {
      setIsLoading(false);
    }
  };

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setErrorMsg('');
    try {
      const res = await fetch('/v1/auth/otp/verify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone, otp: otpCode, txn_id: txnId }),
      });
      const data = await res.json();
      onLoginSuccess({
        username: data.farmer_name || `Farmer (${phone})`,
        role: 'farmer',
        token: data.access_token || 'mock-jwt-farmer-token',
      });
    } catch (err: any) {
      setErrorMsg('Invalid OTP code. Try again.');
    } finally {
      setIsLoading(false);
    }
  };

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
    <div className="min-h-screen bg-surface-base text-ocean-900 dark:bg-surface-darkBase dark:text-slate-100 flex items-center justify-center p-4 relative overflow-hidden font-sans transition-colors duration-200">
      {/* Background Subtle Gradient Spheres */}
      <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-teal-400/20 rounded-full blur-3xl pointer-events-none"></div>
      <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-ocean-400/20 rounded-full blur-3xl pointer-events-none"></div>

      {/* Theme Toggle Button */}
      {onToggleTheme && (
        <button
          onClick={onToggleTheme}
          className="absolute top-6 right-6 p-2 instrument-card rounded-lg text-ocean-900 dark:text-slate-300 transition-all"
        >
          {theme === 'light' ? <Moon className="w-4 h-4 text-ocean-900" /> : <Sun className="w-4 h-4 text-amber-400" />}
        </button>
      )}

      {/* Main Container */}
      <div className="w-full max-w-md instrument-card p-8 rounded-2xl shadow-card-elevated relative z-10 space-y-6 animate-fade-in">
        {/* Header Logo */}
        <div className="text-center space-y-2">
          <div className="w-12 h-12 rounded-xl bg-gradient-to-br from-teal-600 to-ocean-900 flex items-center justify-center font-bold text-white shadow-md font-mono mx-auto text-lg">
            AV
          </div>
          <div className="flex items-center justify-center gap-2 pt-1">
            <h1 className="font-bold text-xl text-ocean-900 dark:text-slate-100 tracking-tight font-mono">
              AquaVerse <span className="text-teal-600 font-extrabold">AI</span>
            </h1>
            <span className="text-[10px] uppercase font-mono px-2 py-0.5 rounded bg-teal-50 dark:bg-teal-950 text-teal-700 dark:text-teal-300 border border-teal-200 dark:border-teal-800 font-semibold">
              State Portal
            </span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 font-mono">
            Analyst &amp; Reasoner Secure Interface
          </p>
        </div>

        {/* Auth Mode Toggle */}
        <div className="flex rounded-lg bg-surface-cardSubtle dark:bg-surface-darkCardAlt p-1 border border-surface-border dark:border-surface-darkBorder text-xs font-mono font-semibold">
          <button
            onClick={() => setAuthMode('keycloak')}
            className={`flex-1 py-1.5 rounded transition-all ${
              authMode === 'keycloak'
                ? 'bg-teal-600 text-white font-bold shadow-xs'
                : 'text-slate-500 dark:text-slate-400 hover:text-ocean-900 dark:hover:text-slate-200'
            }`}
          >
            Keycloak OAuth2
          </button>
          <button
            onClick={() => setAuthMode('otp')}
            className={`flex-1 py-1.5 rounded transition-all ${
              authMode === 'otp'
                ? 'bg-teal-600 text-white font-bold shadow-xs'
                : 'text-slate-500 dark:text-slate-400 hover:text-ocean-900 dark:hover:text-slate-200'
            }`}
          >
            Farmer Mobile OTP
          </button>
        </div>

        {/* Error Callout */}
        {errorMsg && (
          <div className="p-3 bg-risk-criticalBg border border-risk-criticalBorder rounded-lg text-xs text-risk-critical font-mono text-center">
            {errorMsg}
          </div>
        )}

        {authMode === 'otp' ? (
          <form onSubmit={handleVerifyOtp} className="space-y-4 font-mono text-xs">
            <div className="space-y-1.5">
              <label className="text-slate-600 dark:text-slate-300">Mobile Phone Number</label>
              <input
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className="w-full bg-surface-cardSubtle dark:bg-surface-darkCardAlt border border-surface-border dark:border-surface-darkBorder rounded-lg p-2.5 font-mono text-ocean-900 dark:text-slate-100 focus:outline-none focus:border-teal-600"
                placeholder="+91 98765 43210"
              />
            </div>
            {otpSent ? (
              <div className="space-y-1.5">
                <label className="text-slate-600 dark:text-slate-300">6-Digit OTP Code</label>
                <input
                  type="text"
                  value={otpCode}
                  onChange={(e) => setOtpCode(e.target.value)}
                  className="w-full bg-surface-cardSubtle dark:bg-surface-darkCardAlt border border-surface-border dark:border-surface-darkBorder rounded-lg p-2.5 font-mono tracking-widest text-center font-bold text-teal-700 dark:text-teal-400 text-base focus:outline-none focus:border-teal-600"
                  placeholder="1 2 3 4 5 6"
                />
              </div>
            ) : (
              <button
                type="button"
                onClick={handleRequestOtp}
                disabled={isLoading}
                className="w-full py-2.5 bg-teal-600 hover:bg-teal-700 text-white font-bold rounded-lg shadow-sm transition-all flex items-center justify-center gap-2 active:scale-95"
              >
                <span>Send OTP Code</span>
              </button>
            )}
            {otpSent && (
              <button
                type="submit"
                disabled={isLoading}
                className="w-full py-2.5 bg-teal-600 hover:bg-teal-700 text-white font-bold rounded-lg shadow-sm transition-all flex items-center justify-center gap-2 active:scale-95"
              >
                <span>Verify OTP &amp; Login</span>
              </button>
            )}
          </form>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4 font-mono text-xs">
            <div className="space-y-1.5">
              <label className="text-slate-600 dark:text-slate-300">Institutional Username (Email)</label>
              <div className="relative">
                <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type="email"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  required
                  className="w-full bg-surface-cardSubtle dark:bg-surface-darkCardAlt border border-surface-border dark:border-surface-darkBorder rounded-lg pl-9 pr-3 py-2.5 text-ocean-900 dark:text-slate-100 focus:outline-none focus:border-teal-600"
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <label className="text-slate-600 dark:text-slate-300">Keycloak Password</label>
              <div className="relative">
                <Lock className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  className="w-full bg-surface-cardSubtle dark:bg-surface-darkCardAlt border border-surface-border dark:border-surface-darkBorder rounded-lg pl-9 pr-3 py-2.5 text-ocean-900 dark:text-slate-100 focus:outline-none focus:border-teal-600"
                />
              </div>
            </div>

            <div className="flex items-center justify-between pt-1">
              <button
                type="button"
                onClick={handleFillDemo}
                className="text-[11px] text-teal-700 dark:text-teal-400 hover:underline"
              >
                Fill Demo Credentials
              </button>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-2.5 bg-ocean-900 hover:bg-ocean-800 text-white font-bold rounded-lg shadow-sm transition-all flex items-center justify-center gap-2 active:scale-95"
            >
              <span>Authenticate with Keycloak</span>
              <ArrowRight className="w-4 h-4" />
            </button>
          </form>
        )}
      </div>
    </div>
  );
};
