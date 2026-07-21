import type { ReactNode } from 'react';

interface StatCardProps {
  label: string;
  value: number | string;
  icon: ReactNode;
  accent: 'blue' | 'green' | 'red' | 'purple' | 'orange';
  sub?: string;
}

export function StatCard({ label, value, icon, accent, sub }: StatCardProps) {
  return (
    <div className={`stat-card stat-card-${accent}`}>
      <div className="stat-icon">{icon}</div>
      <div className="stat-body">
        <span className="stat-label">{label}</span>
        <strong className="stat-value">{value}</strong>
        {sub && <span className="stat-sub">{sub}</span>}
      </div>
    </div>
  );
}
