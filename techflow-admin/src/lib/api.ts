import type {
  ApiEnvelope,
  AuthPayload,
  ClientBootstrap,
  HealthPayload,
  Lead,
  LeadStatus,
  OverviewData,
  PaginationMeta,
  PublicUser,
} from '../types';

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL ?? '';

export class ApiError extends Error {
  status: number;
  code: string;
  details?: string[];

  constructor(message: string, options: { status: number; code: string; details?: string[] }) {
    super(message);
    this.name = 'ApiError';
    this.status = options.status;
    this.code = options.code;
    this.details = options.details;
  }
}

function buildUrl(path: string, query?: Record<string, string | number | undefined>) {
  const url = new URL(`${apiBaseUrl}${path}`, window.location.origin);

  if (query) {
    for (const [key, value] of Object.entries(query)) {
      if (value !== undefined && value !== '') {
        url.searchParams.set(key, String(value));
      }
    }
  }

  return url.toString();
}

async function parseEnvelope<T>(response: Response) {
  const envelope = (await response.json()) as ApiEnvelope<T>;

  if (!response.ok || !envelope.success) {
    throw new ApiError(envelope.error?.message ?? '请求失败', {
      status: response.status,
      code: envelope.error?.code ?? 'REQUEST_FAILED',
      details: envelope.error?.details,
    });
  }

  return envelope;
}

async function request<T>(
  path: string,
  options: {
    method?: 'GET' | 'POST' | 'PATCH';
    token?: string;
    body?: unknown;
    query?: Record<string, string | number | undefined>;
    signal?: AbortSignal;
  } = {},
) {
  const response = await fetch(buildUrl(path, options.query), {
    method: options.method ?? 'GET',
    headers: {
      'Content-Type': 'application/json',
      ...(options.token ? { Authorization: `Bearer ${options.token}` } : {}),
    },
    body: options.body ? JSON.stringify(options.body) : undefined,
    signal: options.signal,
  });

  return parseEnvelope<T>(response);
}

export async function login(phone: string, password: string) {
  return request<AuthPayload>('/api/v1/auth/login', {
    method: 'POST',
    body: { phone, password },
  });
}

export async function refreshSession(refreshToken: string) {
  return request<AuthPayload>('/api/v1/auth/refresh', {
    method: 'POST',
    body: { refreshToken },
  });
}

export async function logout(refreshToken: string) {
  return request<{ loggedOut: boolean }>('/api/v1/auth/logout', {
    method: 'POST',
    body: { refreshToken },
  });
}

export async function fetchCurrentUser(token: string) {
  return request<PublicUser>('/api/v1/users/me', { token });
}

export async function fetchOverview(token: string) {
  return request<OverviewData>('/api/v1/admin/overview', { token });
}

export async function fetchLeads(
  token: string,
  query: { page: number; pageSize: number; status?: string; platform?: string; keyword?: string },
) {
  const envelope = await request<Lead[]>('/api/v1/admin/leads', {
    token,
    query,
  });

  return {
    items: envelope.data,
    meta: envelope.meta as PaginationMeta,
  };
}

export async function patchLeadStatus(token: string, leadId: string, status: LeadStatus) {
  return request<Lead>(`/api/v1/admin/leads/${leadId}/status`, {
    method: 'PATCH',
    token,
    body: { status },
  });
}

export async function fetchBootstrap() {
  return request<ClientBootstrap>('/api/v1/client-config/bootstrap');
}

export async function fetchHealth() {
  return request<HealthPayload>('/health');
}
