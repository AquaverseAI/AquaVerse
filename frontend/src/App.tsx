import React, { useState, useEffect } from 'react';
import { Sidebar, ScreenId } from './components/layout/Sidebar';
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
  const [selectedDistrict, setSelectedDistrict] = useState<string>('Coimbatore');
  const [selectedPondId, setSelectedPondId] = useState<string>('CBE-003');
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

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
    <div className="min-h-screen bg-[#F8FAFC] text-slate-900 dark:bg-[#0A0E13] dark:text-slate-100 font-sans flex flex-col lg:flex-row antialiased transition-colors duration-200 selection:bg-cyan-500 selection:text-white">
      {/* Left Sidebar Navigation */}
<Sidebar
        activeScreen={activeScreen}
        onSelectScreen={setActiveScreen}
        selectedDistrict={selectedDistrict}
        onDistrictChange={setSelectedDistrict}
        user={user}
        onLogout={() => setUser(null)}
        theme={theme}
        onToggleTheme={handleToggleTheme}
        mobileMenuOpen={mobileMenuOpen}
        onMobileMenuToggle={setMobileMenuOpen}
/>

      {/* Main Content Area (offset by left sidebar on desktop) */}
      <div className="flex-1 flex flex-col lg:pl-64 min-w-0 transition-all duration-200">
        <main className="flex-1 w-full max-w-[1700px] mx-auto p-3 sm:p-4 md:p-5">
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
        <footer className="border-t border-slate-200 dark:border-white/[0.06] py-3 text-center text-xs font-mono text-slate-500 dark:text-slate-400 bg-white/80 dark:bg-[#0A0E13]/80 backdrop-blur-md">
          AquaVerse AI &bull; State Aquaculture Observability &amp; M1 Reasoning Engine &bull; Confidential State Deployment (Tamil Nadu)
        </footer>
      </div>
    </div>
  );
}

export default App;
