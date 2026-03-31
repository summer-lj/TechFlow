import { FormEvent, useMemo, useState } from 'react';
import { useParams } from 'react-router-dom';

import { register, type RegisterSession } from '../lib/api';
import {
  getPhonePattern,
  isEmbeddedInApp,
  resolveApiBase,
  resolveBusinessProfile,
} from '../lib/runtime';

type NoticeState =
  | {
      tone: 'success' | 'error';
      message: string;
    }
  | null;

export function RegisterPage() {
  const params = useParams<{ businessSlug: string }>();
  const apiBase = useMemo(() => resolveApiBase(), []);
  const embedded = useMemo(() => isEmbeddedInApp(), []);
  const phonePattern = useMemo(() => getPhonePattern(), []);
  const businessProfile = useMemo(
    () => resolveBusinessProfile(params.businessSlug),
    [params.businessSlug],
  );

  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [notice, setNotice] = useState<NoticeState>(null);
  const [session, setSession] = useState<RegisterSession | null>(null);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();

    const normalizedPhone = phone.replace(/\D/g, '');

    if (!phonePattern.test(normalizedPhone)) {
      setNotice({
        tone: 'error',
        message: '请输入有效的 11 位中国大陆手机号。',
      });
      return;
    }

    if (password.trim().length < 6) {
      setNotice({
        tone: 'error',
        message: '密码至少需要 6 位。',
      });
      return;
    }

    if (password !== confirmPassword) {
      setNotice({
        tone: 'error',
        message: '两次输入的密码不一致，请重新确认。',
      });
      return;
    }

    setIsSubmitting(true);
    setNotice(null);

    try {
      const result = await register(apiBase, {
        phone: normalizedPhone,
        password: password.trim(),
      });

      window.localStorage.setItem('techflow.h5.session', JSON.stringify(result));
      setSession(result);
      setNotice({
        tone: 'success',
        message: '注册成功，账号已经写入数据库。',
      });

      if (embedded) {
        window.TechFlowRegister?.postMessage(
          JSON.stringify({
            type: 'register-success',
            session: result,
          }),
        );
      }
    } catch (error) {
      setNotice({
        tone: 'error',
        message: error instanceof Error ? error.message : '注册失败，请稍后再试。',
      });
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <main className="page-shell">
      <section className="hero-panel">
        <p className="eyebrow">TechFlow H5 Workspace</p>
        <h1>服务器部署一个 H5 工程，App 通过 WebView 直接访问。</h1>
        <p className="hero-copy">
          这个注册页已经切到工程化形态：后续新增活动页、邀请页、专题页，都可以继续在同一个 H5 工程里扩展路由、接口层和构建发布流程。
        </p>
        <div className="hero-meta">
          <div className="meta-card">
            <span className="meta-label">业务入口</span>
            <strong>{businessProfile.sceneName}</strong>
            <span className="meta-note">{businessProfile.routePath}</span>
          </div>
          <div className="meta-card">
            <span className="meta-label">当前接口</span>
            <strong>{apiBase}</strong>
          </div>
          <div className="meta-card">
            <span className="meta-label">访问方式</span>
            <strong>{embedded ? 'App WebView 内嵌访问' : '浏览器 / WebView 访问'}</strong>
          </div>
        </div>
      </section>

      <section className="register-panel">
        <div className="panel-header">
          <span className="panel-tag">{businessProfile.sceneName}</span>
          <h2>创建 {businessProfile.displayName} 账号</h2>
          <p>
            注册成功后会返回统一认证会话；当前业务入口已经固定在
            {' '}
            <strong>{businessProfile.routePath}</strong>
            ，如果当前页是从 App WebView 打开的，登录态会自动回传给 App。
          </p>
        </div>

        <form className="register-form" onSubmit={handleSubmit}>
          <label>
            手机号
            <input
              value={phone}
              onChange={(event) => setPhone(event.target.value)}
              type="tel"
              inputMode="numeric"
              autoComplete="tel"
              maxLength={11}
              placeholder="请输入 11 位手机号"
              required
            />
          </label>

          <label>
            登录密码
            <input
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              type="password"
              autoComplete="new-password"
              minLength={6}
              placeholder="请输入至少 6 位密码"
              required
            />
          </label>

          <label>
            确认密码
            <input
              value={confirmPassword}
              onChange={(event) => setConfirmPassword(event.target.value)}
              type="password"
              autoComplete="new-password"
              minLength={6}
              placeholder="请再次输入密码"
              required
            />
          </label>

          <button className="primary-button" type="submit" disabled={isSubmitting}>
            {isSubmitting ? '注册中...' : '注册并开通账号'}
          </button>
        </form>

        {notice ? (
          <div className={`feedback is-visible is-${notice.tone}`}>{notice.message}</div>
        ) : null}

        {session ? (
          <section className="success-card">
            <div className="success-badge">注册成功</div>
            <h3>账号已经进入统一用户库</h3>
            <p>
              {embedded
                ? '注册结果已经回传给 App，页面会自动返回并进入已登录状态。'
                : '现在你可以直接回到 App 登录页，使用刚才的手机号和密码登录。'}
            </p>
            <div className="success-grid">
              <div>
                <span>手机号</span>
                <strong>{session.user.phone}</strong>
              </div>
              <div>
                <span>默认昵称</span>
                <strong>{session.user.name}</strong>
              </div>
              <div>
                <span>默认角色</span>
                <strong>{session.user.role}</strong>
              </div>
            </div>
          </section>
        ) : null}
      </section>
    </main>
  );
}
