import { BrowserRouter as Router, Routes, Route, NavLink } from 'react-router-dom';
import Users from './pages/Users';
import Songs from './pages/Songs';
import Chords from './pages/Chords';
import Dashboard from './pages/Dashboard';
import './App.css';

function App() {
  return (
    <Router>
      <div className="admin-layout">
        <aside className="sidebar">
          <div className="sidebar-logo">
            <div className="sidebar-logo-icon">🎸</div>
            <h2>Strumly</h2>
          </div>
          <nav>
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
