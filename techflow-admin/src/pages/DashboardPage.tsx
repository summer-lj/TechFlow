import { ArrowRight, ChevronRight, TrendingUp } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useEffect, useState } from 'react';

import { useAuth } from '../auth';
import { leadStatusMeta, platformMeta } from '../constants';
import { fetchOverview } from '../lib/api';
import { formatCompactNumber, formatDateTime, formatPercent, formatTrend } from '../lib/format';
import type { OverviewData } from '../types';

export function DashboardPage() {
  const auth = useAuth();
  const [overview, setOverview] = useState<OverviewData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    const accessToken = auth.accessToken;

    if (!accessToken) {
      return;
    }

    const token = accessToken;

    let active = true;

    async function loadOverview() {
      setLoading(true);
      setError('');

      try {
        const response = await fetchOverview(token);

        if (active) {
          setOverview(response.data);
        }
      } catch (loadError) {
        if (active) {
          setError(loadError instanceof Error ? loadError.message : '读取后台总览失败');
        }
      } finally {
        if (active) {
          setLoading(false);
        }
      }
    }

    void loadOverview();

    return () => {
      active = false;
    };
  }, [auth.accessToken]);

  if (loading) {
    return <section className="panel-shell">正在加载总览数据...</section>;
  }

  if (error || !overview) {
    return <section className="panel-shell panel-error">{error || '总览数据不可用'}</section>;
  }

  const kpiCards = [
    {
      label: '线索总量',
      value: formatCompactNumber(overview.kpis.totalLeads),
      note: '累计入库',
    },
    {
      label: '待跟进',
      value: formatCompactNumber(overview.kpis.newLeads),
      note: '需要优先处理',
    },
    {
      label: '高意向',
      value: formatCompactNumber(overview.kpis.qualifiedLeads),
      note: '已进入重点推进',
    },
    {
      label: '在线管理员',
      value: formatCompactNumber(overview.kpis.activeAdmins),
      note: '具备后台权限',
    },
  ];

  const maxActivity = Math.max(...overview.activity.map((item) => item.count), 1);

  return (
    <div className="page-grid">
      <section className="hero-panel">
        <div>
          <p className="eyebrow">Realtime Snapshot</p>
          <h3>后台今天最值得看的，是新增线索和高意向之间的衔接效率。</h3>
          <p className="hero-support">
            {formatTrend(overview.kpis.weeklyTrendPercent)}，当前整体转化率 {formatPercent(overview.kpis.conversionRate)}。
          </p>
        </div>

        <div className="hero-panel-aside">
          <div className="inline-stat">
            <TrendingUp size={18} />
            <div>
              <strong>{formatPercent(Math.abs(overview.kpis.weeklyTrendPercent))}</strong>
              <span>{overview.kpis.weeklyTrendPercent >= 0 ? '本周流入更积极' : '本周流入放缓'}</span>
            </div>
          </div>
          <Link className="text-link" to="/leads">
            进入线索台
            <ArrowRight size={16} />
          </Link>
        </div>
      </section>

      <section className="metric-grid">
        {kpiCards.map((card) => (
          <article key={card.label} className="metric-block">
            <p>{card.label}</p>
            <strong>{card.value}</strong>
            <span>{card.note}</span>
          </article>
        ))}
      </section>

      <section className="split-grid">
        <article className="panel-shell">
          <div className="section-head">
            <div>
              <p className="section-eyebrow">Pipeline</p>
              <h3>线索状态分布</h3>
            </div>
          </div>

          <div className="pipeline-list">
            {overview.pipeline.map((item) => (
              <div key={item.status} className="pipeline-row">
                <div className="pipeline-meta">
                  <strong>{leadStatusMeta[item.status].label}</strong>
                  <span>{leadStatusMeta[item.status].description}</span>
                </div>
                <div className="pipeline-bar-track">
                  <div
                    className="pipeline-bar"
                    style={{
                      width: `${Math.max(item.share, 8)}%`,
                      background: leadStatusMeta[item.status].accent,
                    }}
                  />
                </div>
                <div className="pipeline-value">
                  <strong>{item.count}</strong>
                  <span>{formatPercent(item.share)}</span>
                </div>
              </div>
            ))}
          </div>
        </article>

        <article className="panel-shell">
          <div className="section-head">
            <div>
              <p className="section-eyebrow">Volume</p>
              <h3>近 7 天流入</h3>
            </div>
          </div>

          <div className="activity-chart" aria-label="近 7 天线索数量柱状图">
            {overview.activity.map((item) => (
              <div key={item.date} className="activity-column">
                <div
                  className="activity-bar"
                  style={{
                    height: `${Math.max((item.count / maxActivity) * 100, item.count > 0 ? 16 : 8)}%`,
                  }}
                />
                <strong>{item.count}</strong>
                <span>{item.label}</span>
              </div>
            ))}
          </div>
        </article>
      </section>

      <section className="split-grid">
        <article className="panel-shell">
          <div className="section-head">
            <div>
              <p className="section-eyebrow">Channels</p>
              <h3>流入端占比</h3>
            </div>
          </div>

          <div className="channel-grid">
            {overview.platforms.map((item) => (
              <div key={item.platform} className="channel-item">
                <strong>{platformMeta[item.platform].label}</strong>
                <span>{item.count} 条</span>
                <div className="mini-progress">
                  <div style={{ width: `${Math.max(item.share, 8)}%` }} />
                </div>
                <small>{formatPercent(item.share)}</small>
              </div>
            ))}
          </div>
        </article>

        <article className="panel-shell">
          <div className="section-head">
            <div>
              <p className="section-eyebrow">Recent</p>
              <h3>最新线索</h3>
            </div>
            <Link className="text-link" to="/leads">
              查看全部
              <ChevronRight size={16} />
            </Link>
          </div>

          <div className="recent-list">
            {overview.recentLeads.length === 0 ? (
              <div className="empty-state">当前还没有线索数据，先去演示页或客户端提交一条试试。</div>
            ) : (
              overview.recentLeads.map((lead) => (
                <article key={lead.id} className="recent-item">
                  <div>
                    <strong>{lead.name}</strong>
                    <span>
                      {lead.company || '未填写公司'} · {platformMeta[lead.platform].label}
                    </span>
                  </div>
                  <div className="recent-item-meta">
                    <span className="status-pill">{leadStatusMeta[lead.status].label}</span>
                    <small>{formatDateTime(lead.createdAt)}</small>
                  </div>
                </article>
              ))
            )}
          </div>
        </article>
      </section>

      <section className="panel-shell panel-footnote">
        数据更新时间：{formatDateTime(overview.lastUpdatedAt)}
      </section>
    </div>
  );
}
