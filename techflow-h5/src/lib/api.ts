export type RegisterPayload = {
  phone: string;
  password: string;
};

export type RegisterSession = {
  user: {
    id: string;
    email: string;
    phone: string;
    name: string;
    role: string;
    isActive: boolean;
    createdAt?: string;
    updatedAt?: string;
  };
  tokens: {
    accessToken: string;
    refreshToken: string;
    tokenType: string;
    expiresIn: number;
  };
};

export async function register(apiBase: string, payload: RegisterPayload) {
  const response = await fetch(`${apiBase}/auth/register`, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  const envelope = (await response.json().catch(() => ({}))) as {
    success?: boolean;
    message?: string;
    data?: RegisterSession;
    error?: {
      message?: string;
      details?: string[];
    };
  };

  if (response.ok && envelope.success === true && envelope.data) {
    return envelope.data;
  }

  throw new Error(
    envelope.error?.details?.[0] ||
      envelope.error?.message ||
      envelope.message ||
      '注册失败，请稍后再试。',
  );
}
