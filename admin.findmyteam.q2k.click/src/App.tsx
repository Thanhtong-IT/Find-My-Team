import { AlertTriangle, Gamepad2, LayoutDashboard, LogOut, Shield, Users } from 'lucide-react';
import { FormEvent, useState } from 'react';
import { clearSession, getStoredSession, login } from './api';
import { DashboardPage } from './pages/DashboardPage';
import { GamesPage } from './pages/GamesPage';
import { ReportsPage } from './pages/ReportsPage';
import { UsersPage } from './pages/UsersPage';
import type { AuthUser } from './types';

type Tab = 'dashboard' | 'users' | 'games' | 'reports';

const NAV_ITEMS: { id: Tab; label: string; icon: React.ReactNode; badge?: string }[] = [
  { id: 'dashboard', label: 'Dashboard', icon: <LayoutDashboard size={18} /> },
  { id: 'users', label: 'Quản lý User', icon: <Users size={18} /> },
  { id: 'games', label: 'Quản lý Game', icon: <Gamepad2 size={18} /> },
  { id: 'reports', label: 'Quản lý Report', icon: <AlertTriangle size={18} /> },
];

const PAGE_TITLES: Record<Tab, string> = {
  dashboard: 'Dashboard',
  users: 'Quản lý người dùng',
  games: 'Quản lý game',
  reports: 'Quản lý báo cáo',
};

export function App() {
  const [session, setSession] = useState(() => getStoredSession());

  if (!session) {
    return <LoginScreen onLoggedIn={(user) => setSession({ token: user.accessToken, user })} />;
  }

  return (
    <Dashboard
      user={session.user}
      onLogout={() => {
        clearSession();
        setSession(null);
      }}
    />
  );
}

function LoginScreen({ onLoggedIn }: { onLoggedIn: (user: AuthUser) => void }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function submit(event: FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError('');
    try {
      onLoggedIn(await login(email, password));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Đăng nhập thất bại');
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="login-shell">
      <div className="login-bg-orb orb-1" />
      <div className="login-bg-orb orb-2" />
      <section className="login-panel">
        <div className="brand-mark">
          <Shield size={24} />
        </div>
        <h1>Find My Team</h1>
        <p>Đăng nhập bằng tài khoản <strong>ADMIN</strong> để quản lý hệ thống.</p>
        <form onSubmit={submit} className="form-stack">
          <label>
            Email
            <input
              id="login-email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              type="email"
              placeholder="admin@findmyteam.com"
              required
            />
          </label>
          <label>
            Mật khẩu
            <input
              id="login-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              type="password"
              placeholder="••••••••"
              required
            />
          </label>
          {error && <div className="error-box">{error}</div>}
          <button id="login-submit" className="primary-button" disabled={loading}>
            {loading ? (
              <span className="btn-loading">
                <span className="spin-dot" />
                Đang đăng nhập...
              </span>
            ) : (
              'Đăng nhập'
            )}
          </button>
        </form>
      </section>
    </main>
  );
}

function Dashboard({ user, onLogout }: { user: AuthUser; onLogout: () => void }) {
  const [tab, setTab] = useState<Tab>('dashboard');

  return (
    <div className="admin-shell">
      <aside className="sidebar">
        <div className="sidebar-brand">
          <div className="sidebar-brand-icon">
            <Shield size={20} />
          </div>
          <div className="sidebar-brand-text">
            <span className="sidebar-brand-name">FMT Admin</span>
            <span className="sidebar-brand-sub">Control Panel</span>
          </div>
        </div>

        <nav className="sidebar-nav">
          {NAV_ITEMS.map((item) => (
            <button
              key={item.id}
              className={tab === item.id ? 'nav-item active' : 'nav-item'}
              onClick={() => setTab(item.id)}
            >
              <span className="nav-icon">{item.icon}</span>
              <span className="nav-label">{item.label}</span>
              {item.badge && <span className="nav-badge">{item.badge}</span>}
            </button>
          ))}
        </nav>

        <div className="sidebar-footer">
          <div className="sidebar-user">
            <div className="sidebar-avatar">
              {(user.displayName || user.username || '?')[0].toUpperCase()}
            </div>
            <div className="sidebar-user-info">
              <strong>{user.displayName || user.username}</strong>
              <span>{user.email}</span>
            </div>
          </div>
          <button className="sidebar-logout" onClick={onLogout} title="Đăng xuất">
            <LogOut size={17} />
          </button>
        </div>
      </aside>

      <main className="content">
        <header className="topbar">
          <div className="topbar-left">
            <p className="topbar-eyebrow">Admin Console</p>
            <h1 className="topbar-title">{PAGE_TITLES[tab]}</h1>
          </div>
        </header>

        <div className="page-content">
          {tab === 'dashboard' && <DashboardPage onNavigate={(t) => setTab(t as Tab)} />}
          {tab === 'users' && <UsersPage />}
          {tab === 'games' && <GamesPage />}
          {tab === 'reports' && <ReportsPage />}
        </div>
      </main>
    </div>
  );
}
