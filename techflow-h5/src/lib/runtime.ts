declare global {
  interface Window {
    TechFlowRegister?: {
      postMessage: (message: string) => void;
    };
  }
}

const phonePattern = /^1\d{10}$/;
const defaultBusinessSlug = 'techflow-app';

export function getPhonePattern() {
  return phonePattern;
}

export function getDefaultBusinessSlug() {
  return defaultBusinessSlug;
}

export function resolveBusinessProfile(input?: string) {
  const slug = normalizeBusinessSlug(input ?? defaultBusinessSlug);

  if (slug === 'techflow-app') {
    return {
      slug,
      displayName: 'TechFlow App',
      sceneName: 'App 拉新注册',
      routePath: `/h5/register/${slug}`,
    };
  }

  return {
    slug,
    displayName: slug
      .split('-')
      .filter(Boolean)
      .map((segment) => segment.charAt(0).toUpperCase() + segment.slice(1))
      .join(' '),
    sceneName: `${slug} 注册`,
    routePath: `/h5/register/${slug}`,
  };
}

export function resolveApiBase() {
  const search = new URLSearchParams(window.location.search);
  const candidate = search.get('apiBase') || import.meta.env.VITE_API_BASE || '/api/v1';

  return normalizeApiBase(candidate);
}

export function isEmbeddedInApp() {
  return (
    new URLSearchParams(window.location.search).get('embedded') === '1' &&
    typeof window.TechFlowRegister === 'object' &&
    typeof window.TechFlowRegister.postMessage === 'function'
  );
}

function normalizeApiBase(input: string) {
  let value = input.trim();

  if (!value) {
    return '/api/v1';
  }

  if (value.startsWith('/')) {
    return value.replace(/\/+$/, '');
  }

  if (!value.startsWith('http://') && !value.startsWith('https://')) {
    value = `http://${value}`;
  }

  value = value.replace(/\/+$/, '');

  if (value.endsWith('/api/v1')) {
    return value;
  }

  if (value.endsWith('/api')) {
    return `${value}/v1`;
  }

  if (value.includes('/api/')) {
    return value;
  }

  return `${value}/api/v1`;
}

function normalizeBusinessSlug(input: string) {
  const normalized = input
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9-]+/g, '-')
    .replace(/-{2,}/g, '-')
    .replace(/^-|-$/g, '');

  return normalized || defaultBusinessSlug;
}
