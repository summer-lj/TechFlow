import { RefreshCcw, Search } from 'lucide-react';
import { startTransition, useDeferredValue, useEffect, useState } from 'react';

import { useAuth } from '../auth';
import { leadStatusMeta, platformMeta } from '../constants';
import { fetchLeads, patchLeadStatus } from '../lib/api';
import { formatDateTime } from '../lib/format';
import type { ClientPlatform, Lead, LeadStatus, PaginationMeta } from '../types';

const statusOptions: Array<{ value: LeadStatus | 'ALL'; label: string }> = [
  { value: 'ALL', label: '全部状态' },
  { value: 'NEW', label: '待跟进' },
  { value: 'CONTACTED', label: '已联系' },
  { value: 'QUALIFIED', label: '高意向' },
  { value: 'ARCHIVED', label: '已归档' },
];

const platformOptions: Array<{ value: ClientPlatform | 'ALL'; label: string }> = [
  { value: 'ALL', label: '全部来源' },
  { value: 'WEB', label: 'Web' },
  { value: 'H5', label: 'H5' },
  { value: 'MINI_PROGRAM', label: '小程序' },
  { value: 'APP', label: 'App' },
];

const statusWorkflow: LeadStatus[] = ['CONTACTED', 'QUALIFIED', 'ARCHIVED'];

export function LeadsPage() {
  const auth = useAuth();
  const [searchText, setSearchText] = useState('');
  const [statusFilter, setStatusFilter] = useState<LeadStatus | 'ALL'>('ALL');
  const [platformFilter, setPlatformFilter] = useState<ClientPlatform | 'ALL'>('ALL');
  const [page, setPage] = useState(1);
  const [items, setItems] = useState<Lead[]>([]);
  const [meta, setMeta] = useState<PaginationMeta | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [updatingId, setUpdatingId] = useState('');
  const deferredKeyword = useDeferredValue(searchText.trim());

  useEffect(() => {
    const accessToken = auth.accessToken;

    if (!accessToken) {
      return;
    }

    const token = accessToken;

    const controller = new AbortController();

    async function loadLeads() {
      setLoading(true);
      setError('');

      try {
        const response = await fetchLeads(token, {
          page,
          pageSize: 12,
          status: statusFilter === 'ALL' ? undefined : statusFilter,
          platform: platformFilter === 'ALL' ? undefined : platformFilter,
          keyword: deferredKeyword || undefined,
        });

        startTransition(() => {
          setItems(response.items);
          setMeta(response.meta);
        });
      } catch (loadError) {
        if (!controller.signal.aborted) {
          setError(loadError instanceof Error ? loadError.message : '读取线索失败');
        }
      } finally {
        if (!controller.signal.aborted) {
          setLoading(false);
        }
      }
    }

    void loadLeads();

    return () => {
      controller.abort();
    };
  }, [auth.accessToken, deferredKeyword, page, platformFilter, statusFilter]);

  async function handleStatusUpdate(leadId: string, nextStatus: LeadStatus) {
    if (!auth.accessToken) {
      return;
    }

    setUpdatingId(leadId);

    try {
      const response = await patchLeadStatus(auth.accessToken, leadId, nextStatus);

      startTransition(() => {
        setItems((current) =>
          current.map((item) => (item.id === leadId ? response.data : item)),
        );
      });
    } catch (updateError) {
      setError(updateError instanceof Error ? updateError.message : '更新状态失败');
    } finally {
      setUpdatingId('');
    }
  }

  function handleStatusFilterChange(value: LeadStatus | 'ALL') {
    startTransition(() => {
      setStatusFilter(value);
      setPage(1);
    });
  }

  function handlePlatformFilterChange(value: ClientPlatform | 'ALL') {
    startTransition(() => {
      setPlatformFilter(value);
      setPage(1);
    });
  }

  return (
    <div className="page-grid">
      <section className="panel-shell">
        <div className="toolbar">
          <label className="search-box">
            <Search size={16} />
            <input
              value={searchText}
              onChange={(event) => setSearchText(event.target.value)}
              placeholder="搜索姓名、邮箱或公司"
            />
          </label>

          <div className="filter-group">
            {statusOptions.map((option) => (
              <button
                key={option.value}
                type="button"
                className={`chip-button ${statusFilter === option.value ? 'active' : ''}`}
                onClick={() => handleStatusFilterChange(option.value)}
              >
                {option.label}
              </button>
            ))}
          </div>

          <div className="filter-group">
            {platformOptions.map((option) => (
              <button
                key={option.value}
                type="button"
                className={`chip-button ${platformFilter === option.value ? 'active' : ''}`}
                onClick={() => handlePlatformFilterChange(option.value)}
              >
                {option.label}
              </button>
            ))}
          </div>
        </div>
      </section>

      <section className="panel-shell">
        <div className="section-head">
          <div>
            <p className="section-eyebrow">Lead Queue</p>
            <h3>全部线索</h3>
          </div>
          <div className="table-meta">
            {meta ? (
              <span>
                共 {meta.total} 条，第 {meta.page}/{meta.totalPages || 1} 页
              </span>
            ) : null}
          </div>
        </div>

        {error ? <div className="panel-error">{error}</div> : null}

        {loading ? (
          <div className="empty-state">正在同步线索数据...</div>
        ) : items.length === 0 ? (
          <div className="empty-state">当前筛选条件下没有找到线索。</div>
        ) : (
          <div className="lead-table">
            {items.map((lead) => (
              <article key={lead.id} className="lead-row">
                <div className="lead-primary">
                  <strong>{lead.name}</strong>
                  <span>{lead.email}</span>
                  <small>{lead.company || '未填写公司'}</small>
                </div>

                <div className="lead-secondary">
                  <span className="status-pill">{leadStatusMeta[lead.status].label}</span>
                  <span className="source-pill">{platformMeta[lead.platform].label}</span>
                  <small>{formatDateTime(lead.createdAt)}</small>
                </div>

                <div className="lead-message">{lead.message || '未填写需求说明'}</div>

                <div className="lead-actions">
                  {statusWorkflow.map((status) => (
                    <button
                      key={status}
                      type="button"
                      className={`ghost-button ${lead.status === status ? 'selected' : ''}`}
                      disabled={lead.status === status || updatingId === lead.id}
                      onClick={() => void handleStatusUpdate(lead.id, status)}
                    >
                      {updatingId === lead.id ? <RefreshCcw size={15} className="spin" /> : null}
                      {leadStatusMeta[status].label}
                    </button>
                  ))}
                </div>
              </article>
            ))}
          </div>
        )}

        <div className="pagination-row">
          <button
            type="button"
            className="ghost-button"
            disabled={!meta || meta.page <= 1}
            onClick={() => setPage((current) => Math.max(current - 1, 1))}
          >
            上一页
          </button>
          <button
            type="button"
            className="ghost-button"
            disabled={!meta || !meta.hasNextPage}
            onClick={() => setPage((current) => current + 1)}
          >
            下一页
          </button>
        </div>
      </section>
    </div>
  );
}
