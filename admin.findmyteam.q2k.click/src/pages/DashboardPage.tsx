import { AlertTriangle, Gamepad2, RefreshCw, TrendingUp, Users } from 'lucide-react';
import { useEffect, useState } from 'react';
import { getDashboardStats } from '../api';
import { StatCard } from '../components/StatCard';
import type { DashboardStats } from '../types';

type TabSetter = (tab: string) => void;

export function DashboardPage({ onNavigate }: { onNavigate: TabSetter }) {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  async function load() {
    setLoading(true);
    setError('');
    try {
      setStats(await getDashboardStats());
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Không thể tải thống kê');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { void load(); }, []);

  return (
    <section className="section">
      <div className="toolbar">
        <p className="muted">Tổng quan hệ thống Find My Team.</p>
        <button className="secondary-button" onClick={() => void load()} disabled={loading}>
          <RefreshCw size={16} className={loading ? 'spin' : ''} />
          Làm mới
        </button>
      </div>

      {error && <div className="error-box">{error}</div>}

      {loading ? (
        <div className="stats-grid">
          {[...Array(5)].map((_, i) => <div key={i} className="stat-card skeleton" />)}
        </div>
      ) : stats ? (
        <div className="stats-grid">
          <StatCard
            label="Tổng người dùng"
            value={stats.totalUsers.toLocaleString()}
            icon={<Users size={22} />}
            accent="blue"
            sub={`${stats.bannedUsers} bị khoá`}
          />
          <StatCard
            label="Người dùng hoạt động"
            value={stats.activeUsers.toLocaleString()}
            icon={<TrendingUp size={22} />}
            accent="green"
            sub="Trong hệ thống"
          />
          <StatCard
            label="Tổng game"
            value={stats.totalGames}
            icon={<Gamepad2 size={22} />}
            accent="purple"
            sub={`${stats.activeGames} đang hiển thị`}
          />
          <StatCard
            label="Report chờ xử lý"
            value={stats.pendingReports}
            icon={<AlertTriangle size={22} />}
            accent={stats.pendingReports > 0 ? 'red' : 'green'}
            sub={`${stats.resolvedReports} đã xử lý`}
          />
        </div>
      ) : null}

      <div className="dashboard-grid">
        <div className="dashboard-card">
          <div className="dashboard-card-header">
            <Users size={18} />
            <h3>Quản lý người dùng</h3>
          </div>
          <p>Xem, chỉnh sửa thông tin, thay đổi role và trạng thái tài khoản.</p>
          <button className="primary-button compact" onClick={() => onNavigate('users')}>
            Đến trang User →
          </button>
        </div>

        <div className="dashboard-card">
          <div className="dashboard-card-header">
            <Gamepad2 size={18} />
            <h3>Quản lý game</h3>
          </div>
          <p>Thêm mới, chỉnh sửa thông tin game, rank, role và icon hiển thị.</p>
          <button className="primary-button compact" onClick={() => onNavigate('games')}>
            Đến trang Game →
          </button>
        </div>

        <div className="dashboard-card">
          <div className="dashboard-card-header">
            <AlertTriangle size={18} />
            <h3>Quản lý báo cáo</h3>
          </div>
          <p>Xem xét và xử lý các báo cáo vi phạm từ người dùng trong hệ thống.</p>
          <button className="primary-button compact" onClick={() => onNavigate('reports')}>
            Đến trang Report →
          </button>
        </div>
      </div>
    </section>
  );
}
