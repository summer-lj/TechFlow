import {
  createContext,
  startTransition,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react';

import {
  ApiError,
  fetchCurrentUser,
  login as loginRequest,
  logout as logoutRequest,
  refreshSession as refreshRequest,
} from './lib/api';
import type { AuthPayload, AuthTokens, PublicUser } from './types';

const storageKey = 'techflow-admin/session';

type AuthStatus = 'loading' | 'authenticated' | 'unauthenticated';

interface StoredSession extends AuthPayload {}

interface AuthContextValue {
  status: AuthStatus;
  user: PublicUser | null;
  tokens: AuthTokens | null;
  login: (phone: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  accessToken: string | null;
}

const AuthContext = createContext<AuthContextValue | null>(null);

function readStoredSession() {
  const raw = window.localStorage.getItem(storageKey);

  if (!raw) {
    return null;
  }

  try {
    return JSON.parse(raw) as StoredSession;
  } catch {
    window.localStorage.removeItem(storageKey);
    return null;
  }
}

function persistSession(payload: AuthPayload) {
  window.localStorage.setItem(storageKey, JSON.stringify(payload));
}

function clearStoredSession() {
  window.localStorage.removeItem(storageKey);
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [status, setStatus] = useState<AuthStatus>('loading');
  const [user, setUser] = useState<PublicUser | null>(null);
  const [tokens, setTokens] = useState<AuthTokens | null>(null);

  useEffect(() => {
    let active = true;

    async function hydrate() {
      const stored = readStoredSession();

      if (!stored) {
        if (active) {
          setStatus('unauthenticated');
        }

        return;
      }

      try {
        const currentUser = await fetchCurrentUser(stored.tokens.accessToken);

        if (!active) {
          return;
        }

        setUser(currentUser.data);
        setTokens(stored.tokens);
        setStatus('authenticated');
      } catch (error) {
        try {
          const refreshed = await refreshRequest(stored.tokens.refreshToken);

          if (!active) {
            return;
          }

          persistSession(refreshed.data);
          setUser(refreshed.data.user);
          setTokens(refreshed.data.tokens);
          setStatus('authenticated');
        } catch {
          if (active) {
            clearStoredSession();
            setUser(null);
            setTokens(null);
            setStatus('unauthenticated');
          }
        }
      }
    }

    void hydrate();

    return () => {
      active = false;
    };
  }, []);

  async function login(phone: string, password: string) {
    const response = await loginRequest(phone, password);

    if (response.data.user.role !== 'ADMIN') {
      throw new ApiError('当前账号没有后台权限', {
        status: 403,
        code: 'FORBIDDEN',
      });
    }

    persistSession(response.data);

    startTransition(() => {
      setUser(response.data.user);
      setTokens(response.data.tokens);
      setStatus('authenticated');
    });
  }

  async function logout() {
    const currentTokens = tokens;

    clearStoredSession();

    startTransition(() => {
      setUser(null);
      setTokens(null);
      setStatus('unauthenticated');
    });

    if (currentTokens?.refreshToken) {
      try {
        await logoutRequest(currentTokens.refreshToken);
      } catch {
        return;
      }
    }
  }

  return (
    <AuthContext.Provider
      value={{
        status,
        user,
        tokens,
        login,
        logout,
        accessToken: tokens?.accessToken ?? null,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);

  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }

  return context;
}
