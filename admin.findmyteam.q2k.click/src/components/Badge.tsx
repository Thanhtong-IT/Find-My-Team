type BadgeTone = 'blue' | 'green' | 'red' | 'gray' | 'orange' | 'purple';

export function Badge({ tone, children }: { tone: BadgeTone; children: React.ReactNode }) {
  return <span className={`badge badge-${tone}`}>{children}</span>;
}
