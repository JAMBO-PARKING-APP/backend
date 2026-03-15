import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../AuthContext';
import { LayoutDashboard, PlusCircle, KeyRound, LogOut, Sun, Moon, Landmark } from 'lucide-react';
import { useState, useEffect } from 'react';

const NAV_ITEMS = [
  { to: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/add-zone', icon: PlusCircle, label: 'Add New Zone' },
  { to: '/bank-details', icon: Landmark, label: 'Bank Details' },
  { to: '/change-password', icon: KeyRound, label: 'Change Password' },
];

export default function Sidebar() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const initials = user ? `${user.first_name?.[0] || ''}${user.last_name?.[0] || ''}`.toUpperCase() : 'OP';

  const [theme, setTheme] = useState(localStorage.getItem('theme') || 'dark');
  
  useEffect(() => {
    if (theme === 'light') {
      document.documentElement.setAttribute('data-theme', 'light');
    } else {
      document.documentElement.removeAttribute('data-theme');
    }
    localStorage.setItem('theme', theme);
  }, [theme]);
  
  const toggleTheme = () => setTheme(prev => prev === 'light' ? 'dark' : 'light');

  return (
    <aside className="sidebar">
      <div className="sidebar-logo">
        <img src="/logo.png" alt="Space Park" style={{ height: 32, objectFit: 'contain' }} />
        <span>Partner Portal</span>
      </div>

      <nav className="sidebar-nav">
        {NAV_ITEMS.map(item => (
          <NavLink key={item.to} to={item.to} className={({ isActive }) => isActive ? 'active' : ''}>
            <item.icon size={20} />
            <span>{item.label}</span>
          </NavLink>
        ))}
      </nav>

      <div className="sidebar-bottom">
        <button onClick={toggleTheme} className="btn-secondary" style={{ width: '100%', marginBottom: 16, justifyContent: 'center', padding: '10px 12px' }}>
          {theme === 'light' ? <Moon size={18} /> : <Sun size={18} />}
          <span>{theme === 'light' ? 'Dark Mode' : 'Light Mode'}</span>
        </button>
        <div className="sidebar-user">
          <div className="sidebar-user-avatar">{initials}</div>
          <div className="sidebar-user-info">
            <div className="name">{user?.full_name || user?.first_name || 'Zone Owner'}</div>
            <div className="role">Zone Owner</div>
          </div>
        </div>
        <button onClick={() => { logout(); navigate('/login'); }}
          style={{ width: '100%', padding: '10px 12px', background: 'none', border: '1px solid var(--border)', borderRadius: 'var(--radius-md)',
            color: 'var(--danger)', cursor: 'pointer', fontSize: 14, fontFamily: 'Inter,sans-serif',
            marginTop: 8, display: 'flex', alignItems: 'center', gap: 8, justifyContent: 'center' }}>
          <LogOut size={16} /> Sign Out
        </button>
      </div>
    </aside>
  );
}
