import { useEffect, useState } from 'react';
import { apiFetch } from '../api/client';

interface Chord {
  id: number;
  name: string;
  fingering: string;
  category: string | null;
  difficulty: string | null;
  description: string | null;
  createdAt: string;
}

interface ChordForm {
  name: string;
  fingering: string;
  category: string;
  difficulty: string;
  description: string;
}

const EMPTY_FORM: ChordForm = { name: '', fingering: '', category: '', difficulty: '', description: '' };
const CATEGORIES = ['Major', 'Minor', '7th', 'Sus', 'Dim', 'Aug', 'Power', 'Other'];
const DIFFICULTIES = ['beginner', 'intermediate', 'advanced'];

type Toast = { msg: string; type: 'success' | 'error' } | null;

export default function Chords() {
  const [chords, setChords] = useState<Chord[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [toast, setToast] = useState<Toast>(null);

  const [modalOpen, setModalOpen] = useState(false);
  const [editingChord, setEditingChord] = useState<Chord | null>(null);
  const [form, setForm] = useState<ChordForm>(EMPTY_FORM);
  const [saving, setSaving] = useState(false);

  useEffect(() => { fetchChords(); }, []);

  const showToast = (msg: string, type: 'success' | 'error') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 3000);
  };

  const fetchChords = async () => {
    setLoading(true);
    try {
      const data = await apiFetch<Chord[]>('/admin/chords');
      setChords(data);
      setError('');
    } catch (e: any) {
      setError('Не вдалося завантажити акорди: ' + e.message);
    } finally {
      setLoading(false);
    }
  };

  const openCreate = () => {
    setEditingChord(null);
    setForm(EMPTY_FORM);
    setModalOpen(true);
  };

  const openEdit = (c: Chord) => {
    setEditingChord(c);
    setForm({
      name: c.name,
      fingering: c.fingering,
      category: c.category || '',
      difficulty: c.difficulty || '',
      description: c.description || '',
    });
    setModalOpen(true);
  };

  const handleSave = async () => {
    if (!form.name.trim() || !form.fingering.trim()) {
      showToast("Назва та аплікатура — обов'язкові", 'error');
      return;
    }
    setSaving(true);
    const body = {
      name: form.name.trim(),
      fingering: form.fingering.trim(),
      category: form.category || undefined,
      difficulty: form.difficulty || undefined,
      description: form.description.trim() || undefined,
    };
    try {
      if (editingChord) {
        await apiFetch(`/admin/chords/${editingChord.id}`, { method: 'PUT', body: JSON.stringify(body) });
        showToast('Акорд оновлено ✓', 'success');
      } else {
        await apiFetch('/admin/chords', { method: 'POST', body: JSON.stringify(body) });
        showToast('Акорд створено ✓', 'success');
      }
      setModalOpen(false);
      fetchChords();
    } catch (e: any) {
      showToast('Помилка: ' + e.message, 'error');
    } finally {
      setSaving(false);
    }
  };

  const deleteChord = async (id: number, name: string) => {
    if (!confirm(`Видалити акорд "${name}"?`)) return;
    try {
      await apiFetch(`/admin/chords/${id}`, { method: 'DELETE' });
      showToast('Акорд видалено', 'success');
      fetchChords();
    } catch (e: any) {
      showToast('Помилка: ' + e.message, 'error');
    }
  };

  const filtered = chords.filter(c =>
    c.name.toLowerCase().includes(search.toLowerCase()) ||
    (c.category || '').toLowerCase().includes(search.toLowerCase()),
  );

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">🎼 Акорди</h1>
        <button className="btn btn-primary" onClick={openCreate}>+ Додати акорд</button>
      </div>

      {error && <div className="error-banner">{error}</div>}

      <div className="search-bar">
        <input
          className="search-input"
          placeholder="Пошук за назвою або категорією..."
          value={search}
          onChange={e => setSearch(e.target.value)}
        />
        <button className="btn btn-ghost" onClick={fetchChords}>↻ Оновити</button>
      </div>

      <div className="table-wrapper">
        <table className="data-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Назва</th>
              <th>Аплікатура</th>
              <th>Категорія</th>
              <th>Складність</th>
              <th>Опис</th>
              <th>Дії</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={7} style={{ textAlign: 'center', padding: 32, color: 'var(--text-muted)' }}>Завантаження...</td></tr>
            ) : filtered.length === 0 ? (
              <tr>
                <td colSpan={7}>
                  <div className="empty-state">
                    <div className="empty-icon">🎼</div>
                    Акордів не знайдено. Додайте перший!
                  </div>
                </td>
              </tr>
            ) : (
              filtered.map(c => (
                <tr key={c.id}>
                  <td style={{ color: 'var(--text-muted)', fontSize: 12 }}>#{c.id}</td>
                  <td>
                    <strong style={{ fontSize: 16, color: 'var(--primary)' }}>{c.name}</strong>
                  </td>
                  <td>
                    <code style={{ background: 'var(--bg-card2)', padding: '3px 8px', borderRadius: 6, fontSize: 12, color: 'var(--text-muted)' }}>
                      {c.fingering.length > 30 ? c.fingering.slice(0, 30) + '…' : c.fingering}
                    </code>
                  </td>
                  <td>{c.category ? <span className="badge regular">{c.category}</span> : '—'}</td>
                  <td>
                    {c.difficulty ? (
                      <span className={`badge ${c.difficulty}`}>{c.difficulty}</span>
                    ) : '—'}
                  </td>
                  <td style={{ color: 'var(--text-muted)', fontSize: 13 }} className="text-truncate">
                    {c.description || '—'}
                  </td>
                  <td>
                    <div className="actions-cell">
                      <button className="btn btn-primary" onClick={() => openEdit(c)}>✏</button>
                      <button className="btn btn-danger" onClick={() => deleteChord(c.id, c.name)}>🗑</button>
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
              <h2 className="modal-title">{editingChord ? '✏ Редагувати акорд' : '+ Новий акорд'}</h2>
              <button className="modal-close" onClick={() => setModalOpen(false)}>✕</button>
            </div>

            <div className="form-grid">
              <div className="form-field">
                <label className="form-label">Назва акорду *</label>
                <input
                  className="form-input"
                  value={form.name}
                  onChange={e => setForm(f => ({ ...f, name: e.target.value }))}
                  placeholder="Am, C, G7..."
                />
              </div>
              <div className="form-field">
                <label className="form-label">Категорія</label>
                <select
                  className="form-select"
                  value={form.category}
                  onChange={e => setForm(f => ({ ...f, category: e.target.value }))}
                >
                  <option value="">— Оберіть —</option>
                  {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
                </select>
              </div>
              <div className="form-field">
                <label className="form-label">Складність</label>
                <select
                  className="form-select"
                  value={form.difficulty}
                  onChange={e => setForm(f => ({ ...f, difficulty: e.target.value }))}
                >
                  <option value="">— Оберіть —</option>
                  {DIFFICULTIES.map(d => <option key={d} value={d}>{d}</option>)}
                </select>
              </div>
              <div className="form-field span2">
                <label className="form-label">Аплікатура * (позиції пальців / текст)</label>
                <textarea
                  className="form-textarea"
                  rows={3}
                  value={form.fingering}
                  onChange={e => setForm(f => ({ ...f, fingering: e.target.value }))}
                  placeholder="x02210  або  Вказівний: 2 струна, 1 лад..."
                />
              </div>
              <div className="form-field span2">
                <label className="form-label">Опис (необов'язково)</label>
                <textarea
                  className="form-textarea"
                  rows={2}
                  value={form.description}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                  placeholder="Ля мінор — один з найпопулярніших акордів..."
                />
              </div>
            </div>

            <div className="modal-actions">
              <button className="btn btn-ghost" onClick={() => setModalOpen(false)}>Скасувати</button>
              <button className="btn btn-primary" onClick={handleSave} disabled={saving}>
                {saving ? 'Збереження...' : editingChord ? '✓ Зберегти' : '+ Створити'}
              </button>
            </div>
          </div>
        </div>
      )}

      {toast && <div className={`toast ${toast.type}`}>{toast.msg}</div>}
    </div>
  );
}
