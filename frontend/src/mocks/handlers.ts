import { http, HttpResponse } from 'msw';

// EXCLUSIVELY THE 3 COIMBATORE LAKES REQUESTED BY USER:
// 1. CBE-001: Singanallur Lake (10.99009308182897° N, 77.02184251180928° E)
// 2. CBE-002: Ukkadam Periyakulam (10.98263595587382° N, 76.95542994444632° E)
// 3. CBE-003: Valankulam Tank (10.992199162944685° N, 76.97208109809374° E)
export const mockPonds = [
  {
    pond_id: 'CBE-003',
    farmer_name: 'Valankulam Tank Aqua Unit (Farmer 3)',
    district: 'Coimbatore',
    taluk: 'Coimbatore Urban',
    species: 'Penaeus vannamei',
    doc: 52,
    area_ha: 2.4,
    depth_m: 1.5,
    water_source: 'Noyyal Basin Feeder Canal',
    biomass_kg: 7400,
    current_risk: 0.78,
    risk_band: 'high',
    blind_state: false,
    suppression_reason: null,
    lat: 10.992199,
    lng: 76.972081,
    fcr: 2.15,
  },
  {
    pond_id: 'CBE-001',
    farmer_name: 'Singanallur Lake Farm (Farmer 1)',
    district: 'Coimbatore',
    taluk: 'Coimbatore South',
    species: 'Penaeus vannamei',
    doc: 48,
    area_ha: 1.8,
    depth_m: 1.4,
    water_source: 'Noyyal Basin Feeder Canal',
    biomass_kg: 5200,
    current_risk: 0.68,
    risk_band: 'high',
    blind_state: false,
    suppression_reason: null,
    lat: 10.990093,
    lng: 77.021843,
    fcr: 1.92,
  },
  {
    pond_id: 'CBE-002',
    farmer_name: 'Ukkadam Periyakulam Unit (Farmer 2)',
    district: 'Coimbatore',
    taluk: 'Coimbatore South',
    species: 'Labeo rohita',
    doc: 65,
    area_ha: 2.1,
    depth_m: 1.6,
    water_source: 'Noyyal Basin Feeder Canal',
    biomass_kg: 6800,
    current_risk: 0.45,
    risk_band: 'medium',
    blind_state: false,
    suppression_reason: null,
    lat: 10.982636,
    lng: 76.955430,
    fcr: 1.42,
  },
];

