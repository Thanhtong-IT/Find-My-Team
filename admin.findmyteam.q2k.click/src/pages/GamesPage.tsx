import { CloudUpload, Edit3, EyeOff, Gamepad2, Plus, RefreshCw, Save } from 'lucide-react';
import { FormEvent, useEffect, useMemo, useState } from 'react';
import { createGameIconUploadUrl, deactivateGame, getGames, saveGame, uploadToR2 } from '../api';
import { Badge } from '../components/Badge';
import { Modal } from '../components/Modal';
import type { AdminGame, GamePayload } from '../types';

const emptyGame: GamePayload = {
  name: '',
  shortName: '',
  tag: '',
  gradientStart: '#2563EB',
  gradientEnd: '#0F172A',
  iconUrl: '',
  ranks: [],
  roles: [],
  maxTeamSize: 5,
  isActive: true,
};

function GameIcon({ game }: { game: AdminGame }) {
  return game.iconUrl ? (
    <img className="game-icon" src={game.iconUrl} alt={game.name} />
  ) : (
    <div className="game-icon fallback">
      <Gamepad2 size={22} />
    </div>
  );
}

export function GamesPage() {
  const [games, setGames] = useState<AdminGame[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [editing, setEditing] = useState<AdminGame | null | 'new'>(null);

  async function load() {
    setLoading(true);
    setError('');
    try {
      setGames(await getGames());
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Đã xảy ra lỗi');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => { void load(); }, []);

  async function hideGame(game: AdminGame) {
    try {
      await deactivateGame(game.id);
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Đã xảy ra lỗi');
    }
  }

  const activeGames = games.filter((g) => g.isActive);
  const hiddenGames = games.filter((g) => !g.isActive);

  return (
    <section className="section">
      <div className="toolbar">
        <p className="muted">
          {activeGames.length} game đang hiển thị • {hiddenGames.length} đã ẩn
        </p>
        <div className="button-row">
          <button className="primary-button compact" onClick={() => setEditing('new')}>
            <Plus size={16} />
            Thêm game
          </button>
          <button className="secondary-button" onClick={() => void load()}>
            <RefreshCw size={16} />
            Tải lại
          </button>
        </div>
      </div>

      {error && <div className="error-box">{error}</div>}

      {loading ? (
        <div className="game-grid">
          {[...Array(4)].map((_, i) => <div key={i} className="game-card skeleton" style={{ height: 220 }} />)}
        </div>
      ) : games.length ? (
        <div className="game-grid">
          {games.map((game) => (
            <article className="game-card" key={game.id}>
              <div
                className="game-banner"
                style={{
                  background: `linear-gradient(135deg, ${game.gradientStart || '#2563EB'}, ${game.gradientEnd || '#0F172A'})`,
                }}
              >
                <GameIcon game={game} />
                <div>
                  <h3>{game.name}</h3>
                  <p>{game.tag || game.shortName || 'Game'}</p>
                </div>
                <Badge tone={game.isActive ? 'green' : 'gray'}>
                  {game.isActive ? 'ACTIVE' : 'HIDDEN'}
                </Badge>
              </div>
              <div className="game-body">
                <strong>Team tối đa: {game.maxTeamSize} người</strong>
                <p>Ranks: {game.ranks.length ? game.ranks.join(' · ') : '—'}</p>
                <p>Roles: {game.roles.length ? game.roles.join(' · ') : '—'}</p>
                <div className="card-actions">
                  <button className="secondary-button" onClick={() => setEditing(game)}>
                    <Edit3 size={15} />
                    Sửa
                  </button>
                  <button
                    className="secondary-button"
                    disabled={!game.isActive}
                    onClick={() => void hideGame(game)}
                  >
                    <EyeOff size={15} />
                    Ẩn
                  </button>
                </div>
              </div>
            </article>
          ))}
        </div>
      ) : (
        <div className="empty-state">
          <Gamepad2 size={28} />
          <span>Chưa có game nào. Nhấn "Thêm game" để bắt đầu.</span>
        </div>
      )}

      {editing && (
        <GameModal
          game={editing === 'new' ? null : editing}
          onClose={() => setEditing(null)}
          onSaved={async () => { setEditing(null); await load(); }}
        />
      )}
    </section>
  );
}

function GameModal({
  game,
  onClose,
  onSaved,
}: {
  game: AdminGame | null;
  onClose: () => void;
  onSaved: () => Promise<void>;
}) {
  const initial = useMemo<GamePayload>(
    () =>
      game
        ? {
            name: game.name,
            shortName: game.shortName || '',
            tag: game.tag || '',
            gradientStart: game.gradientStart || '#2563EB',
            gradientEnd: game.gradientEnd || '#0F172A',
            iconUrl: game.iconUrl || '',
            ranks: game.ranks,
            roles: game.roles,
            maxTeamSize: game.maxTeamSize,
            isActive: game.isActive,
          }
        : emptyGame,
    [game],
  );
  const [form, setForm] = useState(initial);
  const [ranks, setRanks] = useState(initial.ranks.join(', '));
  const [roles, setRoles] = useState(initial.roles.join(', '));
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState('');

  function patch(next: Partial<GamePayload>) {
    setForm((cur) => ({ ...cur, ...next }));
  }

  async function uploadIcon(file: File | null) {
    if (!file) return;
    setUploading(true);
    setError('');
    try {
      const target = await createGameIconUploadUrl(file.type || 'image/png');
      await uploadToR2(target, file);
      patch({ iconUrl: target.publicUrl });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Upload thất bại');
    } finally {
      setUploading(false);
    }
  }

  async function submit(e: FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError('');
    try {
      await saveGame(game?.id ?? null, {
        ...form,
        ranks: splitCsv(ranks),
        roles: splitCsv(roles),
      });
      await onSaved();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Lưu thất bại');
    } finally {
      setSaving(false);
    }
  }

  const previewGradient = `linear-gradient(135deg, ${form.gradientStart || '#2563EB'}, ${form.gradientEnd || '#0F172A'})`;

  return (
    <Modal title={game ? `Sửa game: ${game.name}` : 'Thêm game mới'} onClose={onClose} wide>
      <form className="form-stack" onSubmit={submit}>
        {/* Preview banner */}
        <div className="game-preview-banner" style={{ background: previewGradient }}>
          <div className="icon-preview">
            {form.iconUrl ? <img src={form.iconUrl} alt="" /> : <Gamepad2 size={26} />}
          </div>
          <span>{form.name || 'Tên game'}</span>
        </div>

        {/* Icon upload */}
        <div className="icon-upload-row">
          <label className="grow">
            Icon URL
            <input value={form.iconUrl || ''} onChange={(e) => patch({ iconUrl: e.target.value })} placeholder="https://..." />
          </label>
          <label className="upload-button">
            <CloudUpload size={17} />
            {uploading ? 'Uploading...' : 'Upload R2'}
            <input type="file" accept="image/png,image/jpeg,image/webp" onChange={(e) => void uploadIcon(e.target.files?.[0] ?? null)} />
          </label>
        </div>

        <label>
          Tên game *
          <input value={form.name} onChange={(e) => patch({ name: e.target.value })} required />
        </label>
        <div className="form-grid">
          <label>
            Tên ngắn
            <input value={form.shortName || ''} onChange={(e) => patch({ shortName: e.target.value })} placeholder="LOL, VALORANT..." />
          </label>
          <label>
            Tag
            <input value={form.tag || ''} onChange={(e) => patch({ tag: e.target.value })} placeholder="FPS, MOBA..." />
          </label>
        </div>
        <div className="form-grid three">
          <label>
            Màu bắt đầu
            <div className="color-input-row">
              <input type="color" value={form.gradientStart || '#2563EB'} onChange={(e) => patch({ gradientStart: e.target.value })} className="color-swatch" />
              <input value={form.gradientStart || ''} onChange={(e) => patch({ gradientStart: e.target.value })} pattern="#[0-9A-Fa-f]{6}" />
            </div>
          </label>
          <label>
            Màu kết thúc
            <div className="color-input-row">
              <input type="color" value={form.gradientEnd || '#0F172A'} onChange={(e) => patch({ gradientEnd: e.target.value })} className="color-swatch" />
              <input value={form.gradientEnd || ''} onChange={(e) => patch({ gradientEnd: e.target.value })} pattern="#[0-9A-Fa-f]{6}" />
            </div>
          </label>
          <label>
            Team size
            <input type="number" min={1} max={100} value={form.maxTeamSize} onChange={(e) => patch({ maxTeamSize: Number(e.target.value) })} />
          </label>
        </div>
        <label>
          Ranks <span className="muted">(cách nhau bằng dấu phẩy)</span>
          <textarea value={ranks} onChange={(e) => setRanks(e.target.value)} placeholder="Sắt, Đồng, Bạc, Vàng, Bạch Kim, Kim Cương" />
        </label>
        <label>
          Roles <span className="muted">(cách nhau bằng dấu phẩy)</span>
          <textarea value={roles} onChange={(e) => setRoles(e.target.value)} placeholder="Duelist, Controller, Initiator, Sentinel" />
        </label>
        <label className="switch-row">
          <input type="checkbox" checked={form.isActive} onChange={(e) => patch({ isActive: e.target.checked })} />
          Hiển thị game này cho người dùng
        </label>
        {error && <div className="error-box">{error}</div>}
        <div className="modal-actions">
          <button type="button" className="secondary-button" onClick={onClose}>Hủy</button>
          <button className="primary-button compact" disabled={saving || uploading}>
            <Save size={16} />
            {saving ? 'Đang lưu...' : 'Lưu game'}
          </button>
        </div>
      </form>
    </Modal>
  );
}

function splitCsv(value: string) {
  return value.split(',').map((s) => s.trim()).filter(Boolean);
}
