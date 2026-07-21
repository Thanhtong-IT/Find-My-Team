import { AlertTriangle, CheckCircle2, Eye, RefreshCw, XCircle } from 'lucide-react';
import { useCallback, useEffect, useState } from 'react';
import { dismissReport, getReports, resolveReport } from '../api';
import { Badge } from '../components/Badge';
import { Modal } from '../components/Modal';
import { Pagination } from '../components/Pagination';
import type { AdminReport, PageResponse, ReportReason, ReportStatus } from '../types';

const STATUS_TABS: { value: ReportStatus | 'ALL'; label: string }[] = [
  { value: 'ALL', label: 'Tất cả' },
  { value: 'PENDING', label: 'Chờ xử lý' },
  { value: 'RESOLVED', label: 'Đã xử lý' },
  { value: 'DISMISSED', label: 'Bỏ qua' },
];

const REASON_LABELS: Record<ReportReason, string> = {
  SPAM: 'Spam',
  INAPPROPRIATE_CONTENT: 'Nội dung không phù hợp',
  HARASSMENT: 'Quấy rối / Đe dọa',
  FAKE_PROFILE: 'Hồ sơ giả mạo',
  CHEATING: 'Gian lận trong game',
  OTHER: 'Khác',
};

const REASON_TONE: Record<ReportReason, 'red' | 'orange' | 'gray' | 'purple'> = {
  HARASSMENT: 'red',
  CHEATING: 'red',
  SPAM: 'orange',
  INAPPROPRIATE_CONTENT: 'orange',
  FAKE_PROFILE: 'purple',
  OTHER: 'gray',
};

function formatDate(iso: string) {
  const d = new Date(iso);
  const now = Date.now();
  const diff = now - d.getTime();
  if (diff < 60000) return 'vừa xong';
  if (diff < 3600000) return `${Math.floor(diff / 60000)} phút trước`;
  if (diff < 86400000) return `${Math.floor(diff / 3600000)} giờ trước`;
  return d.toLocaleDateString('vi-VN');
}

