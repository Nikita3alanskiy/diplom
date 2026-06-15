import { useEffect, useState } from 'react';
import { apiFetch } from '../api/client';

interface Stats {
  totalUsers: number;
  premiumUsers: number;
  totalSongs: number;
  totalChords: number;
}

export default function Dashboard() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [error, setError] = useState('');

  useEffect(() => {
    apiFetch<Stats>('/admin/stats')
      .then(setStats)
      .catch(() => setError('Не вдалося завантажити статистику'));
  }, []);

  const cards = stats
    ? [
        { icon: '👥', label: 'Всього користувачів', value: stats.totalUsers, color: '#6c63ff' },
        { icon: '⭐', label: 'Premium користувачів', value: stats.premiumUsers, color: '#f59e0b' },
        { icon: '🎵', label: 'Пісень у базі', value: stats.totalSongs, color: '#22c55e' },
        { icon: '🎼', label: 'Акордів у базі', value: stats.totalChords, color: '#ec4899' },
      ]
    : [];

  return (
    <div>
      <div className="page-header">
        <h1 className="page-title">Панель керування</h1>
      </div>

      {error && <div className="error-banner">{error}</div>}

      {!stats && !error && (
        <div className="empty-state">
          <div className="empty-icon">⏳</div>
          Завантаження...
        </div>
      )}

      <div className="stats-grid">
        {cards.map(c => (
          <div className="stat-card" key={c.label} style={{ borderLeft: `3px solid ${c.color}` }}>
            <div className="stat-icon">{c.icon}</div>
            <div className="stat-value" style={{ color: c.color }}>{c.value}</div>
            <div className="stat-label">{c.label}</div>
          </div>
        ))}
      </div>

      <div className="table-wrapper" style={{ padding: '24px', lineHeight: 1.7 }}>
        <h3 style={{ marginBottom: 12, color: 'var(--text-muted)', fontSize: 13, textTransform: 'uppercase', letterSpacing: '0.05em' }}>Швидкі посилання</h3>
        <p style={{ fontSize: 14, color: 'var(--text-muted)' }}>
          ✅ Swagger UI: <a href={`${(import.meta.env.VITE_API_URL || 'http://localhost:3000/api').replace('/api', '')}/api/docs`} target="_blank" rel="noreferrer" style={{ color: 'var(--primary)' }}>Відкрити документацію API</a>
        </p>
      </div>
    </div>
  );
}
