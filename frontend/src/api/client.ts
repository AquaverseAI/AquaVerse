/** Single authenticated transport for every browser-to-FastAPI request. */
export interface ApiProblem { type?: string; title?: string; status?: number; detail?: string; [key: string]: unknown }

export class ApiError extends Error {
  constructor(public readonly status: number, message: string, public readonly problem?: ApiProblem) {
    super(message);
    this.name = 'ApiError';
  }
}

export function clearSession(): void {
  localStorage.removeItem('auth_token');
  localStorage.removeItem('auth_user');
}

export function setSession(token: string, user: object): void {
  localStorage.setItem('auth_token', token);
  localStorage.setItem('auth_user', JSON.stringify(user));
}

function buildUrl(path: string, query?: Record<string, unknown>): string {
  const params = new URLSearchParams();
  Object.entries(query ?? {}).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') params.set(key, String(value));
  });
  const encoded = params.toString();
  return encoded ? `${path}${path.includes('?') ? '&' : '?'}${encoded}` : path;
}

export async function apiRequest<T>(path: string, options: RequestInit & { query?: Record<string, unknown> } = {}): Promise<T> {
  const { query, ...requestOptions } = options;
  const headers = new Headers(requestOptions.headers);
  const token = localStorage.getItem('auth_token');
  if (token) headers.set('Authorization', `Bearer ${token}`);
  if (requestOptions.body && !(requestOptions.body instanceof FormData) && !headers.has('Content-Type')) headers.set('Content-Type', 'application/json');
  const response = await fetch(buildUrl(path, query), { ...requestOptions, headers });
  if (!response.ok) {
    let problem: ApiProblem | undefined;
    try { problem = (await response.json()) as ApiProblem; } catch { /* non-JSON upstream error */ }
    if (response.status === 401 && token) {
      clearSession();
      window.dispatchEvent(new Event('aquaverse:unauthorized'));
    }
    throw new ApiError(response.status, problem?.detail || problem?.title || `Request failed with status ${response.status}`, problem);
  }
  if (response.status === 204) return undefined as T;
  return (await response.json()) as T;
}

const json = (value: unknown) => JSON.stringify(value);

export const authApi = {
  loginToken: (username: string, password: string) => apiRequest<any>('/v1/auth/token', { method: 'POST', body: json({ grant_type: 'password', username, password }) }),
  requestOTP: (phone: string) => apiRequest<any>('/v1/auth/otp/request', { method: 'POST', body: json({ phone }) }),
  verifyOTP: (phone: string, requestId: string, otp: string) => apiRequest<any>('/v1/auth/otp/verify', { method: 'POST', body: json({ phone, request_id: requestId, otp }) }),
  me: () => apiRequest<any>('/v1/auth/me'),
};

export const pondsApi = {
  listPonds: (query?: Record<string, unknown>) => apiRequest<any>('/v1/ponds', { query }),
  getPondDetail: (pondId: string) => apiRequest<any>(`/v1/ponds/${pondId}`),
  getPondTimeseries: (pondId: string, query?: Record<string, unknown>) => apiRequest<any>(`/v1/ponds/${pondId}/timeseries`, { query }),
  getPondEvents: (pondId: string) => apiRequest<any>(`/v1/ponds/${pondId}/events`),
  getPondRisk: (pondId: string) => apiRequest<any>(`/v1/ponds/${pondId}/risk`),
};

export const logsApi = {
  listLogs: (query?: Record<string, unknown>) => apiRequest<any>('/v1/logs', { query }),
  ingestLog: (body: unknown) => apiRequest<any>('/v1/logs', { method: 'POST', body: json(body) }),
};

export const mediaApi = {
  presignUpload: (body: unknown) => apiRequest<any>('/v1/media/upload-url', { method: 'POST', body: json(body) }),
  uploadToStorage: async (uploadUrl: string, file: File) => {
    const response = await fetch(uploadUrl, { method: 'PUT', body: file, headers: { 'Content-Type': file.type } });
    if (!response.ok) throw new ApiError(response.status, 'Object storage upload failed');
  },
  commitUpload: (mediaId: string, pondId: string) => apiRequest<any>(`/v1/media/${mediaId}/commit`, { method: 'POST', body: json({ pond_id: pondId }) }),
};

export const riskApi = { getWorklist: (query?: Record<string, unknown>) => apiRequest<any>('/v1/risk/worklist', { query }) };
export const forecastApi = { getDOForecast: (pondId: string) => apiRequest<any>(`/v1/ponds/${pondId}/forecast/do`) };
export const geoApi = {
  getPondsGeoJSON: (query?: Record<string, unknown>) => apiRequest<any>('/v1/geo/ponds', { query }),
  getClustersTopology: (query?: Record<string, unknown>) => apiRequest<any>('/v1/geo/clusters', { query }),
};
export const twinApi = {
  getState: (pondId: string) => apiRequest<any>(`/v1/twin/${pondId}/state`),
  runWhatIf: (pondId: string, intervention: unknown) => apiRequest<any>(`/v1/twin/${pondId}/whatif`, { method: 'POST', body: json(intervention) }),
};
export const askApi = { askAssistant: (query: unknown) => apiRequest<any>('/v1/ask', { method: 'POST', body: json(query) }) };
export const alertsApi = {
  getAlerts: (query?: Record<string, unknown>) => apiRequest<any>('/v1/alerts', { query }),
  ackAlert: (alertId: string) => apiRequest<any>(`/v1/alerts/${alertId}/ack`, { method: 'POST' }),
  submitFeedback: (alertId: string, body: unknown) => apiRequest<any>(`/v1/alerts/${alertId}/feedback`, { method: 'POST', body: json(body) }),
};
export const advisoriesApi = {
  getAdvisories: (query?: Record<string, unknown>) => apiRequest<any>('/v1/advisories', { query }),
  broadcast: (body: unknown) => apiRequest<any>('/v1/advisories/broadcast', { method: 'POST', body: json(body) }),
};
export const modelsApi = {
  getModels: () => apiRequest<any>('/v1/models'),
  getMetrics: () => apiRequest<any>('/v1/models/metrics'),
  getDrift: () => apiRequest<any>('/v1/models/drift'),
};
export const translateApi = { translate: (text: string, targetLang: string) => apiRequest<any>('/v1/translate', { method: 'POST', body: json({ text, target_lang: targetLang }) }) };
export const dataQualityApi = { getDataQuality: () => apiRequest<any>('/v1/data-quality') };
export const reportsApi = {
  exportReport: (format: 'pdf' | 'xlsx', district?: string) => apiRequest<any>('/v1/reports/export', { query: { format, district } }),
  getExportStatus: (jobId: string) => apiRequest<any>(`/v1/reports/export/${jobId}`),
};
