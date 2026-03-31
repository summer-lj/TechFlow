import { Globe, HeartPulse, KeyRound, Server } from 'lucide-react';
import { useEffect, useState } from 'react';

import { useAuth } from '../auth';
import { fetchBootstrap, fetchHealth } from '../lib/api';
import { formatDateTime } from '../lib/format';
import type { ClientBootstrap, HealthPayload } from '../types';

export function SystemPage() {
  const auth = useAuth();
  const [bootstrap, setBootstrap] = useState<ClientBootstrap | null>(null);
  const [health, setHealth] = useState<HealthPayload | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    let active = true;

    async function loadSystemData() {
      try {
        const [bootstrapResponse, healthResponse] = await Promise.all([
          fetchBootstrap(),
          fetchHealth(),
        ]);

        if (!active) {
          return;
        }

        setBootstrap(bootstrapResponse.data);
        setHealth(healthResponse.data);
      } catch (loadError) {
        if (active) {
          setError(loadError instanceof Error ? loadError.message : '读取系统信息失败');
        }
      }
    }

    void loadSystemData();

    return () => {
      active = false;
    };
  }, []);

  return (
    <div className="page-grid">
      {error ? <section className="panel-shell panel-error">{error}</section> : null}

      <section className="split-grid">
        <article className="panel-shell">
          <div className="section-head">
            <div>
              <p className="section-eyebrow">Health</p>
              <h3>服务健康状态</h3>
            </div>
          </div>

          <div className="system-stack">
            <div className="system-item">
              <HeartPulse size={18} />
              <div>
                <strong>{health?.status ?? '未知'}</strong>
                <span>来自 `GET /health` 的实时结果</span>
              </div>
            </div>
            <div className="system-item">
              <Server size={18} />
              <div>
                <strong>{import.meta.env.VITE_API_BASE_URL || '通过 Vite 代理访问'}</strong>
                <span>当前前端请求入口</span>
              </div>
            </div>
          </div>
        </article>

        <article className="panel-shell">
          <div className="section-head">
            <div>
              <p className="section-eyebrow">Session</p>
              <h3>当前管理员会话</h3>
            </div>
          </div>

          <div className="system-stack">
            <div className="system-item">
              <KeyRound size={18} />
              <div>
                <strong>{auth.user?.name ?? '未登录'}</strong>
                <span>{auth.user?.email ?? '当前没有会话'}</span>
              </div>
            </div>
            <div className="system-item">
              <Globe size={18} />
              <div>
                <strong>{auth.user?.role ?? '未知角色'}</strong>
                <span>
                  创建于{' '}
                  {auth.user?.createdAt ? formatDateTime(auth.user.createdAt) : '暂无用户时间信息'}
                </span>
              </div>
            </div>
          </div>
        </article>
      </section>

      <section className="panel-shell">
        <div className="section-head">
          <div>
            <p className="section-eyebrow">Bootstrap</p>
            <h3>启动配置</h3>
          </div>
        </div>

        {bootstrap ? (
          <div className="config-grid">
            <article className="config-card">
              <strong>产品信息</strong>
              <span>{bootstrap.product.name}</span>
              <small>API Base: {bootstrap.product.apiBasePath}</small>
            </article>
            <article className="config-card">
              <strong>登录接口</strong>
              <span>{bootstrap.auth.loginPath}</span>
              <small>刷新：{bootstrap.auth.refreshPath}</small>
            </article>
            <article className="config-card">
              <strong>登出接口</strong>
              <span>{bootstrap.auth.logoutPath}</span>
              <small>当前用户：{bootstrap.auth.currentUserPath}</small>
            </article>
            <article className="config-card">
              <strong>公共配置</strong>
              <span>{bootstrap.publicConfig.bootstrapPath}</span>
              <small>功能目录：{bootstrap.publicConfig.featureCatalogPath}</small>
            </article>
          </div>
        ) : (
          <div className="empty-state">正在加载启动配置...</div>
        )}
      </section>
    </div>
  );
}