export const handlers = [
  http.post('/v1/auth/token', () => {
    return HttpResponse.json({
      access_token: 'mock-jwt-token-analyst-role-12345',
      token_type: 'Bearer',
      role: 'analyst',
    });
  }),

  http.get('/v1/ponds', () => {
    return HttpResponse.json({
      items: mockPonds,
      next_cursor: null,
    });
  }),

  http.get('/v1/ponds/:pond_id', ({ params }: { params: any }) => {
    const pond = mockPonds.find(p => p.pond_id === params.pond_id) || mockPonds[0];
    return HttpResponse.json(pond);
  }),

  http.get('/v1/ponds/:pond_id/timeseries', () => {
    const now = new Date();
    const timestamps: string[] = [];
    const do_series: (number | null)[] = [];
    const ph_series: (number | null)[] = [];
    const temp_series: (number | null)[] = [];
    const tan_series: (number | null)[] = [];

    for (let i = 72; i >= 0; i--) {
      const t = new Date(now.getTime() - i * 3600 * 1000);
      timestamps.push(t.toISOString().slice(0, 16));
      
      const hour = t.getHours();
      const doVal = Number((5.5 + 2.2 * Math.sin(((hour - 10) / 24) * 2 * Math.PI) + (Math.random() * 0.4 - 0.2)).toFixed(2));
      const phVal = Number((8.1 + 0.4 * Math.sin(((hour - 12) / 24) * 2 * Math.PI)).toFixed(2));
      const tempVal = Number((28.5 + 2.0 * Math.sin(((hour - 14) / 24) * 2 * Math.PI)).toFixed(2));
      const tanVal = Number((0.15 + (72 - i) * 0.005 + Math.random() * 0.02).toFixed(2));

      do_series.push(doVal < 0 ? 0.5 : doVal);
      ph_series.push(phVal);
      temp_series.push(tempVal);
      tan_series.push(tanVal);
    }

    return HttpResponse.json({
      timestamps,
      series: {
        DO: do_series,
        pH: ph_series,
        Temperature: temp_series,
        TAN: tan_series,
      },
    });
  }),

  http.get('/v1/ponds/:pond_id/events', () => {
    return HttpResponse.json([
      { event_id: 'ev-1', timestamp: '2026-08-12T06:00:00Z', type: 'feed', title: 'Feed Input', details: '50 kg grower feed applied in Valankulam Tank (10.9922°N, 76.9721°E)' },
      { event_id: 'ev-2', timestamp: '2026-08-11T18:00:00Z', type: 'water_exchange', title: 'Water Exchange', details: '12% volume exchanged via Noyyal feeder canal to Singanallur Lake (10.9901°N, 77.0218°E)' },
      { event_id: 'ev-3', timestamp: '2026-08-10T14:30:00Z', type: 'rain', title: 'Rainfall Event', details: '32 mm monsoon downpour recorded in Ukkadam Periyakulam (10.9826°N, 76.9554°E)' },
    ]);
  }),

  http.get('/v1/ponds/:pond_id/risk', ({ params }: { params: any }) => {
    const pId = params.pond_id || 'CBE-003';
    
    if (pId === 'CBE-001') {
      // Singanallur Lake (10.990093°N, 77.021843°E)
      return HttpResponse.json({
        pond_id: 'CBE-001',
        as_of: new Date().toISOString(),
        model_version: { numeric: 'm2-ebm-0.4.1', adapter: 'm1_chemistry-lora-1.0.0' },
        risk: 0.68,
        risk_delta_24h: 0.22,
        calibration: { brier_1m: 0.08, reliability: 'ok' },
        modality_gate: { timeseries: 0.72, image: 0.20, static: 0.08 },
        top_temporal_features: [
          { feature: 'night_DO_min', value: 2.4, unit: 'mg/L', attribution: 0.35, window: '0200-0500, Singanallur Lake (10.9901°N, 77.0218°E)' },
          { feature: 'TAN_slope_3d', value: 0.19, unit: 'mg/L/day', attribution: 0.21, window: 'Singanallur feeder canal' },
          { feature: 'pH_diurnal_delta', value: 0.86, unit: 'pH units', attribution: 0.14, window: 'last 24h' },
        ],
        concepts: { white_spots: 0.06, empty_gut: 0.76, white_gut_line: 0.62, gill_discolouration: 0.15 },
        image_age_hours: 12,
        nearest_cases: [
          { pond: 'CBE-001', outcome: 'Singanallur overnight DO crash averted', similarity: 0.94 },
          { pond: 'CBE-003', outcome: 'Valankulam TAN managed', similarity: 0.87 },
        ],
        blind_state: false,
        suppression_reason: null,
      });
    }

    if (pId === 'CBE-002') {
      // Ukkadam Periyakulam (10.982636°N, 76.955430°E)
      return HttpResponse.json({
        pond_id: 'CBE-002',
        as_of: new Date().toISOString(),
        model_version: { numeric: 'm2-ebm-0.4.1', adapter: 'm1_chemistry-lora-1.0.0' },
        risk: 0.45,
        risk_delta_24h: 0.08,
        calibration: { brier_1m: 0.07, reliability: 'ok' },
        modality_gate: { timeseries: 0.68, image: 0.22, static: 0.10 },
        top_temporal_features: [
          { feature: 'TAN_level', value: 0.18, unit: 'mg/L', attribution: 0.28, window: 'Ukkadam Periyakulam (10.9826°N, 76.9554°E)' },
          { feature: 'night_DO_min', value: 3.4, unit: 'mg/L', attribution: 0.22, window: '0300-0500' },
          { feature: 'pH_diurnal_delta', value: 0.65, unit: 'pH units', attribution: 0.12, window: 'last 24h' },
        ],
        concepts: { white_spots: 0.02, empty_gut: 0.42, white_gut_line: 0.35, gill_discolouration: 0.08 },
        image_age_hours: 8,
        nearest_cases: [
          { pond: 'CBE-002', outcome: 'Ukkadam optimal Rohu growth', similarity: 0.96 },
        ],
        blind_state: false,
        suppression_reason: null,
      });
    }

    // CBE-003 Valankulam Tank (10.992199°N, 76.972081°E)
    return HttpResponse.json({
      pond_id: 'CBE-003',
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
    });
  }),

  http.get('/v1/risk/worklist', () => {
    const cbeTriageList = [
      {
        pond_id: 'CBE-003',
        farmer_name: 'Valankulam Tank Aqua Unit (Farmer 3)',
        district: 'Coimbatore',
        species: 'Penaeus vannamei',
        doc: 52,
        biomass_kg: 7400,
        risk: 0.78,
        risk_delta_24h: 0.28,
        risk_biomass_score: 5772,
        top_driver: 'Valankulam Tank (10.9922°N, 76.9721°E) overnight DO drop below 2.1 mg/L',
        last_contact: '20 mins ago',
        data_health: 'Optimal',
        blind_state: false,
      },
      {
        pond_id: 'CBE-001',
        farmer_name: 'Singanallur Lake Farm (Farmer 1)',
        district: 'Coimbatore',
        species: 'Penaeus vannamei',
        doc: 48,
        biomass_kg: 5200,
        risk: 0.68,
        risk_delta_24h: 0.22,
        risk_biomass_score: 3536,
        top_driver: 'Singanallur Lake (10.9901°N, 77.0218°E) TAN slope 0.19 mg/L/day',
        last_contact: '45 mins ago',
        data_health: 'Optimal',
        blind_state: false,
      },
      {
        pond_id: 'CBE-002',
        farmer_name: 'Ukkadam Periyakulam Unit (Farmer 2)',
        district: 'Coimbatore',
        species: 'Labeo rohita',
        doc: 65,
        biomass_kg: 6800,
        risk: 0.45,
        risk_delta_24h: 0.08,
        risk_biomass_score: 3060,
        top_driver: 'Ukkadam Periyakulam (10.9826°N, 76.9554°E) pH diurnal amplitude 0.65',
        last_contact: '1 hour ago',
        data_health: 'Optimal',
        blind_state: false,
      },
    ];

    return HttpResponse.json(cbeTriageList);
  }),

  http.get('/v1/ponds/:pond_id/forecast/do', ({ params }: { params: any }) => {
    const now = new Date();
    const timestamps: string[] = [];
    const p50: number[] = [];
    const p10: number[] = [];
    const p90: number[] = [];

    for (let i = 1; i <= 72; i++) {
      const t = new Date(now.getTime() + i * 3600 * 1000);
      timestamps.push(t.toISOString().slice(0, 16));
      const hour = t.getHours();
      
      const baseDO = 5.2 + 2.0 * Math.sin(((hour - 10) / 24) * 2 * Math.PI);
      const med = Number(baseDO.toFixed(2));
      const low = Number((baseDO * 0.82).toFixed(2));
      const high = Number((baseDO * 1.18).toFixed(2));

      p50.push(med);
      p10.push(low);
      p90.push(high);
    }

    return HttpResponse.json({
      pond_id: params.pond_id,
      timestamps,
      forecast_p50: p50,
      forecast_p10: p10,
      forecast_p90: p90,
      overnight_minimum_0400: 2.10,
      confidence_level: 'High (Calibrated on Valankulam, Singanallur, Ukkadam Noyyal Basin datasets)',
    });
  }),

  http.get('/v1/geo/ponds', () => {
    const features = mockPonds.map((p) => ({
      type: 'Feature',
      geometry: {
        type: 'Point',
        coordinates: [p.lng, p.lat],
      },
      properties: {
        pond_id: p.pond_id,
        farmer: p.farmer_name,
        district: p.district,
        risk: p.current_risk,
        risk_band: p.risk_band,
        biomass_kg: p.biomass_kg,
        blind_state: p.blind_state,
      },
    }));

    return HttpResponse.json({
      type: 'FeatureCollection',
      features,
    });
  }),

  http.get('/v1/geo/clusters', () => {
    return HttpResponse.json({
      type: 'FeatureCollection',
      features: [
        {
          type: 'Feature',
          properties: {
            cluster_id: 'CBE-CL-COIMBATORE-3',
            district: 'Coimbatore',
            p_value: 0.0006,
            relative_risk: 4.12,
            primary_driver: 'Coimbatore 3 Lakes (Valankulam 10.9922°N, Singanallur 10.9901°N, Ukkadam 10.9826°N) Outbreak Risk Cluster',
          },
          geometry: {
            type: 'Polygon',
            coordinates: [[
              [76.940, 10.970],
              [77.040, 10.970],
              [77.040, 11.020],
              [76.940, 11.020],
              [76.940, 10.970],
            ]],
          },
        },
      ],
      topology_edges: [
        { source_pond: 'CBE-001', target_pond: 'CBE-003', type: 'Singanallur to Valankulam Feeder Canal' },
        { source_pond: 'CBE-003', target_pond: 'CBE-002', type: 'Valankulam to Ukkadam Noyyal Connector' },
      ],
    });
  }),

  http.get('/v1/twin/:pond_id/state', ({ params }: { params: any }) => {
    return HttpResponse.json({
      pond_id: params.pond_id,
      timestamp: new Date().toISOString(),
      do_mg_l: 4.6,
      ph: 8.3,
      temp_c: 28.5,
      tan_mg_l: 0.52,
      no2_mg_l: 0.14,
      salinity_ppt: 12.0,
      alkalinity_mg_l: 115,
      biomass_kg: 7400,
      water_clarity_cm: 30,
    });
  }),

  http.post('/v1/twin/:pond_id/whatif', async ({ request, params }: { request: Request; params: any }) => {
    const body = await request.json() as any;
    const aerate = body.aeration_hours || 8;
    const waterEx = body.water_exchange_rate || 0;

    return HttpResponse.json({
      pond_id: params.pond_id,
      timestamp: new Date().toISOString(),
      do_mg_l: Number((4.6 + aerate * 0.28).toFixed(2)),
      ph: 8.1,
      temp_c: 28.2,
      tan_mg_l: Number((0.52 * (1 - waterEx / 100)).toFixed(2)),
      no2_mg_l: 0.07,
      salinity_ppt: 12.0,
      alkalinity_mg_l: 122,
      biomass_kg: 7400,
      water_clarity_cm: 34,
    });
  }),

  http.post('/v1/reason', async ({ request }: { request: Request }) => {
    const body = await request.json() as any;
    const adapter = body.adapter || 'm1_chemistry';

    if (adapter === 'm1_chemistry') {
      return HttpResponse.json({
        explanation: 'Dissolved oxygen minimum across Valankulam Tank (10.9922°N, 76.9721°E), Singanallur (10.9901°N, 77.0218°E), and Ukkadam (10.9826°N, 76.9554°E) is projected at 2.1 mg/L at 04:00 due to night algal respiration & Noyyal basin TAN oxidation. Nitrification consumes 4.18 g of O2 per g of TAN oxidised (Ebeling et al., 2006).',
        reasoning_trace: 'Step 1: TAN elevated at 0.52 mg/L across Valankulam-Singanallur canal link. Step 2: Calculate NH3 equilibrium using pKa ~ 9.25 (Emerson et al., 1975). Step 3: Compute nitrifying bacterial oxygen demand (4.18 g O2/g TAN). Step 4: Confirm by manual 04:00 DO check.',
        recommendations: [
          'Run paddlewheel aerators between 23:00 and 06:00 in Valankulam Tank (CBE-003).',
          'Cut morning feed by 20% in Singanallur Lake (CBE-001) to reduce TAN buildup.',
          'Apply 15 kg/ha agricultural lime to stabilize pH in Ukkadam Periyakulam (CBE-002).',
        ],
      });
    }

    return HttpResponse.json({
      explanation: 'General advisory for Valankulam & Coimbatore 3 Lakes.',
      reasoning_trace: 'Standard inference trace.',
      recommendations: ['Monitor parameters closely.'],
    });
  }),

  http.get('/v1/alerts', () => {
    return HttpResponse.json([
      { alert_id: 'alt-cbe-301', pond_id: 'CBE-003', district: 'Coimbatore', timestamp: '2026-08-13T04:15:00Z', severity: 'critical', title: 'Valankulam Tank (10.9922°N, 76.9721°E) DO Minimum Warning', message: 'Projected 04:00 DO minimum of 2.1 mg/L violates 3.0 mg/L threshold.', suppressed: false, suppression_reason: null, acknowledged: false },
      { alert_id: 'alt-cbe-302', pond_id: 'CBE-001', district: 'Coimbatore', timestamp: '2026-08-13T03:30:00Z', severity: 'warning', title: 'Singanallur Lake (10.9901°N, 77.0218°E) TAN Accumulation', message: 'TAN accumulated +0.19 mg/L/day over 72 hours.', suppressed: false, suppression_reason: null, acknowledged: false },
      { alert_id: 'alt-cbe-303', pond_id: 'CBE-002', district: 'Coimbatore', timestamp: '2026-08-13T02:00:00Z', severity: 'info', title: 'Ukkadam Periyakulam (10.9826°N, 76.9554°E) Telemetry Normal', message: 'Water quality parameters within safe threshold.', suppressed: false, suppression_reason: null, acknowledged: true },
    ]);
  }),

  http.get('/v1/models', () => {
    return HttpResponse.json({
      active_models: [
        { name: 'M1 Chemistry Reasoner', adapter: 'm1_chemistry-lora-1.0.0', base: 'Qwen3-8B', dataset_hash: 'sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' },
        { name: 'Quantitative EBM Core', version: 'm2-ebm-0.4.1', type: 'LightGBM + Temporal', dataset_hash: 'sha256:8f434346648f6b96df89dda901c5176b10a6d83961dd3c1ac88b59b2dc327aa4' },
      ],
      changelog: [
        { date: '2026-08-07', version: '1.0.0', author: 'Suchit', notes: 'Initial QLoRA fine-tune on 15k simulator & Kisan Call Centre pairs' },
      ],
    });
  }),

  http.get('/v1/models/metrics', () => {
    return HttpResponse.json({
      calibration_curve: [
        { bin: '0.0 - 0.2', predicted: 0.10, observed: 0.09 },
        { bin: '0.2 - 0.4', predicted: 0.30, observed: 0.31 },
        { bin: '0.4 - 0.6', predicted: 0.50, observed: 0.48 },
        { bin: '0.6 - 0.8', predicted: 0.70, observed: 0.72 },
        { bin: '0.8 - 1.0', predicted: 0.90, observed: 0.89 },
      ],
      auc_pr: 0.884,
      brier_score: 0.082,
      lead_time_hours: 14.5,
      false_alarms_per_pond_week: 0.12,
      number_hallucination_violations: 0,
    });
  }),

  http.get('/v1/models/drift', () => {
    return HttpResponse.json({
      psi_by_feature: [
        { feature: 'DO_overnight_min', psi: 0.03, status: 'Stable' },
        { feature: 'TAN_level', psi: 0.06, status: 'Stable' },
        { feature: 'pH_diurnal_amplitude', psi: 0.12, status: 'Moderate Shift' },
        { feature: 'Temperature', psi: 0.02, status: 'Stable' },
      ],
    });
  }),

  http.get('/v1/data-quality', () => {
    return HttpResponse.json({
      total_ponds: 3,
      active_sensors: 3,
      blind_state_ponds: 0,
      stuck_value_alerts: 0,
      calibration_due_count: 1,
      suppressed_alerts_count: 0,
      recent_registers: [
        { pond_id: 'CBE-003', lake: 'Valankulam Tank (10.9922°N, 76.9721°E)', status: 'Optimal', last_seen: '2 mins ago' },
        { pond_id: 'CBE-001', lake: 'Singanallur Lake (10.9901°N, 77.0218°E)', status: 'Optimal', last_seen: '5 mins ago' },
        { pond_id: 'CBE-002', lake: 'Ukkadam Periyakulam (10.9826°N, 76.9554°E)', status: 'Optimal', last_seen: '8 mins ago' },
      ],
    });
  }),

  http.post('/v1/translate', async ({ request }: { request: Request }) => {
    const body = await request.json() as any;
    const text = body.text || '';
    return HttpResponse.json({
      translated_text: `[Tamil Translated]: ${text} (வலங்குளம் 10.9922°N, சிங்காநல்லூர் 10.9901°N, உக்கடம் 10.9826°N - கோவை 3 குளங்களின் இரவு 04:00 மணி ஆக்ஸிஜன் அளவு முன்னறிவிப்பு.)`,
      cached: true,
    });
  }),

  http.get('/v1/advisories', () => {
    return HttpResponse.json([
      { advisory_id: 'adv-cbe-301', timestamp: '2026-08-10T10:00:00Z', target_segment: 'Coimbatore 3 Lakes Segment', text_en: 'Valankulam (10.9922°N, 76.9721°E), Singanallur (10.9901°N, 77.0218°E), and Ukkadam (10.9826°N, 76.9554°E) feeder canal advisory.', text_ta: 'கோவை 3 குளங்களின் நொய்யல் பாசன நீர் மேலாண்மை முன்னறிவிப்பு.', approved_by: 'Suchit (Extension Lead)', delivered_count: 210, read_count: 195 },
    ]);
  }),

  http.post('/v1/advisories/broadcast', async ({ request }: { request: Request }) => {
    const body = await request.json() as any;
    return HttpResponse.json({
      broadcast_id: `adv-${Date.now()}`,
      status: 'Sent to SMS & Mobile Push Gateway',
      target_segment: body.target_segment,
    });
  }),

  http.get('/v1/reports/export', () => {
    return HttpResponse.json({
      download_url: '/exports/aquaverse_coimbatore_3_lakes_report_20260813.pdf',
    });
  }),

  // Farmer Phone OTP Auth
  http.post('/v1/auth/otp/request', async ({ request }: { request: Request }) => {
    const body = (await request.json()) as any;
    return HttpResponse.json({
      status: `OTP sent successfully to ${body.phone || 'farmer phone'}`,
      txn_id: `txn_otp_${Date.now()}`,
    });
  }),

  http.post('/v1/auth/otp/verify', async ({ request }: { request: Request }) => {
    const body = (await request.json()) as any;
    return HttpResponse.json({
      access_token: `mock-jwt-farmer-${Date.now()}`,
      token_type: 'Bearer',
      role: 'farmer',
      farmer_name: `Farmer (${body.phone || '9876543210'})`,
    });
  }),

  // Telemetry & Water-Quality Log Ingestion
  http.post('/v1/logs', async ({ request }: { request: Request }) => {
    const body = (await request.json()) as any;
    return HttpResponse.json(
      {
        log_id: `log-${Date.now()}`,
        status: 'ingested',
        timestamp: new Date().toISOString(),
        details: body,
      },
      { status: 201 }
    );
  }),

  // Presigned S3/MinIO Object Storage & Media Commit
  http.post('/v1/media/presign', async ({ request }: { request: Request }) => {
    const body = (await request.json()) as any;
    const key = `uploads/${body.pond_id || 'CBE-003'}/${Date.now()}-${body.filename || 'image.jpg'}`;
    return HttpResponse.json({
      upload_url: `https://minio.aquaverse.internal/uploads/${key}?presigned=true&sig=abc123xyz`,
      asset_key: key,
      expires_at: new Date(Date.now() + 15 * 60 * 1000).toISOString(),
    });
  }),

  http.post('/v1/media/commit', async ({ request }: { request: Request }) => {
    const body = (await request.json()) as any;
    return HttpResponse.json({
      asset_id: `asset-${Date.now()}`,
      status: 'committed',
      asset_key: body.asset_key,
    });
  }),

  // Multi-variable Temporal Model Forecasts (TFT / TCN / PatchTST)
  http.get('/v1/forecast/temporal', ({ request }: { request: Request }) => {
    const url = new URL(request.url);
    const pondId = url.searchParams.get('pond_id') || 'CBE-003';
    const modelFamily = url.searchParams.get('model_family') || 'TFT';
    const horizon = parseInt(url.searchParams.get('horizon_hours') || '72', 10);

    const now = new Date();
    const timestamps: string[] = [];
    const forecast_do: number[] = [];
    const forecast_ph: number[] = [];
    const forecast_temp: number[] = [];
    const do_p10: number[] = [];
    const do_p90: number[] = [];

    for (let i = 1; i <= horizon; i++) {
      const t = new Date(now.getTime() + i * 3600 * 1000);
      timestamps.push(t.toISOString().slice(0, 16));
      const hour = t.getHours();
      const baseDO = 5.2 + 2.1 * Math.sin(((hour - 10) / 24) * 2 * Math.PI);
      const doVal = Number(Math.max(0.8, baseDO).toFixed(2));
      forecast_do.push(doVal);
      do_p10.push(Number(Math.max(0.4, doVal - 0.7).toFixed(2)));
      do_p90.push(Number((doVal + 0.6).toFixed(2)));

      forecast_ph.push(Number((8.0 + 0.3 * Math.sin(((hour - 12) / 24) * 2 * Math.PI)).toFixed(2)));
      forecast_temp.push(Number((29.0 + 1.8 * Math.sin(((hour - 14) / 24) * 2 * Math.PI)).toFixed(2)));
    }

    return HttpResponse.json({
      pond_id: pondId,
      model_family: modelFamily,
      horizon_hours: horizon,
      timestamps,
      forecast_do,
      forecast_ph,
      forecast_temp,
      confidence_interval: {
        do_p10,
        do_p90,
      },
    });
  }),

  // Farmer-Facing Conversational Q&A (vLLM Qwen3-8B + IndicTrans2 + TTS)
  http.post('/v1/ask', async ({ request }: { request: Request }) => {
    const body = (await request.json()) as any;
    const question = body.question || 'How is my pond DO tonight?';
    const lang = body.lang || 'en';

    const englishAnswer = `For pond ${body.pond_id || 'CBE-003'} (Valankulam Tank), predicted 04:00 AM DO is 2.8 mg/L. Run aerator 2 between 03:00 AM and 06:00 AM. Maintain feeding at normal rate.`;
    const tamilAnswer = `குளம் ${body.pond_id || 'CBE-003'} (வலங்குளம் ஏரி) க்கு அதிகாலை 04:00 மணி கரைந்த ஆக்ஸிஜன் 2.8 mg/L ஆகும். அதிகாலை 03:00 முதல் 06:00 மணி வரை ஏரேட்டரை இயக்கவும்.`;

    return HttpResponse.json({
      answer: englishAnswer,
      translated_answer: lang === 'ta' ? tamilAnswer : englishAnswer,
      audio_url: body.voice_tts ? '/audio/speech_output_ta_1002.mp3' : null,
      confidence: 0.94,
      sources: ['vLLM Qwen3-8B + M1 Chemistry Adapter', 'TimescaleDB DO Forecast Stream', 'IndicTrans2 Translation Engine'],
    });
  }),
];
