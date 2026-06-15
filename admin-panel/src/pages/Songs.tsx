import { useEffect, useState } from 'react';
import { apiFetch } from '../api/client';

interface Song {
  id: number;
  title: string;
  artist: string;
  lyrics: string;
  chords: string;
  bpm: number | null;
  audioUrl: string | null;
  youtubeUrl: string | null;
  userId: number | null;
  createdAt: string;
  creator?: { id: number; name: string; email: string } | null;
}

interface SongForm {
  title: string;
  artist: string;
  lyrics: string;
  chords: string;
  bpm: string;
  audioUrl: string;
  youtubeUrl: string;
}

const EMPTY_FORM: SongForm = { title: '', artist: '', lyrics: '', chords: '', bpm: '', audioUrl: '', youtubeUrl: '' };

type Toast = { msg: string; type: 'success' | 'error' } | null;

export default function Songs() {
  const [songs, setSongs] = useState<Song[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [toast, setToast] = useState<Toast>(null);

  const [modalOpen, setModalOpen] = useState(false);
  const [editingSong, setEditingSong] = useState<Song | null>(null);
  const [form, setForm] = useState<SongForm>(EMPTY_FORM);
  const [saving, setSaving] = useState(false);

  useEffect(() => { fetchSongs(); }, []);

  const showToast = (msg: string, type: 'success' | 'error') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 3000);
  };

  const fetchSongs = async () => {
    setLoading(true);
    try {
      const data = await apiFetch<Song[]>('/admin/songs');
      setSongs(data);
      setError('');
    } catch (e: any) {
      setError('Не вдалося завантажити пісні: ' + e.message);
    } finally {
      setLoading(false);
    }
  };

  const openCreate = () => {
    setEditingSong(null);
    setForm(EMPTY_FORM);
    setModalOpen(true);
  };

  const openEdit = (s: Song) => {
    setEditingSong(s);
    setForm({
      title: s.title,
      artist: s.artist,
      lyrics: s.lyrics,
      chords: s.chords,
      bpm: s.bpm ? String(s.bpm) : '',
      audioUrl: s.audioUrl || '',
      youtubeUrl: s.youtubeUrl || '',
    });
    setModalOpen(true);
  };

  const handleSave = async () => {
    if (!form.title.trim() || !form.chords.trim() || !form.lyrics.trim()) {
      showToast("Назва, акорди та текст — обов'язкові поля", 'error');
      return;
    }
    setSaving(true);
    const body = {
      title: form.title.trim(),
      artist: form.artist.trim() || 'Unknown',
      lyrics: form.lyrics.trim(),
      chords: form.chords.trim(),
      bpm: form.bpm ? Number(form.bpm) : undefined,
      audioUrl: form.audioUrl.trim() || undefined,
      youtubeUrl: form.youtubeUrl.trim() || undefined,
    };
    try {
      if (editingSong) {
        await apiFetch(`/admin/songs/${editingSong.id}`, { method: 'PUT', body: JSON.stringify(body) });
        showToast('Пісню оновлено ✓', 'success');
      } else {
        await apiFetch('/admin/songs', { method: 'POST', body: JSON.stringify(body) });
        showToast('Пісню створено ✓', 'success');
      }
      setModalOpen(false);
      fetchSongs();
    } catch (e: any) {
      showToast('Помилка: ' + e.message, 'error');
    } finally {
      setSaving(false);
    }
  };

  const deleteSong = async (id: number, title: string) => {
    if (!confirm(`Видалити пісню "${title}"?`)) return;
    try {
      await apiFetch(`/admin/songs/${id}`, { method: 'DELETE' });
      showToast('Пісню видалено', 'success');
      fetchSongs();
    } catch (e: any) {
      showToast('Помилка: ' + e.message, 'error');
    }
  };

  const filtered = songs.filter(
    s =>
      s.title.toLowerCase().includes(search.toLowerCase()) ||
      s.artist.toLowerCase().includes(search.toLowerCase()),
  );

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">🎵 Пісні</h1>
        <button className="btn btn-primary" onClick={openCreate}>+ Додати пісню</button>
      </div>

      {error && <div className="error-banner">{error}</div>}

      <div className="search-bar">
        <input
          className="search-input"
          placeholder="Пошук за назвою або виконавцем..."
          value={search}
          onChange={e => setSearch(e.target.value)}
        />
        <button className="btn btn-ghost" onClick={fetchSongs}>↻ Оновити</button>
      </div>

      <div className="table-wrapper">
        <table className="data-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Назва</th>
              <th>Виконавець</th>
              <th>BPM</th>
              <th>Автор</th>
              <th>Дата</th>
              <th>Дії</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={7} style={{ textAlign: 'center', padding: 32, color: 'var(--text-muted)' }}>Завантаження...</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={7}><div className="empty-state"><div className="empty-icon">🎵</div>Пісень не знайдено</div></td></tr>
            ) : (
              filtered.map(s => (
                <tr key={s.id}>
                  <td style={{ color: 'var(--text-muted)', fontSize: 12 }}>#{s.id}</td>
                  <td style={{ fontWeight: 500 }} className="text-truncate">{s.title}</td>
                  <td style={{ color: 'var(--text-muted)' }}>{s.artist}</td>
                  <td style={{ color: 'var(--text-muted)' }}>{s.bpm ?? '—'}</td>
                  <td>
                    {s.creator ? (
                      <span className="badge regular">👤 {s.creator.name}</span>
                    ) : (
                      <span className="badge system">⚙ System</span>
                    )}
                  </td>
                  <td style={{ color: 'var(--text-muted)', fontSize: 13 }}>
                    {new Date(s.createdAt).toLocaleDateString('uk-UA')}
                  </td>
                  <td>
                    <div className="actions-cell">
                      <button className="btn btn-primary" onClick={() => openEdit(s)}>✏ Редагувати</button>
                      <button className="btn btn-danger" onClick={() => deleteSong(s.id, s.title)}>🗑</button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {/* Modal */}
      {modalOpen && (
        <div className="modal-overlay" onClick={e => e.target === e.currentTarget && setModalOpen(false)}>
          <div className="modal">
            <div className="modal-header">
              <h2 className="modal-title">{editingSong ? '✏ Редагувати пісню' : '+ Нова пісня'}</h2>
              <button className="modal-close" onClick={() => setModalOpen(false)}>✕</button>
            </div>

            <div className="form-grid">
              <div className="form-field">
                <label className="form-label">Назва *</label>
                <input className="form-input" value={form.title} onChange={e => setForm(f => ({ ...f, title: e.target.value }))} placeholder="Bohemian Rhapsody" />
              </div>
              <div className="form-field">
                <label className="form-label">Виконавець</label>
                <input className="form-input" value={form.artist} onChange={e => setForm(f => ({ ...f, artist: e.target.value }))} placeholder="Queen" />
              </div>
              <div className="form-field">
                <label className="form-label">BPM</label>
                <input className="form-input" type="number" value={form.bpm} onChange={e => setForm(f => ({ ...f, bpm: e.target.value }))} placeholder="120" />
              </div>
              <div className="form-field">
                <label className="form-label">YouTube URL</label>
                <input className="form-input" value={form.youtubeUrl} onChange={e => setForm(f => ({ ...f, youtubeUrl: e.target.value }))} placeholder="https://youtube.com/..." />
              </div>
              <div className="form-field span2">
                <label className="form-label">Акорди *</label>
                <textarea className="form-textarea" rows={3} value={form.chords} onChange={e => setForm(f => ({ ...f, chords: e.target.value }))} placeholder="Am C G D Em..." />
              </div>
              <div className="form-field span2">
                <label className="form-label">Текст пісні (слова) *</label>
                <textarea className="form-textarea" rows={5} value={form.lyrics} onChange={e => setForm(f => ({ ...f, lyrics: e.target.value }))} placeholder="Слова пісні..." />
              </div>
            </div>

            <div className="modal-actions">
              <button className="btn btn-ghost" onClick={() => setModalOpen(false)}>Скасувати</button>
              <button className="btn btn-primary" onClick={handleSave} disabled={saving}>
                {saving ? 'Збереження...' : editingSong ? '✓ Зберегти' : '+ Створити'}
              </button>
            </div>
          </div>
        </div>
      )}

      {toast && <div className={`toast ${toast.type}`}>{toast.msg}</div>}
    </div>
  );
}
