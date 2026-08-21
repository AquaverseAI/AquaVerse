import React, { useState, useEffect } from 'react';
import { Outlet, useNavigate, useLocation } from '@tanstack/react-router';
import { Sidebar, ScreenId } from './components/layout/Sidebar';
import { LoginPage } from './pages/LoginPage';

export interface UserSession {
  username: string;
  role: string;
  token: string;
}

export function App() {
  const [theme, setTheme] = useState<'light' | 'dark'>('light');
  const [user, setUser] = useState<UserSession | null>(() => {
    const savedToken = localStorage.getItem('auth_token');
    const savedUser = localStorage.getItem('auth_user');
    if (savedToken && savedUser) {
      try {
        return JSON.parse(savedUser);
      } catch {
        return null;
      }
    }
    return null;
  });
  
  const navigate = useNavigate();
  const location = useLocation();
  
  const [selectedDistrict, setSelectedDistrict] = useState<string>('Coimbatore');
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  // Derive activeScreen from current path
  const path = location.pathname;
  let activeScreen: ScreenId = 'map';
  if (path.startsWith('/worklist')) activeScreen = 'worklist';
  if (path.startsWith('/ponds/')) activeScreen = 'deepdive';
  if (path.startsWith('/modelops')) activeScreen = 'modelops';
  if (path.startsWith('/broadcaster')) activeScreen = 'broadcaster';
  if (path.startsWith('/dataquality')) activeScreen = 'dataquality';
  if (path.startsWith('/analytics')) activeScreen = 'analytics';

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

  const handleSelectScreen = (screen: ScreenId) => {
    switch (screen) {
      case 'map': navigate({ to: '/' }); break;
      case 'worklist': navigate({ to: '/worklist' }); break;
      case 'deepdive': navigate({ to: '/ponds/$pondId', params: { pondId: 'CBE-003' } }); break;
      case 'modelops': navigate({ to: '/modelops' }); break;
      case 'broadcaster': navigate({ to: '/broadcaster' }); break;
      case 'dataquality': navigate({ to: '/dataquality' }); break;
      case 'analytics': navigate({ to: '/analytics' }); break;
    }
  };

  // If user is not logged in, display the Keycloak OAuth2 Login Screen
  if (!user) {
    return <LoginPage 
      onLoginSuccess={(u) => {
        localStorage.setItem('auth_token', u.token);
        localStorage.setItem('auth_user', JSON.stringify(u));
        setUser(u);
      }} 
      theme={theme} 
      onToggleTheme={handleToggleTheme} 
    />;
  }

  return (
    <div className="min-h-screen bg-[#F8FAFC] text-slate-900 dark:bg-[#0A0E13] dark:text-slate-100 font-sans flex flex-col lg:flex-row antialiased transition-colors duration-200 selection:bg-cyan-500 selection:text-white">
      {/* Left Sidebar Navigation */}
<Sidebar
        activeScreen={activeScreen}
        onSelectScreen={handleSelectScreen}
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
          <Outlet />
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
