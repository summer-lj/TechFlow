import { LockKeyhole, ShieldCheck, Sparkle, Workflow } from 'lucide-react';
import { startTransition, useEffect, useState, type FormEvent } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';

import { useAuth } from '../auth';
import { ApiError } from '../lib/api';

const featureNotes = [
  {
    icon: ShieldCheck,
    title: '统一登录鉴权',
    description: '复用服务端 JWT、刷新 token 和管理员角色守卫。',
  },
  {
    icon: Workflow,
    title: '线索流转看板',
    description: '从新增到高意向再到归档，操作链路收敛在同一张工作台里。',
  },
  {
    icon: Sparkle,
    title: '更适合运营使用',
    description: '信息层级清晰，重点数据更醒目，减少传统后台的压迫感。',
  },
];

export function LoginPage() {
  const auth = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [phone, setPhone] = useState('13965026764');
  const [password, setPassword] = useState('123456');
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (auth.status === 'authenticated') {
      startTransition(() => {
        navigate('/', { replace: true });
      });
    }
  }, [auth.status, navigate]);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSubmitting(true);
    setError('');

    try {
      await auth.login(phone, password);
      const nextPath = (location.state as { from?: string } | null)?.from ?? '/';

      startTransition(() => {
        navigate(nextPath, { replace: true });
      });
    } catch (submissionError) {
      if (submissionError instanceof ApiError) {
        setError(submissionError.message);
      } else if (submissionError instanceof Error) {
        setError(submissionError.message);
      } else {
        setError('登录失败，请稍后再试。');
      }
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="login-screen">
      <section className="login-poster">
        <div className="poster-glow" />
        <p className="eyebrow">TechFlow Admin</p>
        <h1>把后台做成真正能工作的运营控制台。</h1>
        <p className="poster-copy">
          登录后可以查看总览、筛选线索、更新状态，并实时检查接口和服务运行情况。
        </p>

        <div className="poster-feature-list">
          {featureNotes.map((feature) => {
            const Icon = feature.icon;

            return (
              <article key={feature.title} className="poster-feature">
                <span className="poster-feature-icon">
                  <Icon size={18} />
                </span>
                <div>
                  <h2>{feature.title}</h2>
                  <p>{feature.description}</p>
                </div>
              </article>
            );
          })}
        </div>
      </section>

      <section className="login-panel">
        <div className="login-panel-header">
          <span className="panel-tag">管理员登录</span>
          <h2>进入后台工作区</h2>
          <p>默认账号来自后端 seed，可直接用于本地联调。</p>
        </div>

        <form className="login-form" onSubmit={handleSubmit}>
          <label>
            手机号
            <input
              autoComplete="username"
              inputMode="numeric"
              value={phone}
              onChange={(event) => setPhone(event.target.value)}
              placeholder="请输入管理员手机号"
              required
            />
          </label>

          <label>
            密码
            <input
              autoComplete="current-password"
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              placeholder="请输入管理员密码"
              required
            />
          </label>

          {error ? <p className="form-error">{error}</p> : null}

          <button className="primary-button" type="submit" disabled={submitting}>
            <LockKeyhole size={16} />
            {submitting ? '登录中...' : '登录后台'}
          </button>
        </form>

        <div className="login-hint">
          <strong>默认凭据</strong>
          <span>`13965026764` / `123456`</span>
          <span>如果你改过 `techflow-server/.env.local`，请以本地环境变量配置为准。</span>
        </div>
      </section>
    </div>
  );
}