export function ReportsPage() {
  const [reports, setReports] = useState<PageResponse<AdminReport> | null>(null);
  const [statusFilter, setStatusFilter] = useState<ReportStatus | 'ALL'>('ALL');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [detail, setDetail] = useState<AdminReport | null>(null);
  const [acting, setActing] = useState<string | null>(null);

  const load = useCallback(
    async (page = 0) => {
      setLoading(true);
      setError('');
      try {
        setReports(await getReports(statusFilter, page));
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Đã xảy ra lỗi');
      } finally {
        setLoading(false);
      }
    },
    [statusFilter],
  );

  useEffect(() => { void load(0); }, [load]);

  async function handleAction(report: AdminReport, action: 'resolve' | 'dismiss') {
    setActing(report.id);
    try {
      if (action === 'resolve') await resolveReport(report.id);
      else await dismissReport(report.id);
      setDetail(null);
      await load(reports?.page ?? 0);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Đã xảy ra lỗi');
    } finally {
      setActing(null);
    }
  }

  const pendingCount = reports?.content.filter((r) => r.status === 'PENDING').length ?? 0;

  return (
    <section className="section">
      <div className="toolbar">
        <div className="tab-pills">
          {STATUS_TABS.map((t) => (
            <button
              key={t.value}
              className={statusFilter === t.value ? 'tab-pill active' : 'tab-pill'}
              onClick={() => setStatusFilter(t.value)}
            >
              {t.label}
              {t.value === 'PENDING' && pendingCount > 0 && (
                <span className="tab-badge">{pendingCount}</span>
              )}
            </button>
          ))}
        </div>
        <button className="secondary-button" onClick={() => void load(reports?.page ?? 0)}>
          <RefreshCw size={16} />
          Tải lại
        </button>
      </div>

      {error && <div className="error-box">{error}</div>}

      <div className="table-panel">
        {loading ? (
          <div className="empty-state">
            <RefreshCw size={24} className="spin" />
            <span>Đang tải báo cáo...</span>
          </div>
        ) : reports?.content.length ? (
          <table>
            <thead>
              <tr>
                <th>Người báo cáo</th>
                <th>Đối tượng</th>
                <th>Lý do</th>
                <th>Trạng thái</th>
                <th>Thời gian</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {reports.content.map((r) => (
                <tr key={r.id} className={r.status === 'PENDING' ? 'row-highlight' : ''}>
                  <td>
                    <div className="user-cell">
                      <div className="avatar fallback" style={{ width: 36, height: 36, fontSize: 14 }}>
                        {r.reporterUsername[0].toUpperCase()}
                      </div>
                      <span>@{r.reporterUsername}</span>
                    </div>
                  </td>
                  <td>
                    <div className="user-cell">
                      <div className="avatar fallback" style={{ width: 36, height: 36, fontSize: 14, background: '#dc2626' }}>
                        {r.targetUsername[0].toUpperCase()}
                      </div>
                      <span>@{r.targetUsername}</span>
                    </div>
                  </td>
                  <td>
                    <Badge tone={REASON_TONE[r.reason]}>{REASON_LABELS[r.reason]}</Badge>
                  </td>
                  <td>
                    <Badge
                      tone={
                        r.status === 'PENDING' ? 'orange' : r.status === 'RESOLVED' ? 'green' : 'gray'
                      }
                    >
                      {r.status === 'PENDING' ? 'Chờ xử lý' : r.status === 'RESOLVED' ? 'Đã xử lý' : 'Bỏ qua'}
                    </Badge>
                  </td>
                  <td className="muted">{formatDate(r.createdAt)}</td>
                  <td className="actions">
                    <button className="icon-button" onClick={() => setDetail(r)} title="Xem chi tiết">
                      <Eye size={16} />
                    </button>
                    {r.status === 'PENDING' && (
                      <>
                        <button
                          className="icon-button success"
                          disabled={acting === r.id}
                          onClick={() => void handleAction(r, 'resolve')}
                          title="Xử lý (resolve)"
                        >
                          <CheckCircle2 size={16} />
                        </button>
                        <button
                          className="icon-button danger"
                          disabled={acting === r.id}
                          onClick={() => void handleAction(r, 'dismiss')}
                          title="Bỏ qua (dismiss)"
                        >
                          <XCircle size={16} />
                        </button>
                      </>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : (
          <div className="empty-state">
            <AlertTriangle size={28} />
            <span>Không có báo cáo nào</span>
          </div>
        )}
      </div>

      {reports && (
        <Pagination
          page={reports.page}
          totalPages={reports.totalPages}
          totalElements={reports.totalElements}
          itemLabel="báo cáo"
          onPage={(p) => void load(p)}
        />
      )}

      {detail && (
        <ReportDetailModal
          report={detail}
          acting={acting === detail.id}
          onClose={() => setDetail(null)}
          onResolve={() => void handleAction(detail, 'resolve')}
          onDismiss={() => void handleAction(detail, 'dismiss')}
        />
      )}
    </section>
  );
}

function ReportDetailModal({
  report,
  acting,
  onClose,
  onResolve,
  onDismiss,
}: {
  report: AdminReport;
  acting: boolean;
  onClose: () => void;
  onResolve: () => void;
  onDismiss: () => void;
}) {
  return (
    <Modal title="Chi tiết báo cáo" onClose={onClose}>
      <div className="report-detail">
        <div className="report-parties">
          <div className="report-party">
            <span className="report-party-label">Người báo cáo</span>
            <div className="user-cell">
              <div className="avatar fallback" style={{ width: 40, height: 40, fontSize: 16 }}>
                {report.reporterUsername[0].toUpperCase()}
              </div>
              <strong>@{report.reporterUsername}</strong>
            </div>
          </div>
          <AlertTriangle size={20} className="report-arrow" />
          <div className="report-party">
            <span className="report-party-label">Đối tượng bị báo cáo</span>
            <div className="user-cell">
              <div className="avatar fallback" style={{ width: 40, height: 40, fontSize: 16, background: '#dc2626' }}>
                {report.targetUsername[0].toUpperCase()}
              </div>
              <strong>@{report.targetUsername}</strong>
            </div>
          </div>
        </div>

        <div className="report-info-grid">
          <div>
            <span className="info-label">Lý do</span>
            <Badge tone={REASON_TONE[report.reason]}>{REASON_LABELS[report.reason]}</Badge>
          </div>
          <div>
            <span className="info-label">Trạng thái</span>
            <Badge tone={report.status === 'PENDING' ? 'orange' : report.status === 'RESOLVED' ? 'green' : 'gray'}>
              {report.status === 'PENDING' ? 'Chờ xử lý' : report.status === 'RESOLVED' ? 'Đã xử lý' : 'Bỏ qua'}
            </Badge>
          </div>
          <div>
            <span className="info-label">Thời gian báo cáo</span>
            <span>{new Date(report.createdAt).toLocaleString('vi-VN')}</span>
          </div>
          {report.resolvedAt && (
            <div>
              <span className="info-label">Xử lý lúc</span>
              <span>{new Date(report.resolvedAt).toLocaleString('vi-VN')}</span>
            </div>
          )}
        </div>

        {report.description && (
          <div className="report-desc">
            <span className="info-label">Mô tả chi tiết</span>
            <p>"{report.description}"</p>
          </div>
        )}

        {report.resolvedByUsername && (
          <p className="muted">
            Xử lý bởi: <strong>@{report.resolvedByUsername}</strong>
          </p>
        )}

        {report.status === 'PENDING' && (
          <div className="modal-actions">
            <button type="button" className="secondary-button" onClick={onClose}>
              Để sau
            </button>
            <button
              className="secondary-button danger-btn"
              disabled={acting}
              onClick={onDismiss}
            >
              <XCircle size={16} />
              Bỏ qua
            </button>
            <button
              className="primary-button compact"
              disabled={acting}
              onClick={onResolve}
            >
              <CheckCircle2 size={16} />
              Xử lý xong
            </button>
          </div>
        )}
      </div>
    </Modal>
  );
}
