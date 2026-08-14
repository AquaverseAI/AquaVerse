import React, { useState, useEffect, useRef } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Layers, Activity, Filter, MapPin, Navigation } from 'lucide-react';
import { ExplanationCard } from '../components/common/ExplanationCard';
import { mockPonds } from '../mocks/handlers';

interface DistrictMapProps {
  selectedDistrict: string;
  onSelectPondForDeepDive: (pondId: string) => void;
  theme?: 'light' | 'dark';
}

// User-provided exact high-precision GPS coordinates for the 3 Coimbatore Lakes:
// 1. Singanallur Lake: 10.99009308182897° N, 77.02184251180928° E
// 2. Ukkadam Periyakulam: 10.98263595587382° N, 76.95542994444632° E
// 3. Valankulam Tank: 10.992199162944685° N, 76.97208109809374° E
const COIMBATORE_3_LAKES = [
  {
    id: 'CBE-001',
    name: 'Singanallur Lake',
    lat: 10.99009308182897,
    lng: 77.02184251180928,
    coordsText: '10.9901°N, 77.0218°E',
    risk: 0.68,
    biomass: '5,200 kg',
    species: 'Penaeus vannamei',
    color: '#f59e0b', // Amber
  },
  {
    id: 'CBE-002',
    name: 'Ukkadam Periyakulam',
    lat: 10.98263595587382,
    lng: 76.95542994444632,
    coordsText: '10.9826°N, 76.9554°E',
    risk: 0.45,
    biomass: '6,800 kg',
    species: 'Labeo rohita',
    color: '#10b981', // Emerald
  },
  {
    id: 'CBE-003',
    name: 'Valankulam Tank',
    lat: 10.992199162944685,
    lng: 76.97208109809374,
    coordsText: '10.9922°N, 76.9721°E',
    risk: 0.78,
    biomass: '7,400 kg',
    species: 'Penaeus vannamei',
    color: '#ef4444', // Red
  },
];

