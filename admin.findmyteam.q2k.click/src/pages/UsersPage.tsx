import { Ban, CheckCircle2, Edit3, RefreshCw, Save, Search } from 'lucide-react';
import { FormEvent, useCallback, useEffect, useState } from 'react';
import { getUsers, updateUser } from '../api';
import { Avatar } from '../components/Avatar';
import { Badge } from '../components/Badge';
import { Modal } from '../components/Modal';
import { Pagination } from '../components/Pagination';
import type { AdminUser, PageResponse, Role, UserStatus } from '../types';

export function UsersPage() {
  const [users, setUsers] = useState<PageResponse<AdminUser> | null>(null);
  const [query, setQuery] = useState('');
  const [draftQuery, setDraftQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [editing, setEditing] = useState<AdminUser | null>(null);

  const load = useCallback(
    async (page = 0) => {
      setLoading(true);
      setError('');
      try {
        setUsers(await getUsers(query, page));
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Đã xảy ra lỗi');
      } finally {
        setLoading(false);
      }
    },
    [query],
  );

  useEffect(() => { void load(0); }, [load]);

  async function toggleStatus(user: AdminUser) {
    try {
      await updateUser(user.id, { status: user.status === 'ACTIVE' ? 'BANNED' : 'ACTIVE' });
      await load(users?.page ?? 0);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Đã xảy ra lỗi');
    }
  }

  return (
    <section className="section">
      <div className="toolbar">
        <form
          className="search-box"
          onSubmit={(e) => { e.preventDefault(); setQuery(draftQuery); }}
        >
          <Search size={17} />
          <input
            value={draftQuery}
            onChange={(e) => setDraftQuery(e.target.value)}
            placeholder="Tìm email, username, họ tên..."
          />
        </form>
        <button className="secondary-button" onClick={() => void load(users?.page ?? 0)}>
          <RefreshCw size={16} />
          Tải lại
        </button>
      </div>

      {error && <div className="error-box">{error}</div>}

      <div className="table-panel">
        {loading ? (
          <div className="empty-state">
            <RefreshCw size={24} className="spin" />
            <span>Đang tải người dùng...</span>
          </div>
        ) : users?.content.length ? (
          <table>
            <thead>
              <tr>
                <th>Người dùng</th>
                <th>Email</th>
                <th>Region</th>
                <th>Role</th>
                <th>Trạng thái</th>
                <th>Tham gia</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {users.content.map((item) => (
                <tr key={item.id}>
                  <td>
                    <div className="user-cell">
                      <Avatar user={item} />
                      <div>
                        <strong>{item.displayName || item.fullName || item.username}</strong>
                        <span>@{item.username}</span>
                      </div>
                    </div>
                  </td>
                  <td>{item.email}</td>
                  <td>{item.region || <span className="muted">—</span>}</td>
                  <td>
                    <Badge tone={item.role === 'ADMIN' ? 'blue' : 'gray'}>{item.role}</Badge>
                  </td>
                  <td>
                    <Badge tone={item.status === 'ACTIVE' ? 'green' : 'red'}>{item.status}</Badge>
                  </td>
                  <td className="muted">
                    {item.createdAt ? new Date(item.createdAt).toLocaleDateString('vi-VN') : '—'}
                  </td>
                  <td className="actions">
                    <button className="icon-button" onClick={() => setEditing(item)} title="Chỉnh sửa">
                      <Edit3 size={16} />
                    </button>
                    <button
                      className="icon-button"
                      onClick={() => void toggleStatus(item)}
                      title={item.status === 'ACTIVE' ? 'Khoá tài khoản' : 'Mở khóa'}
                    >
                      {item.status === 'ACTIVE' ? <Ban size={16} /> : <CheckCircle2 size={16} />}
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <div className="empty-state">
            <Search size={24} />
            <span>Không tìm thấy tài khoản phù hợp</span>
          </div>
        )}
      </div>

      {users && (
        <Pagination
          page={users.page}
          totalPages={users.totalPages}
          totalElements={users.totalElements}
          itemLabel="tài khoản"
          onPage={(p) => void load(p)}
        />
      )}

      {editing && (
        <UserModal
          user={editing}
          onClose={() => setEditing(null)}
          onSaved={async () => { setEditing(null); await load(users?.page ?? 0); }}
        />
      )}
    </section>
  );
}

function UserModal({ user, onClose, onSaved }: { user: AdminUser; onClose: () => void; onSaved: () => Promise<void> }) {
  const [displayName, setDisplayName] = useState(user.displayName || '');
  const [region, setRegion] = useState(user.region || '');
  const [role, setRole] = useState<Role>(user.role);
  const [status, setStatus] = useState<UserStatus>(user.status);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  async function submit(e: FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError('');
    try {
      await updateUser(user.id, { displayName, region, role, status });
      await onSaved();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Đã xảy ra lỗi');
    } finally {
      setSaving(false);
    }
  }

  return (
    <Modal title={`Chỉnh sửa @${user.username}`} onClose={onClose}>
      <form className="form-stack" onSubmit={submit}>
        <div className="user-modal-header">
          <Avatar user={user} size={52} />
          <div>
            <strong>{user.fullName || user.username}</strong>
            <span className="muted">{user.email}</span>
          </div>
        </div>
        <label>
          Tên hiển thị
          <input value={displayName} onChange={(e) => setDisplayName(e.target.value)} placeholder={user.username} />
        </label>
        <label>
          Region
          <input value={region} onChange={(e) => setRegion(e.target.value)} placeholder="VN, NA, EU..." />
        </label>
        <div className="form-grid">
          <label>
            Role
            <select value={role} onChange={(e) => setRole(e.target.value as Role)}>
              <option value="USER">USER</option>
              <option value="ADMIN">ADMIN</option>
            </select>
          </label>
          <label>
            Trạng thái
            <select value={status} onChange={(e) => setStatus(e.target.value as UserStatus)}>
              <option value="ACTIVE">ACTIVE</option>
              <option value="BANNED">BANNED</option>
            </select>
          </label>
        </div>
        {error && <div className="error-box">{error}</div>}
        <div className="modal-actions">
          <button type="button" className="secondary-button" onClick={onClose}>Hủy</button>
          <button className="primary-button compact" disabled={saving}>
            <Save size={16} />
            {saving ? 'Đang lưu...' : 'Lưu thay đổi'}
          </button>
        </div>
      </form>
    </Modal>
  );
}
