import type { AdminUser } from '../types';

export function Avatar({ user, size = 40 }: { user: Pick<AdminUser, 'username' | 'avatarUrl'>; size?: number }) {
  if (user.avatarUrl) {
    return (
      <img
        className="avatar"
        src={user.avatarUrl}
        alt={user.username}
        style={{ width: size, height: size }}
      />
    );
  }
  return (
    <div className="avatar fallback" style={{ width: size, height: size, fontSize: size * 0.4 }}>
      {(user.username || '?')[0].toUpperCase()}
    </div>
  );
}