export const DistrictMap: React.FC<DistrictMapProps> = ({
  selectedDistrict,
  onSelectPondForDeepDive,
  theme = 'light',
}) => {
  const [selectedPondId, setSelectedPondId] = useState<string>('CBE-003');
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const leafletMapRef = useRef<any>(null);

  // Fetch Ponds List via TanStack Query
  const { data: pondsData } = useQuery({
    queryKey: ['ponds', selectedDistrict],
    queryFn: async () => {
      const res = await fetch(`/v1/ponds?district=Coimbatore`);
      return res.json();
    },
  });

  const { data: riskPayload } = useQuery({
    queryKey: ['pond-risk', selectedPondId],
    queryFn: async () => {
      if (!selectedPondId) return null;
      const res = await fetch(`/v1/ponds/${selectedPondId}/risk`);
      return res.json();
    },
    enabled: !!selectedPondId,
  });

  const pondsList: any[] = pondsData?.items || mockPonds;
  const selectedPond = pondsList.find((p) => p.pond_id === selectedPondId) || pondsList[2] || pondsList[0];

  // Dynamic Leaflet OpenStreetMap Initialization for Coimbatore 3 Lakes
  useEffect(() => {
    // Load Leaflet CSS dynamically if not present
    if (!document.getElementById('leaflet-css')) {
      const link = document.createElement('link');
      link.id = 'leaflet-css';
      link.rel = 'stylesheet';
      link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
      document.head.appendChild(link);
    }

    // Load Leaflet Script dynamically
    const loadLeafletScript = () => {
      if ((window as any).L) {
        initMap();
        return;
      }

      if (!document.getElementById('leaflet-js')) {
        const script = document.createElement('script');
        script.id = 'leaflet-js';
        script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
        script.onload = () => initMap();
        document.body.appendChild(script);
      }
    };

    const initMap = () => {
      if (!mapContainerRef.current || leafletMapRef.current) return;

      const L = (window as any).L;
      if (!L) return;

      // Center map directly over Coimbatore Lakes centroid: 10.988° N, 76.983° E, zoom level 13
      const map = L.map(mapContainerRef.current).setView([10.988, 76.983], 13);
      leafletMapRef.current = map;

      // OpenStreetMap Standard Tiles Layer
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors | AquaVerse AI',
        maxZoom: 18,
      }).addTo(map);

      // Draw Noyyal Feeder Canal Polyline connecting:
      // Singanallur (10.990093, 77.021843) -> Valankulam (10.992199, 76.972081) -> Ukkadam (10.982636, 76.955430)
      const canalPolyline = L.polyline(
        [
          [10.99009308182897, 77.02184251180928], // Singanallur Lake
          [10.992199162944685, 76.97208109809374], // Valankulam Tank
          [10.98263595587382, 76.95542994444632], // Ukkadam Periyakulam
        ],
        {
          color: '#0284c7',
          weight: 4,
          dashArray: '6, 8',
          opacity: 0.85,
        }
      ).addTo(map);
      canalPolyline.bindTooltip('Noyyal River Feeder Canal Line (3 Lakes Connector)', { permanent: false });

      // Add Custom OpenStreetMap Markers for all 3 Lakes with High-Precision Coordinates
      COIMBATORE_3_LAKES.forEach((lake) => {
        const customIcon = L.divIcon({
          className: 'custom-leaflet-marker',
          html: `
            <div style="
              background-color: ${lake.color};
              width: 36px;
              height: 36px;
              border-radius: 50%;
              border: 3px solid #ffffff;
              box-shadow: 0 4px 12px rgba(0,0,0,0.35);
              display: flex;
              align-items: center;
              justify-content: center;
              color: white;
              font-family: monospace;
              font-weight: bold;
              font-size: 11px;
            ">
              ${lake.id.replace('CBE-00', '')}
            </div>
          `,
          iconSize: [36, 36],
          iconAnchor: [18, 18],
        });

        const marker = L.marker([lake.lat, lake.lng], { icon: customIcon }).addTo(map);

        marker.bindPopup(`
          <div style="font-family: sans-serif; font-size: 12px; padding: 4px;">
            <strong style="color: #0284c7; font-size: 13px;">${lake.name} (${lake.id})</strong><br/>
            Exact GPS: <strong>${lake.lat.toFixed(6)}°N, ${lake.lng.toFixed(6)}°E</strong><br/>
            Current Risk Score: <strong style="color: ${lake.color}">${lake.risk.toFixed(2)}</strong><br/>
            Biomass: ${lake.biomass}<br/>
            Species: ${lake.species}
          </div>
        `);

        marker.on('click', () => {
          setSelectedPondId(lake.id);
        });
      });
    };

    loadLeafletScript();

    return () => {
      if (leafletMapRef.current) {
        leafletMapRef.current.remove();
        leafletMapRef.current = null;
      }
    };
  }, []);

  const defaultExplanation = {
    pond_id: selectedPondId || 'CBE-003',
    as_of: new Date().toISOString(),
    model_version: { numeric: 'm2-ebm-0.4.1', adapter: 'm1_chemistry-lora-1.0.0' },
    risk: 0.78,
    risk_delta_24h: 0.28,
    calibration: { brier_1m: 0.09, reliability: 'ok' },
    modality_gate: { timeseries: 0.74, image: 0.19, static: 0.07 },
    top_temporal_features: [
      { feature: 'night_DO_min', value: 2.1, unit: 'mg/L', attribution: 0.38, window: '0200-0500, Valankulam Tank (10.9922°N, 76.9721°E)' },
      { feature: 'TAN_slope_3d', value: 0.24, unit: 'mg/L/day', attribution: 0.25, window: 'Noyyal Basin inflow' },
      { feature: 'pH_diurnal_delta', value: 0.92, unit: 'pH units', attribution: 0.16, window: 'last 24h' },
    ],
    concepts: { white_spots: 0.05, empty_gut: 0.82, white_gut_line: 0.69, gill_discolouration: 0.18 },
    image_age_hours: 10,
    nearest_cases: [
      { pond: 'CBE-003', outcome: 'Valankulam overnight DO crash averted via aeration', similarity: 0.95 },
      { pond: 'CBE-001', outcome: 'Singanallur TAN runoff managed', similarity: 0.88 },
    ],
    blind_state: false,
    suppression_reason: null,
  };

  return (
    <div className="space-y-4">
      {/* Top Banner Context */}
      <div className="glass-panel p-4 rounded-xl border border-blue-200 dark:border-cyan-900/40 bg-gradient-to-r from-blue-50 via-white to-cyan-50 dark:from-slate-900 dark:via-slate-900 dark:to-cyan-950/40 flex flex-col md:flex-row items-start md:items-center justify-between gap-4 shadow-sm">
        <div>
          <h2 className="text-sm font-bold text-blue-900 dark:text-cyan-300 font-mono flex items-center gap-2">
            <MapPin className="w-4 h-4 text-blue-600 dark:text-cyan-400" /> Screen 1: High-Precision OpenGIS Map — 3 Coimbatore Lakes
          </h2>
          <p className="text-xs text-slate-600 dark:text-slate-400 mt-0.5 font-sans">
            User-verified GPS points: <strong className="text-blue-700 dark:text-cyan-400">Singanallur (10.9901°N, 77.0218°E)</strong>, <strong className="text-blue-700 dark:text-cyan-400">Valankulam (10.9922°N, 76.9721°E)</strong>, and <strong className="text-blue-700 dark:text-cyan-400">Ukkadam (10.9826°N, 76.9554°E)</strong>.
          </p>
        </div>

        {/* 3 Lakes Quick Selector Buttons */}
        <div className="flex items-center gap-1.5 bg-white dark:bg-slate-950 p-1.5 rounded-lg border border-slate-200 dark:border-slate-800 text-xs shadow-sm font-mono">
          <span className="text-slate-500 font-bold text-[11px] px-1">Coimbatore Lakes:</span>
          {COIMBATORE_3_LAKES.map((lake) => (
            <button
              key={lake.id}
              onClick={() => setSelectedPondId(lake.id)}
              className={`px-2.5 py-1 rounded text-[11px] font-bold transition-all ${
                selectedPondId === lake.id
                  ? 'bg-blue-600 text-white shadow-sm ring-2 ring-blue-400'
                  : 'bg-slate-100 dark:bg-slate-900 text-slate-700 dark:text-slate-300 hover:bg-blue-50'
              }`}
            >
              {lake.id} ({lake.name.split(' ')[0]})
            </button>
          ))}
        </div>
      </div>

      {/* Main Grid: GIS Map Surface + Right Side Explanation Panel */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
        {/* Map Canvas Column (7 cols) */}
        <div className="lg:col-span-7 glass-panel rounded-xl border border-slate-200 dark:border-slate-800 p-4 relative min-h-[560px] flex flex-col justify-between overflow-hidden bg-white dark:bg-slate-950 shadow-md">
          {/* Map Header Badge */}
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between border-b border-slate-200 dark:border-slate-800 pb-3 mb-2 gap-2">
            <div className="flex items-center gap-2">
              <Navigation className="w-4 h-4 text-blue-600 dark:text-cyan-400" />
              <span className="font-bold text-xs text-slate-900 dark:text-slate-100 font-mono">
                OpenStreetMap GIS — Exact User GPS Coordinates
              </span>
            </div>
            <div className="flex flex-wrap items-center gap-2.5 text-[10px] font-mono font-bold text-slate-700 dark:text-slate-300">
              <span className="flex items-center gap-1 text-amber-600">
                <span className="w-2.5 h-2.5 rounded-full bg-amber-500"></span> Singanallur (77.0218°E)
              </span>
              <span className="flex items-center gap-1 text-red-600">
                <span className="w-2.5 h-2.5 rounded-full bg-red-500"></span> Valankulam (76.9721°E)
              </span>
              <span className="flex items-center gap-1 text-emerald-600">
                <span className="w-2.5 h-2.5 rounded-full bg-emerald-500"></span> Ukkadam (76.9554°E)
              </span>
            </div>
          </div>

          {/* Interactive Leaflet OpenStreetMap Canvas */}
          <div
            ref={mapContainerRef}
            className="w-full h-[450px] rounded-lg border border-slate-300 dark:border-slate-800 overflow-hidden shadow-inner z-10"
          ></div>

          {/* Bottom Bar: Selected Pond Quick Actions */}
          {selectedPond && (
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-2 pt-3 border-t border-slate-200 dark:border-slate-800 text-xs mt-2">
              <div className="flex items-center gap-3 font-sans">
                <span className="font-mono font-bold text-blue-700 dark:text-cyan-400 text-sm">{selectedPond.pond_id}</span>
                <span className="text-slate-900 dark:text-slate-100 font-bold">{selectedPond.farmer_name}</span>
                <span className="text-slate-500 font-mono">({selectedPond.species}, DOC {selectedPond.doc})</span>
              </div>
              <button
                onClick={() => onSelectPondForDeepDive(selectedPond.pond_id)}
                className="px-3.5 py-1.5 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-lg transition-all flex items-center gap-1.5 font-mono shadow-sm shrink-0"
              >
                <Activity className="w-3.5 h-3.5" />
                Open {selectedPond.pond_id} Deep Dive &rarr;
              </button>
            </div>
          )}
        </div>

        {/* Right Explanation Column (5 cols) */}
        <div className="lg:col-span-5 space-y-4">
          <ExplanationCard payload={riskPayload || defaultExplanation} theme={theme} />
        </div>
      </div>
    </div>
  );
};
