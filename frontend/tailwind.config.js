/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ['class'],
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif'],
        mono: ['JetBrains Mono', 'IBM Plex Mono', 'ui-monospace', 'SFMono-Regular', 'Menlo', 'Monaco', 'Consolas', 'monospace'],
      },
      colors: {
        // AquaVerse Mountain/Ocean Theme Palette
        ocean: {
          950: '#092131',
          900: '#0F3F5C', // Deepest ocean text & dark accent
          800: '#154C6E',
          700: '#1C5B82',
          600: '#23709F',
          500: '#2D89BF',
          400: '#4DA2D4',
          300: '#84C0E3',
          200: '#B8DCF1',
          100: '#E1F0F9',
          50: '#F0F7FC',
        },
        teal: {
          950: '#0A2B33',
          900: '#114450',
          800: '#175E6E',
          700: '#1F8AA6', // Primary interactive accent
          600: '#2394B2',
          500: '#2E9CB8',
          400: '#53B7CF',
          300: '#85D0E2',
          200: '#BDE7F1',
          100: '#E4F6FA',
          50: '#F2FBFD',
        },
        mint: {
          900: '#1C5948',
          800: '#26735E',
          700: '#349379',
          600: '#4FBFA0', // Seafoam / Healthy state accent
          500: '#5ECDB0',
          400: '#82DBC4',
          300: '#A9E8D7',
          200: '#CEF3EA',
          100: '#E9FAF5',
          50: '#F4FCF9',
        },
        surface: {
          base: '#F4FBFC',      // Pale cyan-white app background
          card: '#FFFFFF',      // Pure white card
          cardAlt: '#FCFEFE',
          cardSubtle: '#EFF8FA',
          border: '#DCE8EC',    // Soft cool-gray/teal border
          borderLight: '#E8F1F4',
          borderDark: '#C7D9DF',
          // Dark theme surfaces
          darkBase: '#081722',
          darkCard: '#0E2231',
          darkCardAlt: '#122B3E',
          darkBorder: 'rgba(255, 255, 255, 0.08)',
        },
        // Strict Semantic Risk Scale (Independent of brand palette)
        risk: {
          critical: '#DC3545',
          criticalBg: '#FDF2F2',
          criticalBorder: '#F8B4B4',
          warning: '#E8A33D',
          warningBg: '#FEF9EE',
          warningBorder: '#FCD89C',
          healthy: '#4FBFA0',
          healthyBg: '#F2FAF7',
          healthyBorder: '#A9E8D7',
          blind: '#6C7A89',
          blindBg: '#F3F5F7',
          blindBorder: '#D2D7DD',
        },
      },
      boxShadow: {
        'card-soft': '0 1px 3px rgba(15, 63, 92, 0.06), 0 1px 2px rgba(15, 63, 92, 0.04)',
        'card-hover': '0 4px 12px rgba(15, 63, 92, 0.08), 0 2px 4px rgba(15, 63, 92, 0.04)',
        'card-elevated': '0 8px 24px rgba(15, 63, 92, 0.10), 0 2px 6px rgba(15, 63, 92, 0.04)',
        'hud-glass': '0 8px 32px rgba(15, 63, 92, 0.12)',
      },
      borderRadius: {
        lg: '0.625rem',
        md: '0.5rem',
        sm: '0.375rem',
      },
      animation: {
        'fade-in': 'fadeIn 0.25s ease-out forwards',
        'slide-up': 'slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1) forwards',
        'pulse-subtle': 'pulseSubtle 2.5s ease-in-out infinite',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(6px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        pulseSubtle: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.7' },
        },
      },
    },
  },
  plugins: [],
}
