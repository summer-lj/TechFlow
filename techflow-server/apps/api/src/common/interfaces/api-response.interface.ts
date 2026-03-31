export interface ApiEnvelope<T> {
  success: true;
  message: string;
  requestId: string;
  timestamp: string;
  path: string;
  data: T;
  meta?: Record<string, unknown>;
}

export interface ApiPayload<T> {
  data: T;
  message?: string;
  meta?: Record<string, unknown>;
}
