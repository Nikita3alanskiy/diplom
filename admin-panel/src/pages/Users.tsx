import { useEffect, useState } from 'react';
import { apiFetch } from '../api/client';

interface User {
  id: number;
  email: string;
  name: string;
  isPremium: boolean;
  premiumUntil: string | null;
  createdAt: string;
  avatarUrl: string | null;
}

type Toast = { msg: string; type: 'success' | 'error' } | null;

export default function Users() {
  const [users, setUsers] = useState<User[]>([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [toast, setToast] = useState<Toast>(null);

  useEffect(() => { fetchUsers(); }, []);

  const showToast = (msg: string, type: 'success' | 'error') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 3000);
  };

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const data = await apiFetch<User[]>('/admin/users');
      setUsers(data);
      setError('');
    } catch (e: any) {
      setError('Не вдалося завантажити користувачів: ' + e.message);
    } finally {
      setLoading(false);
    }
  };

  const togglePremium = async (id: number, current: boolean) => {
    try {
      await apiFetch(`/admin/users/${id}/premium`, {
        method: 'PUT',
        body: JSON.stringify({ isPremium: !current }),
      });
      showToast(current ? 'Premium знято' : 'Premium надано ✨', 'success');
      fetchUsers();
    } catch (e: any) {
      showToast('Помилка: ' + e.message, 'error');
    }
  };

  const deleteUser = async (id: number, name: string) => {
    if (!confirm(`Видалити користувача "${name}"? Цю дію не можна скасувати.`)) return;
    try {
      await apiFetch(`/admin/users/${id}`, { method: 'DELETE' });
      showToast('Користувача видалено', 'success');
      fetchUsers();
    } catch (e: any) {
      showToast('Помилка: ' + e.message, 'error');
    }
  };

  const filtered = users.filter(
    u =>
      u.name.toLowerCase().includes(search.toLowerCase()) ||
      u.email.toLowerCase().includes(search.toLowerCase()),
  );

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">👥 Користувачі</h1>
        <span style={{ color: 'var(--text-muted)', fontSize: 14 }}>{users.length} всього</span>
      </div>

      {error && <div className="error-banner">{error}</div>}

      <div className="search-bar">
        <input
          className="search-input"
          placeholder="Пошук за іменем або email..."
          value={search}
          onChange={e => setSearch(e.target.value)}
        />
        <button className="btn btn-ghost" onClick={fetchUsers}>↻ Оновити</button>
      </div>

      <div className="table-wrapper">
        <table className="data-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Ім'я</th>
              <th>Email</th>
              <th>Статус</th>
              <th>Premium до</th>
              <th>Дата реєстрації</th>
              <th>Дії</th>
            </tr>
          </thead>
          <tbody>
            {loading ? (
              <tr><td colSpan={7} style={{ textAlign: 'center', padding: 32, color: 'var(--text-muted)' }}>Завантаження...</td></tr>
            ) : filtered.length === 0 ? (
              <tr><td colSpan={7}><div className="empty-state"><div className="empty-icon">👤</div>Користувачів не знайдено</div></td></tr>
            ) : (
              filtered.map(u => (
                <tr key={u.id}>
                  <td style={{ color: 'var(--text-muted)', fontSize: 12 }}>#{u.id}</td>
                  <td style={{ fontWeight: 500 }}>{u.name}</td>
                  <td style={{ color: 'var(--text-muted)' }}>{u.email}</td>
                  <td>
                    <span className={`badge ${u.isPremium ? 'premium' : 'regular'}`}>
                      {u.isPremium ? '⭐ Premium' : 'Free'}
                    </span>
                  </td>
                  <td style={{ color: 'var(--text-muted)', fontSize: 13 }}>
                    {u.premiumUntil ? new Date(u.premiumUntil).toLocaleDateString('uk-UA') : '—'}
                  </td>
                  <td style={{ color: 'var(--text-muted)', fontSize: 13 }}>
                    {new Date(u.createdAt).toLocaleDateString('uk-UA')}
                  </td>
                  <td>
                    <div className="actions-cell">
                      <button
                        className={`btn ${u.isPremium ? 'btn-warning' : 'btn-success'}`}
                        onClick={() => togglePremium(u.id, u.isPremium)}
                      >
                        {u.isPremium ? '⭐ Забрати' : '⭐ Дати'}
                      </button>
                      <button className="btn btn-danger" onClick={() => deleteUser(u.id, u.name)}>
                        🗑
                      </button>
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>

      {toast && <div className={`toast ${toast.type}`}>{toast.msg}</div>}
    </div>
  );
}
