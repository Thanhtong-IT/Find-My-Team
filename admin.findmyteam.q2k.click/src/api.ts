import type {
  AdminGame,
  AdminReport,
  AdminUser,
  ApiResponse,
  AuthUser,
  DashboardStats,
  GamePayload,
  PageResponse,
  ReportStatus,
  Role,
  UploadTarget,
  UserStatus,
} from './types';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:8080/api';
const TOKEN_KEY = 'fmt_admin_access_token';
const REFRESH_KEY = 'fmt_admin_refresh_token';
const USER_KEY = 'fmt_admin_user';

export function getStoredSession() {
  const token = localStorage.getItem(TOKEN_KEY);
  const rawUser = localStorage.getItem(USER_KEY);
  if (!token || !rawUser) return null;

  try {
    return { token, user: JSON.parse(rawUser) as AuthUser };
  } catch {
    clearSession();
    return null;
  }
}

export function storeSession(user: AuthUser) {
  localStorage.setItem(TOKEN_KEY, user.accessToken);
  localStorage.setItem(REFRESH_KEY, user.refreshToken);
  localStorage.setItem(USER_KEY, JSON.stringify(user));
}

export function clearSession() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(REFRESH_KEY);
  localStorage.removeItem(USER_KEY);
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = localStorage.getItem(TOKEN_KEY);
  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      Accept: 'application/json',
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  const json = (await response.json().catch(() => ({}))) as ApiResponse<T>;
  if (!response.ok || json.success === false) {
    throw new Error(json.message || `HTTP ${response.status}`);
  }

  return json.data as T;
}

export async function login(email: string, password: string) {
  const user = await request<AuthUser>('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });

  if (user.role !== 'ADMIN') {
    throw new Error('Tài khoản này chưa có quyền ADMIN');
  }

  storeSession(user);
  return user;
}

// ─── Users ───────────────────────────────────────────────────────────────────

export async function getUsers(query: string, page: number, size = 20) {
  const params = new URLSearchParams({ page: String(page), size: String(size) });
  if (query.trim()) params.set('query', query.trim());
  return request<PageResponse<AdminUser>>(`/admin/users?${params.toString()}`);
}

export async function updateUser(
  userId: string,
  payload: Partial<{ displayName: string; region: string; role: Role; status: UserStatus }>,
) {
  return request<AdminUser>(`/admin/users/${userId}`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  });
}

// ─── Games ────────────────────────────────────────────────────────────────────

export async function getGames() {
  return request<AdminGame[]>('/admin/games');
}

export async function saveGame(gameId: string | null, payload: GamePayload) {
  return request<AdminGame>(gameId ? `/admin/games/${gameId}` : '/admin/games', {
    method: gameId ? 'PUT' : 'POST',
    body: JSON.stringify(payload),
  });
}

export async function deactivateGame(gameId: string) {
  await request<void>(`/admin/games/${gameId}`, { method: 'DELETE' });
}

export async function createGameIconUploadUrl(contentType: string) {
  return request<UploadTarget>('/admin/games/icon-upload-url', {
    method: 'POST',
    body: JSON.stringify({ contentType }),
  });
}

export async function uploadToR2(target: UploadTarget, file: File) {
  const response = await fetch(target.uploadUrl, {
    method: 'PUT',
    headers: { 'Content-Type': file.type || 'image/png' },
    body: file,
  });

  if (!response.ok) {
    throw new Error('Không thể upload icon lên Cloudflare R2');
  }
}

// ─── Reports (mock — swap to real API when backend ready) ────────────────────

