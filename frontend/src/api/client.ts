import type { components, paths } from './generated-sdk';

/**
 * AquaVerse API Client
 * Wraps all 16 backend endpoints defined in openapi.yaml
 */

async function fetchApi<T>(endpoint: string, options?: RequestInit): Promise<T> {
  const token = localStorage.getItem('auth_token');
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...options?.headers,
  };

  if (token) {
    (headers as Record<string, string>)['Authorization'] = `Bearer ${token}`;
  }

  const res = await fetch(endpoint, {
    headers,
    ...options,
  });

  if (!res.ok) {
    const errorText = await res.text();
    throw new Error(`API Error ${res.status}: ${errorText}`);
  }

  return res.json();
}

// 1. Auth API (/v1/auth/*)
export const authApi = {
  loginToken: (credentials: { username: string; password?: string }) =>
    fetchApi<paths['/v1/auth/token']['post']['responses']['200']['content']['application/json']>(
      '/v1/auth/token',
      { method: 'POST', body: JSON.stringify(credentials) }
    ),
  requestOTP: (phone: string) =>
    fetchApi<paths['/v1/auth/otp/request']['post']['responses']['200']['content']['application/json']>(
      '/v1/auth/otp/request',
      { method: 'POST', body: JSON.stringify({ phone }) }
    ),
  verifyOTP: (phone: string, otp: string, txn_id: string) =>
    fetchApi<paths['/v1/auth/otp/verify']['post']['responses']['200']['content']['application/json']>(
      '/v1/auth/otp/verify',
      { method: 'POST', body: JSON.stringify({ phone, otp, txn_id }) }
    ),
};

// 2. Ponds API (/v1/ponds/*)
export const pondsApi = {
  listPonds: (params?: { district?: string; species?: string; risk_band?: string }) => {
    const query = new URLSearchParams(params as Record<string, string>).toString();
    return fetchApi<paths['/v1/ponds']['get']['responses']['200']['content']['application/json']>(
      `/v1/ponds${query ? `?${query}` : ''}`
    );
  },
  getPondDetail: (pondId: string) =>
    fetchApi<components['schemas']['PondRecord']>(`/v1/ponds/${pondId}`),
  getPondTimeseries: (pondId: string, from?: string, to?: string) =>
    fetchApi<paths['/v1/ponds/{pond_id}/timeseries']['get']['responses']['200']['content']['application/json']>(
      `/v1/ponds/${pondId}/timeseries`
    ),
  getPondEvents: (pondId: string) =>
    fetchApi<components['schemas']['PondEvent'][]>(`/v1/ponds/${pondId}/events`),
  getPondRisk: (pondId: string) =>
    fetchApi<components['schemas']['ExplanationPayload']>(`/v1/ponds/${pondId}/risk`),
};

// 3. Log Ingestion API (/v1/logs)
export const logsApi = {
  ingestLog: (log: components['schemas']['WaterQualityLog']) =>
    fetchApi<paths['/v1/logs']['post']['responses']['201']['content']['application/json']>(
      '/v1/logs',
      { method: 'POST', body: JSON.stringify(log) }
    ),
};

// 4. Media Storage API (/v1/media/*)
export const mediaApi = {
  presignUpload: (req: components['schemas']['PresignRequest']) =>
    fetchApi<components['schemas']['PresignResponse']>('/v1/media/presign', {
      method: 'POST',
      body: JSON.stringify(req),
    }),
  commitUpload: (commit: components['schemas']['MediaCommit']) =>
    fetchApi<{ asset_id: string; status: string }>('/v1/media/commit', {
      method: 'POST',
      body: JSON.stringify(commit),
    }),
};

// 5. ML Risk API (/v1/risk/*)
export const riskApi = {
  getWorklist: () =>
    fetchApi<components['schemas']['TriageItem'][]>('/v1/risk/worklist'),
};

