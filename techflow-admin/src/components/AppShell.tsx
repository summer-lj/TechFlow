import {
  BellDot,
  DatabaseZap,
  LayoutDashboard,
  LogOut,
  Sparkles,
  UsersRound,
} from 'lucide-react';
import { NavLink, Outlet, useLocation } from 'react-router-dom';

import { useAuth } from '../auth';

const navItems = [
  {
    to: '/',
    label: '总览看板',
    description: '关键指标与线索趋势',
    icon: LayoutDashboard,
  },
  {
    to: '/leads',
    label: '线索管理',
    description: '筛选、跟进、归档',
    icon: UsersRound,
  },
  {
    to: '/system',
    label: '系统配置',
    description: '接口、健康状态与环境说明',
    icon: DatabaseZap,
  },
];

const pageCopy: Record<string, { eyebrow: string; title: string; description: string }> = {
  '/': {
    eyebrow: 'Admin Overview',
    title: '运营总览',
    description: '集中查看线索流入、转化质量和后台运行节奏。',
  },
  '/leads': {
    eyebrow: 'Lead Desk',
    title: '线索管理',
    description: '快速筛选最新线索，并把状态推进到下一步。',
  },
  '/system': {
    eyebrow: 'System Console',
    title: '系统配置',
    description: '核对健康状态、启动配置和当前管理员会话。',
  },
};

export function AppShell() {
  const { pathname } = useLocation();
  const auth = useAuth();
  const pageMeta = pageCopy[pathname] ?? pageCopy['/'];
  const formattedDate = new Intl.DateTimeFormat('zh-CN', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    weekday: 'short',
  }).format(new Date());

  return (
    <div className="app-frame">
      <aside className="sidebar">
        <div className="brand-panel">
          <div className="brand-mark">TF</div>
          <div>
            <p className="brand-kicker">TechFlow</p>
            <h1>Command Room</h1>
          </div>
        </div>

        <nav className="nav-list" aria-label="主导航">
          {navItems.map((item) => {
            const Icon = item.icon;

            return (
              <NavLink
                key={item.to}
                to={item.to}
                end={item.to === '/'}
                className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
              >
                <span className="nav-item-icon">
                  <Icon size={18} strokeWidth={2.1} />
                </span>
                <span>
                  <strong>{item.label}</strong>
                  <small>{item.description}</small>
                </span>
              </NavLink>
            );
          })}
        </nav>

        <section className="sidebar-note">
          <div className="sidebar-note-header">
            <Sparkles size={16} />
            <span>今日关注</span>
          </div>
          <p>先处理新增线索，再回看高意向转化，后台效率会更稳定。</p>
        </section>

        <button className="ghost-button sidebar-logout" type="button" onClick={() => void auth.logout()}>
          <LogOut size={16} />
          退出登录
        </button>
      </aside>

      <div className="workspace">
        <header className="workspace-header">
          <div>
            <p className="eyebrow">{pageMeta.eyebrow}</p>
            <h2>{pageMeta.title}</h2>
            <p className="workspace-description">{pageMeta.description}</p>
          </div>

          <div className="workspace-meta">
            <div className="meta-chip">
              <BellDot size={16} />
              <span>{formattedDate}</span>
            </div>
            <div className="profile-chip">
              <div className="profile-avatar">{auth.user?.name.slice(0, 1) ?? 'A'}</div>
              <div>
                <strong>{auth.user?.name}</strong>
                <span>{auth.user?.email}</span>
              </div>
            </div>
          </div>
        </header>

        <main className="workspace-main">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
