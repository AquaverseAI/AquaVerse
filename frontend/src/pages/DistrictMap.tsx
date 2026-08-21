import React, { useState, useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import Map from 'react-map-gl/maplibre';
import DeckGL from '@deck.gl/react';
import { ScatterplotLayer, GeoJsonLayer, ArcLayer } from '@deck.gl/layers';
import 'maplibre-gl/dist/maplibre-gl.css';
import { MapPin, Navigation, Filter, Sparkles, Activity, Layers } from 'lucide-react';
import { Button } from '../components/ui/button';

interface DistrictMapProps {
  selectedDistrict: string;
  onSelectPondForDeepDive: (pondId: string) => void;
  theme?: 'light' | 'dark';
}

const MAP_STYLE_LIGHT = 'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json';
const MAP_STYLE_DARK = 'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json';

const INITIAL_VIEW_STATE = {
  longitude: 76.972,
  latitude: 10.992,
  zoom: 11.5,
  pitch: 45,
  bearing: 0,
};

export const DistrictMap: React.FC<DistrictMapProps> = ({
  selectedDistrict,
  onSelectPondForDeepDive,
  theme = 'light',
}) => {
  const isDark = theme === 'dark';

  // Filters State
  const [filterDistrict, setFilterDistrict] = useState<string>('All');
  const [filterRisk, setFilterRisk] = useState<string>('All');

  // Fetch Ponds
  const { data: pondsData } = useQuery({
    queryKey: ['geo-ponds', filterDistrict],
    queryFn: async () => {
      const url = filterDistrict !== 'All' ? `/v1/geo/ponds?district=${filterDistrict}` : '/v1/geo/ponds';
      const res = await fetch(url);
      return res.json();
    },
  });

  // Fetch Clusters
  const { data: clustersData } = useQuery({
    queryKey: ['geo-clusters', filterDistrict],
    queryFn: async () => {
      const url = filterDistrict !== 'All' ? `/v1/geo/clusters?district=${filterDistrict}` : '/v1/geo/clusters';
      const res = await fetch(url);
      return res.json();
    },
  });

  // Process data & mock biomass / topology
  const { ponds, filteredPonds, arcs } = useMemo(() => {
    if (!pondsData?.features) return { ponds: [], filteredPonds: [], arcs: [] };

    const processedPonds = pondsData.features.map((f: any) => {
      // Mock biomass based on hash of id to keep it deterministic
      const mockHash = f.properties.pond_name.length * 1432;
      const biomass = (mockHash % 12000) + 3000; 
      
      // Map risk string to color
      let color: [number, number, number, number] = [79, 191, 160, 200]; // Optimal (Mint)
      if (f.properties.suppressed) color = [148, 163, 184, 150]; // Grey
      else if (f.properties.risk_level === 'critical') color = [220, 53, 69, 200]; // Red
      else if (f.properties.risk_level === 'high') color = [232, 163, 61, 200]; // Amber
      else if (f.properties.risk_level === 'medium') color = [232, 163, 61, 150]; // Amber lighter

      return {
        ...f,
        properties: {
          ...f.properties,
          biomass_kg: biomass,
          color,
        },
      };
    });

    const filtered = processedPonds.filter((p: any) => {
      if (filterRisk !== 'All' && p.properties.risk_level !== filterRisk.toLowerCase()) return false;
      return true;
    });

    // Generate topological mock arcs (connecting nearby high risk ponds to downstream)
    // We'll just randomly connect a few points to form a canal line for visual effect
    const sorted = [...filtered].sort((a: any, b: any) => a.geometry.coordinates[1] - b.geometry.coordinates[1]);
    const mockArcs = [];
    for (let i = 0; i < sorted.length - 1; i++) {
      if (i % 3 === 0) { // Connect some subset
        const source = sorted[i];
        const target = sorted[i+1];
        if (source.properties.risk_score > 0.5) {
          mockArcs.push({
            source: source.geometry.coordinates,
            target: target.geometry.coordinates,
            sourceRisk: source.properties.risk_score,
          });
        }
      }
    }

    return { ponds: processedPonds, filteredPonds: filtered, arcs: mockArcs };
  }, [pondsData, filterRisk]);

  const clusters = clustersData?.features || [];

  // DeckGL Layers
  const layers = [
    // 1. Cluster Polygons (GeoJSON)
    new GeoJsonLayer({
      id: 'clusters-layer',
      data: clusters,
      pickable: true,
      stroked: true,
      filled: true,
      extruded: false,
      lineWidthMinPixels: 2,
      getFillColor: [220, 53, 69, 40], // Light red overlay
      getLineColor: [220, 53, 69, 150], // Red border
      getLineWidth: 2,
    }),

    // 2. Topology Arcs (Downstream transmission paths)
    new ArcLayer({
      id: 'topology-arcs',
      data: arcs,
      getSourcePosition: (d: any) => d.source,
      getTargetPosition: (d: any) => d.target,
      getSourceColor: [220, 53, 69, 200],
      getTargetColor: [232, 163, 61, 200],
      getWidth: 2,
    }),

    // 3. Pond Markers (Scatterplot)
    new ScatterplotLayer({
      id: 'ponds-layer',
      data: filteredPonds,
      pickable: true,
      opacity: 0.8,
      stroked: true,
      filled: true,
      radiusScale: 1,
      radiusMinPixels: 4,
      radiusMaxPixels: 20,
      lineWidthMinPixels: 1,
      getPosition: (d: any) => d.geometry.coordinates,
      // Size by biomass
      getRadius: (d: any) => Math.sqrt(d.properties.biomass_kg) * 5, 
      getFillColor: (d: any) => d.properties.color,
      getLineColor: (d: any) => [255, 255, 255, 200],
      onClick: ({ object }: any) => {
        if (object) {
          onSelectPondForDeepDive(object.id);
        }
      },
    }),
  ];

  return (
    <div className="relative w-full h-[calc(100vh-100px)] rounded-xl overflow-hidden border border-surface-border dark:border-surface-darkBorder shadow-sm animate-fade-in flex flex-col">
      {/* DeckGL Map Canvas */}
      <div className="flex-1 relative">
        <DeckGL
          initialViewState={INITIAL_VIEW_STATE}
          controller={true}
          layers={layers}
          getTooltip={({ object }: any) => {
            if (!object) return null;
            if (object.properties?.pond_name) {
              return `Pond: ${object.properties.pond_name}\nDistrict: ${object.properties.district}\nSpecies: ${object.properties.species}\nRisk: ${object.properties.risk_level.toUpperCase()} (${object.properties.risk_score.toFixed(2)})\nBiomass: ${object.properties.biomass_kg} kg`;
            }
            if (object.properties?.cluster_id) {
              return `Outbreak Cluster\nPonds Affected: ${object.properties.pond_count}\nDominant Risk: ${object.properties.dominant_risk}`;
            }
            return null;
          }}
        >
          <Map
            mapStyle={isDark ? MAP_STYLE_DARK : MAP_STYLE_LIGHT}
            attributionControl={false}
          />
        </DeckGL>

        {/* UI Control Overlay Panel */}
        <div className="absolute top-4 left-4 z-10 w-80 bg-white/95 dark:bg-[#0A0E13]/95 backdrop-blur-md p-4 rounded-xl border border-surface-border dark:border-surface-darkBorder shadow-lg">
          <div className="flex items-center gap-2 mb-4 pb-3 border-b border-surface-border dark:border-surface-darkBorder">
            <Layers className="w-5 h-5 text-teal-600 dark:text-teal-400" />
            <div>
              <h2 className="text-sm font-bold text-ocean-900 dark:text-slate-100 font-mono tracking-tight">
                AquaVerse Map Intelligence
              </h2>
              <p className="text-[10px] text-slate-500 font-sans">
                Deck.GL HW-Accelerated Topology Rendering
              </p>
            </div>
          </div>

          <div className="space-y-4">
            {/* Filter: District */}
            <div className="space-y-1.5">
              <label className="text-[11px] font-mono font-bold text-slate-600 dark:text-slate-400 uppercase">
                Filter by District
              </label>
              <select
                value={filterDistrict}
                onChange={(e) => setFilterDistrict(e.target.value)}
                className="w-full text-xs font-mono p-2 rounded-lg bg-surface-cardSubtle dark:bg-surface-darkCardAlt border border-surface-border dark:border-surface-darkBorder text-ocean-900 dark:text-slate-200 outline-none focus:ring-1 focus:ring-teal-500"
              >
                <option value="All">All Districts</option>
                <option value="Coimbatore">Coimbatore</option>
                <option value="Nagapattinam">Nagapattinam</option>
                <option value="Tiruppur">Tiruppur</option>
              </select>
            </div>

            {/* Filter: Risk Band */}
            <div className="space-y-1.5">
              <label className="text-[11px] font-mono font-bold text-slate-600 dark:text-slate-400 uppercase">
                Filter by Risk Band
              </label>
              <select
                value={filterRisk}
                onChange={(e) => setFilterRisk(e.target.value)}
                className="w-full text-xs font-mono p-2 rounded-lg bg-surface-cardSubtle dark:bg-surface-darkCardAlt border border-surface-border dark:border-surface-darkBorder text-ocean-900 dark:text-slate-200 outline-none focus:ring-1 focus:ring-teal-500"
              >
                <option value="All">All Risks</option>
                <option value="Critical">Critical</option>
                <option value="High">High</option>
                <option value="Medium">Medium</option>
                <option value="Low">Low</option>
              </select>
            </div>
            
            {/* Map Legend */}
            <div className="pt-2">
              <span className="text-[11px] font-mono font-bold text-slate-600 dark:text-slate-400 uppercase block mb-2">
                Legend (Biomass Scale)
              </span>
              <div className="space-y-1.5 text-[10px] font-mono text-slate-600 dark:text-slate-300">
                <div className="flex items-center gap-2">
                  <span className="w-3 h-3 rounded-full bg-[#dc3545] border border-white" />
                  <span>Critical Risk</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-3 h-3 rounded-full bg-[#e8a33d] border border-white" />
                  <span>Elevated Risk</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-3 h-3 rounded-full bg-[#4fbfa0] border border-white" />
                  <span>Optimal</span>
                </div>
                <div className="flex items-center gap-2">
                  <span className="w-3 h-3 rounded-full bg-slate-400 border border-white" />
                  <span>Blind State (Suppressed)</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
