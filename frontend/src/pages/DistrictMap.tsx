import React, { useState, useEffect, useRef } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Layers,
  Activity,
  Filter,
  MapPin,
  Navigation,
  ExternalLink,
  Radio,
  Sparkles,
  ArrowRight,
  Droplets,
  ShieldCheck,
  Crosshair,
} from 'lucide-react';
import { ExplanationCard } from '../components/common/ExplanationCard';
import { mockPonds } from '../mocks/handlers';
import { RiskStatusBadge } from '../components/common/RiskStatusBadge';

interface DistrictMapProps {
  selectedDistrict: string;
  onSelectPondForDeepDive: (pondId: string) => void;
  theme?: 'light' | 'dark';
}

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
    color: '#e8a33d', // Warm Amber (Elevated)
    severityText: 'Elevated TAN Risk',
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
    color: '#4fbfa0', // Seafoam Mint (Optimal)
    severityText: 'Optimal Telemetry',
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
    color: '#dc3545', // Warm Red (Critical)
    severityText: 'Critical Nocturnal Hypoxia',
  },
];

export const DistrictMap: React.FC<DistrictMapProps> = ({
  selectedDistrict,
  onSelectPondForDeepDive,
  theme = 'light',
}) => {
  const isDark = theme === 'dark';
  const [selectedLakeId, setSelectedLakeId] = useState<string>('CBE-003');
  const [hoveredLakeId, setHoveredLakeId] = useState<string | null>(null);

  const mapContainerRef = useRef<HTMLDivElement>(null);
  const leafletMapRef = useRef<any>(null);
  const markersRef = useRef<{ [key: string]: any }>({});

  const activeLake = COIMBATORE_3_LAKES.find((l) => l.id === selectedLakeId) || COIMBATORE_3_LAKES[2];

  // TanStack Query for the selected pond explanation payload
  const { data: explanationData } = useQuery({
    queryKey: ['pond-risk', selectedLakeId],
    queryFn: async () => {
      const res = await fetch(`/v1/ponds/${selectedLakeId}/risk`);
      return res.json();
    },
  });

  // Dynamically load Leaflet for real GIS rendering
  useEffect(() => {
    let isMounted = true;

    const loadLeaflet = async () => {
      if (!(window as any).L) {
        if (!document.getElementById('leaflet-css')) {
          const link = document.createElement('link');
          link.id = 'leaflet-css';
          link.rel = 'stylesheet';
          link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
          document.head.appendChild(link);
        }

        await new Promise<void>((resolve) => {
          if (document.getElementById('leaflet-js')) {
            resolve();
            return;
          }
          const script = document.createElement('script');
          script.id = 'leaflet-js';
          script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
          script.onload = () => resolve();
          document.head.appendChild(script);
        });
      }

      if (!isMounted || !mapContainerRef.current) return;

      const L = (window as any).L;
      if (!L) return;

      if (leafletMapRef.current) {
        leafletMapRef.current.remove();
        leafletMapRef.current = null;
      }

      const map = L.map(mapContainerRef.current, {
        center: [10.988, 76.985],
        zoom: 13,
        zoomControl: false,
        attributionControl: false,
      });
      leafletMapRef.current = map;

      L.control.zoom({ position: 'topright' }).addTo(map);

      // Positron light tiles or Carto dark tiles
      const tileUrl = isDark
        ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
        : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

      L.tileLayer(tileUrl, {
        maxZoom: 19,
        subdomains: 'abcd',
      }).addTo(map);

      // Noyyal Basin Feeder Canal Polyline
      const canalCoords = [
        [10.98263595587382, 76.95542994444632], // Ukkadam
        [10.992199162944685, 76.97208109809374], // Valankulam
        [10.99009308182897, 77.02184251180928], // Singanallur
      ];

      L.polyline(canalCoords, {
        color: isDark ? '#2e9cb8' : '#1f8aa6',
        weight: 3,
        opacity: 0.6,
        dashArray: '6, 8',
      }).addTo(map);

      // Render Interactive Custom Markers
      COIMBATORE_3_LAKES.forEach((lake) => {
        const isCurrent = lake.id === selectedLakeId;

        const customIcon = L.divIcon({
          className: 'custom-gis-marker',
          html: `
            <div style="position: relative; width: 34px; height: 34px; display: flex; align-items: center; justify-content: center; cursor: pointer;">
              ${
                isCurrent
                  ? `<div style="position: absolute; inset: -4px; border-radius: 50%; border: 2px solid ${lake.color}; opacity: 0.8; animation: ping 2s cubic-bezier(0, 0, 0.2, 1) infinite;"></div>`
                  : ''
              }
              <div style="width: 28px; height: 28px; border-radius: 50%; background: ${lake.color}; border: 3px solid #ffffff; box-shadow: 0 4px 10px rgba(15,63,92,0.25); display: flex; align-items: center; justify-content: center; color: white; font-family: monospace; font-weight: bold; font-size: 11px;">
                ${lake.risk.toFixed(2)}
              </div>
            </div>
          `,
          iconSize: [34, 34],
          iconAnchor: [17, 17],
        });

        const marker = L.marker([lake.lat, lake.lng], { icon: customIcon }).addTo(map);

        marker.on('click', () => {
          setSelectedLakeId(lake.id);
          map.flyTo([lake.lat, lake.lng], 14, { duration: 0.8 });
        });

        marker.bindTooltip(
          `<strong>${lake.name}</strong><br/>${lake.coordsText}<br/>Biomass: ${lake.biomass}`,
          { direction: 'top', offset: [0, -14], className: 'custom-map-tooltip' }
        );

        markersRef.current[lake.id] = marker;
      });
    };

    loadLeaflet();

    return () => {
      isMounted = false;
      if (leafletMapRef.current) {
        leafletMapRef.current.remove();
        leafletMapRef.current = null;
      }
    };
  }, [isDark, selectedLakeId]);

  const handleSelectLake = (lake: (typeof COIMBATORE_3_LAKES)[0]) => {
    setSelectedLakeId(lake.id);
    if (leafletMapRef.current) {
      leafletMapRef.current.flyTo([lake.lat, lake.lng], 14, { duration: 0.8 });
    }
  };

  return (
    <div className="space-y-4 animate-fade-in">
      {/* Top Banner */}
      <div className="instrument-card p-4 rounded-xl flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-base font-bold text-ocean-900 dark:text-slate-100 font-mono tracking-tight flex items-center gap-2">
              <MapPin className="w-4 h-4 text-teal-600" />
              Coimbatore Basin — 3 High-Priority Lakes GIS Fleet
            </h2>
            <span className="text-[10px] px-2 py-0.5 rounded bg-teal-50 text-teal-800 dark:bg-teal-950/60 dark:text-teal-300 border border-teal-200 dark:border-teal-800 font-mono font-bold">
              PRD-AV-02
            </span>
          </div>
          <p className="text-xs text-slate-600 dark:text-slate-400 mt-1 font-sans">
            Real-time geospatial telemetry for <strong>Singanallur Lake</strong>, <strong>Ukkadam Periyakulam</strong>, and <strong>Valankulam Tank</strong> along the Noyyal feeder system.
          </p>
        </div>

        {/* Fleet Summary Pills */}
        <div className="flex items-center gap-2 font-mono text-xs">
          <span className="px-2.5 py-1 bg-surface-cardSubtle dark:bg-surface-darkCardAlt rounded-lg border border-surface-border dark:border-surface-darkBorder text-slate-600 dark:text-slate-300">
            Total Biomass: <strong className="text-ocean-900 dark:text-teal-300">19,400 kg</strong>
          </span>
          <span className="px-2.5 py-1 bg-risk-criticalBg text-risk-critical border border-risk-criticalBorder rounded-lg font-bold">
            1 Critical
          </span>
        </div>
      </div>

      {/* Main Grid: GIS Map (7 cols) + Calibrated Explanation Card (5 cols) */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
        {/* Left Column (7 cols): Leaflet GIS Map with Lake Selector Tabs */}
        <div className="lg:col-span-7 space-y-3 flex flex-col">
          {/* Lake Selector Tabs */}
          <div className="grid grid-cols-3 gap-2">
            {COIMBATORE_3_LAKES.map((lake) => {
              const isSelected = selectedLakeId === lake.id;
              const isHovered = hoveredLakeId === lake.id;

              return (
                <button
                  key={lake.id}
                  onClick={() => handleSelectLake(lake)}
                  onMouseEnter={() => setHoveredLakeId(lake.id)}
                  onMouseLeave={() => setHoveredLakeId(null)}
                  className={`p-3 rounded-xl text-left transition-all font-mono border ${
                    isSelected
                      ? 'bg-surface-card dark:bg-surface-darkCard border-teal-600 shadow-md ring-2 ring-teal-500/20'
                      : 'bg-surface-cardSubtle dark:bg-surface-darkCardAlt border-surface-border dark:border-surface-darkBorder hover:border-teal-400'
                  }`}
                >
                  <div className="flex items-center justify-between">
                    <span className="text-[11px] font-bold text-ocean-900 dark:text-slate-100">{lake.name}</span>
                    <span
                      style={{ color: lake.color }}
                      className="text-xs font-mono font-extrabold"
                    >
                      {lake.risk.toFixed(2)}
                    </span>
                  </div>
<div className="flex justify-between items-center text-[10px] text-slate-500 dark:text-slate-400 mt-1">
                  <span>{lake.id}</span>
                  <RiskStatusBadge risk={lake.risk} blind_state={false} showValue={true} />
                </div>
                </button>
              );
            })}
          </div>

          {/* Map Container */}
          <div className="instrument-card rounded-xl overflow-hidden relative flex-1 min-h-[460px] shadow-sm">
            <div ref={mapContainerRef} className="w-full h-full min-h-[460px] z-10" />

            {/* In-Map Floating Legend */}
            <div className="absolute bottom-3 left-3 z-20 hud-card p-3 rounded-xl max-w-[280px] text-xs font-mono space-y-1.5 pointer-events-auto">
              <div className="flex items-center justify-between font-bold text-ocean-900 dark:text-slate-100 border-b border-surface-border dark:border-surface-darkBorder pb-1">
                <span>Selected: {activeLake.name}</span>
                <span style={{ color: activeLake.color }} className="font-extrabold">
                  {activeLake.risk.toFixed(2)}
                </span>
              </div>
              <div className="text-[10px] text-slate-500 dark:text-slate-400 space-y-0.5">
                <div>GPS: <strong className="text-ocean-900 dark:text-slate-200">{activeLake.coordsText}</strong></div>
                <div>Species: {activeLake.species} &bull; {activeLake.biomass}</div>
              </div>
              <button
                onClick={() => onSelectPondForDeepDive(activeLake.id)}
                className="w-full mt-1.5 py-1.5 px-2.5 bg-teal-600 hover:bg-teal-700 text-white font-bold rounded-lg transition-all flex items-center justify-center gap-1.5 text-[11px] active:scale-95 shadow-sm"
              >
                <span>Launch 3D Digital Twin</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        </div>

        {/* Right Column (5 cols): Calibrated Explanation Hero Card */}
        <div className="lg:col-span-5 space-y-4">
          {explanationData && <ExplanationCard payload={explanationData} theme={theme} />}
        </div>
      </div>
    </div>
  );
};