// 6. Forecast API (/v1/forecast/*)
export const forecastApi = {
  getDOForecast: (pondId: string) =>
    fetchApi<components['schemas']['DOForecast']>(`/v1/ponds/${pondId}/forecast/do`),
  getTemporalForecast: (pondId: string, modelFamily: 'TFT' | 'TCN' | 'PatchTST' = 'TFT', horizonHours = 72) =>
    fetchApi<components['schemas']['TemporalForecastPayload']>(
      `/v1/forecast/temporal?pond_id=${pondId}&model_family=${modelFamily}&horizon_hours=${horizonHours}`
    ),
};

// 7. Geo API (/v1/geo/*)
export const geoApi = {
  getPondsGeoJSON: () => fetchApi<object>('/v1/geo/ponds'),
  getClustersTopology: () => fetchApi<object>('/v1/geo/clusters'),
};

// 8. Digital Twin API (/v1/twin/*)
export const twinApi = {
  getState: (pondId: string) =>
    fetchApi<components['schemas']['TwinState']>(`/v1/twin/${pondId}/state`),
  runWhatIf: (pondId: string, intervention: { water_exchange_rate?: number; aeration_hours?: number; feed_reduction_pct?: number }) =>
    fetchApi<components['schemas']['TwinState']>(`/v1/twin/${pondId}/whatif`, {
      method: 'POST',
      body: JSON.stringify(intervention),
    }),
};

// 9. Internal Reasoner API (/v1/reason)
export const reasonApi = {
  getReasoning: (pondId: string, adapter: 'm1_chemistry' | 'm2_health' | 'm3_production') =>
    fetchApi<{ explanation: string; reasoning_trace: string; recommendations: string[] }>('/v1/reason', {
      method: 'POST',
      body: JSON.stringify({ pond_id: pondId, adapter }),
    }),
};

// 10. Farmer Conversational Assistant API (/v1/ask)
export const askApi = {
  askAssistant: (query: components['schemas']['AskQuery']) =>
    fetchApi<components['schemas']['AskResponse']>('/v1/ask', {
      method: 'POST',
      body: JSON.stringify(query),
    }),
};

// 11. Alerts API (/v1/alerts/*)
export const alertsApi = {
  getAlerts: () => fetchApi<components['schemas']['AlertItem'][]>('/v1/alerts'),
  ackAlert: (alertId: string) =>
    fetchApi<{ success: boolean }>(`/v1/alerts/${alertId}/ack`, { method: 'POST' }),
  submitFeedback: (alertId: string, feedback: 'correct' | 'incorrect') =>
    fetchApi<{ recorded: boolean }>(`/v1/alerts/${alertId}/feedback`, {
      method: 'POST',
      body: JSON.stringify({ feedback }),
    }),
};

// 12. Advisories API (/v1/advisories/*)
export const advisoriesApi = {
  getAdvisories: () => fetchApi<components['schemas']['AdvisoryItem'][]>('/v1/advisories'),
  broadcast: (payload: { target_segment: string; text_en: string; approved_by: string }) =>
    fetchApi<{ broadcast_id: string; status: string }>('/v1/advisories/broadcast', {
      method: 'POST',
      body: JSON.stringify(payload),
    }),
};

// 13. Model Registry & Drift API (/v1/models/*)
export const modelsApi = {
  getModels: () => fetchApi<object>('/v1/models'),
  getMetrics: () => fetchApi<object>('/v1/models/metrics'),
  getDrift: () => fetchApi<object>('/v1/models/drift'),
};

// 14. Translation API (/v1/translate)
export const translateApi = {
  translate: (text: string, targetLang: 'ta' | 'te' | 'hi') =>
    fetchApi<{ translated_text: string; cached: boolean }>('/v1/translate', {
      method: 'POST',
      body: JSON.stringify({ text, target_lang: targetLang }),
    }),
};

// 15. Data Quality Signals API (/v1/data-quality)
export const dataQualityApi = {
  getDataQuality: () => fetchApi<object>('/v1/data-quality'),
};

// 16. Reports API (/v1/reports/*)
export const reportsApi = {
  exportReport: (format: 'pdf' | 'xlsx' = 'pdf', district?: string) =>
    fetchApi<{ download_url: string }>(`/v1/reports/export?format=${format}${district ? `&district=${district}` : ''}`),
};
