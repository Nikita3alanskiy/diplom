import React, { useState } from 'react';

interface LoginProps {
  onLogin: () => void;
}

export default function Login({ onLogin }: LoginProps) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (username === 'admin' && password === 'admin123') {
      localStorage.setItem('admin_authenticated', 'true');
      onLogin();
    } else {
      setError('Неправильний логін або пароль');
    }
  };

  return (
    <div style={{
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      minHeight: '100vh',
      width: '100vw',
      background: 'radial-gradient(circle at center, #1e1b4b 0%, #09090b 100%)',
      fontFamily: 'Inter, sans-serif',
      position: 'fixed',
      top: 0,
      left: 0,
      zIndex: 9999,
    }}>
      <div style={{
        background: 'rgba(26, 29, 39, 0.85)',
        backdropFilter: 'blur(12px)',
        border: '1px solid rgba(255, 255, 255, 0.08)',
        borderRadius: '16px',
        padding: '40px',
        width: '100%',
        maxWidth: '400px',
        boxShadow: '0 20px 40px rgba(0, 0, 0, 0.5)',
        textAlign: 'center',
      }}>
        <div style={{ fontSize: '48px', marginBottom: '16px' }}>🎸</div>
        <h1 style={{
          fontSize: '24px',
          fontWeight: 700,
          marginBottom: '8px',
          background: 'linear-gradient(135deg, #a78bfa, #6c63ff)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent',
        }}>Strumly Admin</h1>
        <p style={{ color: '#8892a4', fontSize: '14px', marginBottom: '24px' }}>
          Вхід у панель керування додатком
        </p>

        {error && (
          <div style={{
            background: 'rgba(239, 68, 68, 0.1)',
            border: '1px solid #ef4444',
            color: '#ef4444',
            padding: '10px',
            borderRadius: '8px',
            fontSize: '13px',
            marginBottom: '16px',
            textAlign: 'left',
          }}>
            ⚠️ {error}
          </div>
        )}

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', textAlign: 'left' }}>
            <label style={{
              fontSize: '11px',
              fontWeight: 600,
              color: '#8892a4',
              textTransform: 'uppercase',
              letterSpacing: '0.05em',
            }}>Логін</label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="Введіть логін..."
              required
              style={{
                background: '#20243a',
                border: '1px solid #2a2d3e',
                borderRadius: '8px',
                padding: '12px',
                color: '#e2e8f0',
                fontSize: '14px',
                outline: 'none',
                transition: 'border-color 0.2s',
              }}
              onFocus={(e) => e.target.style.borderColor = '#6c63ff'}
              onBlur={(e) => e.target.style.borderColor = '#2a2d3e'}
            />
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '6px', textAlign: 'left' }}>
            <label style={{
              fontSize: '11px',
              fontWeight: 600,
              color: '#8892a4',
              textTransform: 'uppercase',
              letterSpacing: '0.05em',
            }}>Пароль</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Введіть пароль..."
              required
              style={{
                background: '#20243a',
                border: '1px solid #2a2d3e',
                borderRadius: '8px',
                padding: '12px',
                color: '#e2e8f0',
                fontSize: '14px',
                outline: 'none',
                transition: 'border-color 0.2s',
              }}
              onFocus={(e) => e.target.style.borderColor = '#6c63ff'}
              onBlur={(e) => e.target.style.borderColor = '#2a2d3e'}
            />
          </div>

          <button
            type="submit"
            style={{
              background: '#6c63ff',
              color: '#fff',
              border: 'none',
              borderRadius: '8px',
              padding: '12px',
              fontWeight: 600,
              fontSize: '14px',
              cursor: 'pointer',
              marginTop: '10px',
              transition: 'background 0.2s, transform 0.1s',
            }}
            onMouseOver={(e) => e.currentTarget.style.background = '#5a52e0'}
            onMouseOut={(e) => e.currentTarget.style.background = '#6c63ff'}
            onMouseDown={(e) => e.currentTarget.style.transform = 'scale(0.98)'}
            onMouseUp={(e) => e.currentTarget.style.transform = 'scale(1)'}
          >
            Увійти
          </button>
        </form>
      </div>
    </div>
  );
}
