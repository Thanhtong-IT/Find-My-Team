export type Role = 'USER' | 'ADMIN';
export type UserStatus = 'ACTIVE' | 'BANNED';
export type ReportStatus = 'PENDING' | 'RESOLVED' | 'DISMISSED';
export type ReportReason =
  | 'SPAM'
  | 'INAPPROPRIATE_CONTENT'
  | 'HARASSMENT'
  | 'FAKE_PROFILE'
  | 'CHEATING'
  | 'OTHER';

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  message?: string;
}

export interface PageResponse<T> {
  content: T[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
}

export interface AuthUser {
  userId: string;
  email: string;
  username: string;
  fullName: string;
  displayName?: string;
  avatarUrl?: string;
  role: Role;
  status: UserStatus;
  accessToken: string;
  refreshToken: string;
}

export interface AdminUser {
  id: string;
  email: string;
  username: string;
  fullName: string;
  displayName?: string;
  avatarUrl?: string;
  region?: string;
  role: Role;
  status: UserStatus;
  lastSeenAt?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface AdminGame {
  id: string;
  name: string;
  shortName?: string;
  tag?: string;
  gradientStart?: string;
  gradientEnd?: string;
  iconUrl?: string;
  ranks: string[];
  roles: string[];
  maxTeamSize: number;
  isActive: boolean;
}

export interface GamePayload {
  name: string;
  shortName?: string;
  tag?: string;
  gradientStart?: string;
  gradientEnd?: string;
  iconUrl?: string;
  ranks: string[];
  roles: string[];
  maxTeamSize: number;
  isActive: boolean;
}

export interface UploadTarget {
  uploadUrl: string;
  publicUrl: string;
  objectKey: string;
  expiresInSeconds: number;
}

export interface AdminReport {
  id: string;
  reporterUsername: string;
  reporterAvatarUrl?: string;
  targetUsername: string;
  targetAvatarUrl?: string;
  reason: ReportReason;
  description?: string;
  status: ReportStatus;
  createdAt: string;
  resolvedAt?: string;
  resolvedByUsername?: string;
}

export interface DashboardStats {
  totalUsers: number;
  activeUsers: number;
  bannedUsers: number;
  totalGames: number;
  activeGames: number;
  pendingReports: number;
  resolvedReports: number;
}