const MOCK_REPORTS: AdminReport[] = [
  {
    id: 'r1',
    reporterUsername: 'trung_hv',
    targetUsername: 'nhoktoxic99',
    reason: 'HARASSMENT',
    description: 'Người chơi này liên tục chửi bới và đe doạ trong team chat.',
    status: 'PENDING',
    createdAt: new Date(Date.now() - 2 * 3600000).toISOString(),
  },
  {
    id: 'r2',
    reporterUsername: 'minh_pt',
    targetUsername: 'acc_farm_vip',
    reason: 'FAKE_PROFILE',
    description: 'Profile giả mạo, rank không đúng thực tế.',
    status: 'PENDING',
    createdAt: new Date(Date.now() - 5 * 3600000).toISOString(),
  },
  {
    id: 'r3',
    reporterUsername: 'lananh_gamer',
    targetUsername: 'spammer_01',
    reason: 'SPAM',
    description: 'Liên tục spam link quảng cáo trong mọi nhóm.',
    status: 'RESOLVED',
    createdAt: new Date(Date.now() - 24 * 3600000).toISOString(),
    resolvedAt: new Date(Date.now() - 20 * 3600000).toISOString(),
    resolvedByUsername: 'admin',
  },
  {
    id: 'r4',
    reporterUsername: 'khoa_dev',
    targetUsername: 'hacker_aim',
    reason: 'CHEATING',
    description: 'Sử dụng phần mềm gian lận, aimbot trong game.',
    status: 'PENDING',
    createdAt: new Date(Date.now() - 10 * 3600000).toISOString(),
  },
  {
    id: 'r5',
    reporterUsername: 'tuan_knight',
    targetUsername: 'bad_content_user',
    reason: 'INAPPROPRIATE_CONTENT',
    description: 'Đăng ảnh đại diện không phù hợp.',
    status: 'DISMISSED',
    createdAt: new Date(Date.now() - 48 * 3600000).toISOString(),
    resolvedAt: new Date(Date.now() - 45 * 3600000).toISOString(),
    resolvedByUsername: 'admin',
  },
  {
    id: 'r6',
    reporterUsername: 'phuong_na',
    targetUsername: 'toxic_player',
    reason: 'HARASSMENT',
    description: 'Gửi tin nhắn cá nhân đe dọa.',
    status: 'PENDING',
    createdAt: new Date(Date.now() - 1 * 3600000).toISOString(),
  },
];

let mockReports = [...MOCK_REPORTS];

export async function getReports(
  status: ReportStatus | 'ALL' = 'ALL',
  page = 0,
  size = 20,
): Promise<PageResponse<AdminReport>> {
  await new Promise((res) => setTimeout(res, 400)); // simulate latency
  const filtered = status === 'ALL' ? mockReports : mockReports.filter((r) => r.status === status);
  const start = page * size;
  return {
    content: filtered.slice(start, start + size),
    page,
    size,
    totalElements: filtered.length,
    totalPages: Math.max(1, Math.ceil(filtered.length / size)),
  };
}

export async function resolveReport(reportId: string): Promise<void> {
  await new Promise((res) => setTimeout(res, 300));
  mockReports = mockReports.map((r) =>
    r.id === reportId
      ? { ...r, status: 'RESOLVED', resolvedAt: new Date().toISOString(), resolvedByUsername: 'admin' }
      : r,
  );
}

export async function dismissReport(reportId: string): Promise<void> {
  await new Promise((res) => setTimeout(res, 300));
  mockReports = mockReports.map((r) =>
    r.id === reportId
      ? { ...r, status: 'DISMISSED', resolvedAt: new Date().toISOString(), resolvedByUsername: 'admin' }
      : r,
  );
}

// ─── Dashboard Stats ──────────────────────────────────────────────────────────

export async function getDashboardStats(): Promise<DashboardStats> {
  // Try real API first; fallback to derived mock stats
  try {
    return await request<DashboardStats>('/admin/stats');
  } catch {
    // derive from available endpoints
    const [usersPage, games, allReports] = await Promise.all([
      getUsers('', 0, 1),
      getGames(),
      getReports('ALL', 0, 999),
    ]);
    const pending = allReports.content.filter((r) => r.status === 'PENDING').length;
    const resolved = allReports.content.filter((r) => r.status === 'RESOLVED').length;
    return {
      totalUsers: usersPage.totalElements,
      activeUsers: usersPage.totalElements, // approx — no breakdown from API
      bannedUsers: 0,
      totalGames: games.length,
      activeGames: games.filter((g) => g.isActive).length,
      pendingReports: pending,
      resolvedReports: resolved,
    };
  }
}
