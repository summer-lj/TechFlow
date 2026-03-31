export type UserRole = 'ADMIN' | 'USER';
export type LeadStatus = 'NEW' | 'CONTACTED' | 'QUALIFIED' | 'ARCHIVED';
export type ClientPlatform = 'WEB' | 'H5' | 'MINI_PROGRAM' | 'APP';

export interface ApiErrorShape {
  code: string;
  message: string;
  details?: string[];
}

export interface PaginationMeta {
  page: number;
  pageSize: number;
  total: number;
  totalPages: number;
  hasNextPage: boolean;
}

export interface ApiEnvelope<T> {
  success: boolean;
  message: string;
  requestId: string;
  timestamp: string;
  path: string;
  data: T;
  meta?: PaginationMeta;
  error?: ApiErrorShape;
}

export interface PublicUser {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  tokenType: string;
  expiresIn: number;
}

export interface AuthPayload {
  user: PublicUser;
  tokens: AuthTokens;
}

export interface Lead {
  id: string;
  name: string;
  email: string;
  company: string | null;
  platform: ClientPlatform;
  message: string | null;
  source: string;
  status: LeadStatus;
  createdAt: string;
  updatedAt: string;
}

export interface OverviewKpis {
  totalLeads: number;
  newLeads: number;
  qualifiedLeads: number;
  activeAdmins: number;
  conversionRate: number;
  weeklyTrendPercent: number;
}

export interface OverviewBucket {
  label: string;
  count: number;
  share: number;
}

export interface OverviewPipelineBucket extends OverviewBucket {
  status: LeadStatus;
}

export interface OverviewPlatformBucket extends OverviewBucket {
  platform: ClientPlatform;
}

export interface ActivityPoint {
  date: string;
  label: string;
  count: number;
}

export interface OverviewData {
  kpis: OverviewKpis;
  pipeline: OverviewPipelineBucket[];
  platforms: OverviewPlatformBucket[];
  activity: ActivityPoint[];
  recentLeads: Lead[];
  lastUpdatedAt: string;
}

export interface ClientBootstrap {
  product: {
    name: string;
    apiBasePath: string;
  };
  auth: {
    loginPath: string;
    refreshPath: string;
    logoutPath: string;
    currentUserPath: string;
  };
  publicConfig: {
    bootstrapPath: string;
    featureCatalogPath: string;
  };
}

export interface HealthPayload {
  status: string;
  timestamp?: string;
}
