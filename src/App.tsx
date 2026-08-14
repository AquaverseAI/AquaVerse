import React, { useState, useEffect } from 'react';
import { Navbar, ScreenId } from './components/layout/Navbar';
import { LoginPage } from './pages/LoginPage';
import { DistrictMap } from './pages/DistrictMap';
import { TriageWorklist } from './pages/TriageWorklist';
import { PondDeepDive } from './pages/PondDeepDive';
import { ModelOperations } from './pages/ModelOperations';
import { AdvisoryBroadcaster } from './pages/AdvisoryBroadcaster';
import { DataQuality } from './pages/DataQuality';
import { AnalyticsReports } from './pages/AnalyticsReports';

export interface UserSession {
  username: string;
  role: string;
  token: string;
}

export function App() {
  const [theme, setTheme] = useState<'light' | 'dark'>('light');
  const [user, setUser] = useState<UserSession | null>({
    username: 'Suchit (Lead)',
    role: 'analyst',
    token: 'mock-jwt-token-12345',
  });
  const [activeScreen, setActiveScreen] = useState<ScreenId>('map');
  const [selectedDistrict, setSelectedDistrict] = useState<string>('All');
  const [selectedPondId, setSelectedPondId] = useState<string>('NGP-004');

  // Toggle dark/light class on html element
  useEffect(() => {
    const root = document.documentElement;
    if (theme === 'dark') {
      root.classList.add('dark');
      root.classList.remove('light');
    } else {
      root.classList.add('light');
      root.classList.remove('dark');
    }
  }, [theme]);

  const handleToggleTheme = () => {
    setTheme((prev) => (prev === 'light' ? 'dark' : 'light'));
  };

  const handleSelectPondForDeepDive = (pondId: string) => {
    setSelectedPondId(pondId);
    setActiveScreen('deepdive');
  };

  const handleOpenBroadcaster = (pondId: string) => {
    setSelectedPondId(pondId);
    setActiveScreen('broadcaster');
  };

  // If user is not logged in, display the Keycloak OAuth2 Login Screen
  if (!user) {
    return <LoginPage onLoginSuccess={(u) => setUser(u)} theme={theme} onToggleTheme={handleToggleTheme} />;
  }

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 dark:bg-slate-950 dark:text-slate-100 font-sans flex flex-col antialiased transition-colors duration-200">
      {/* Top Navbar Header */}
      <Navbar
        activeScreen={activeScreen}
        onSelectScreen={setActiveScreen}
        selectedDistrict={selectedDistrict}
        onDistrictChange={setSelectedDistrict}
        user={user}
        onLogout={() => setUser(null)}
        theme={theme}
        onToggleTheme={handleToggleTheme}
      />

      {/* Main Content Area */}
      <main className="flex-1 max-w-[1700px] w-full mx-auto p-4">
        {activeScreen === 'map' && (
          <DistrictMap
            selectedDistrict={selectedDistrict}
            onSelectPondForDeepDive={handleSelectPondForDeepDive}
            theme={theme}
          />
        )}

        {activeScreen === 'worklist' && (
          <TriageWorklist
            onSelectPondForDeepDive={handleSelectPondForDeepDive}
            onOpenBroadcaster={handleOpenBroadcaster}
            theme={theme}
          />
        )}

        {activeScreen === 'deepdive' && (
          <PondDeepDive pondId={selectedPondId} theme={theme} />
        )}

        {activeScreen === 'modelops' && <ModelOperations theme={theme} />}

        {activeScreen === 'broadcaster' && (
          <AdvisoryBroadcaster initialPondId={selectedPondId} theme={theme} />
        )}

        {activeScreen === 'dataquality' && <DataQuality theme={theme} />}

        {activeScreen === 'analytics' && <AnalyticsReports theme={theme} />}
      </main>

      {/* Footer */}
      <footer className="border-t border-slate-200 dark:border-slate-900 py-3 text-center text-xs font-mono text-slate-500 bg-white dark:bg-slate-950">
        AquaVerse AI — Workstream 1: Analyst Dashboard &amp; M1 Water-Chemistry Model | Confidential State Deployment (Tamil Nadu)
      </footer>
    </div>
  );
}

export default App;
