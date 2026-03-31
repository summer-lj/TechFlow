import type { ClientPlatform, LeadStatus } from './types';

export const brandName = 'TechFlow Admin';

export const leadStatusMeta: Record<
  LeadStatus,
  { label: string; description: string; accent: string }
> = {
  NEW: {
    label: '待跟进',
    description: '新流入线索，尚未处理',
    accent: 'var(--tone-amber)',
  },
  CONTACTED: {
    label: '已联系',
    description: '已经建立联系，等待进一步确认',
    accent: 'var(--tone-blue)',
  },
  QUALIFIED: {
    label: '高意向',
    description: '需求明确，值得推进',
    accent: 'var(--tone-green)',
  },
  ARCHIVED: {
    label: '已归档',
    description: '暂不跟进或已完成记录',
    accent: 'var(--tone-ink)',
  },
};

export const platformMeta: Record<ClientPlatform, { label: string }> = {
  WEB: { label: 'Web' },
  H5: { label: 'H5' },
  MINI_PROGRAM: { label: '小程序' },
  APP: { label: 'App' },
};
