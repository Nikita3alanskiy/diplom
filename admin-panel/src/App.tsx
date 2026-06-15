import { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, NavLink } from 'react-router-dom';
import Users from './pages/Users';
import Songs from './pages/Songs';
import Chords from './pages/Chords';
import Dashboard from './pages/Dashboard';
import Login from './pages/Login';
import './App.css';

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(
    localStorage.getItem('admin_authenticated') === 'true'
  );

  const handleLogin = () => {
    setIsAuthenticated(true);
  };

  const handleLogout = () => {
    localStorage.removeItem('admin_authenticated');
    setIsAuthenticated(false);
  };

  if (!isAuthenticated) {
    return <Login onLogin={handleLogin} />;
  }

  return (
    <Router>
      <div className="admin-layout">
        <aside className="sidebar">
          <div className="sidebar-logo">
            <div className="sidebar-logo-icon">🎸</div>
            <h2>Strumly</h2>
          </div>
          <nav style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '8px' }}>
            <NavLink to="/" end className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
              <span className="icon">📊</span> Dashboard
            </NavLink>
            <NavLink to="/users" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
              <span className="icon">👥</span> Користувачі
            </NavLink>
            <NavLink to="/songs" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
              <span className="icon">🎵</span> Пісні
            </NavLink>
            <NavLink to="/chords" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
              <span className="icon">🎼</span> Акорди
            </NavLink>
          </nav>
          <button 
            onClick={handleLogout} 
            className="nav-link" 
            style={{ 
              background: 'none', 
              border: 'none', 
              cursor: 'pointer', 
              width: '100%', 
              textAlign: 'left',
              marginTop: 'auto',
              color: 'var(--danger)'
            }}
          >
            <span className="icon">🚪</span> Вийти
          </button>
        </aside>
        <main className="content">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/users" element={<Users />} />
            <Route path="/songs" element={<Songs />} />
            <Route path="/chords" element={<Chords />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;
