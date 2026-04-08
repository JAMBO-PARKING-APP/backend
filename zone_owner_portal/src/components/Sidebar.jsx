import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../AuthContext';
import { LayoutDashboard, PlusCircle, KeyRound, LogOut, Sun, Moon, Landmark, Settings, DollarSign, Globe } from 'lucide-react';
import { useState, useEffect } from 'react';

const NAV_ITEMS = [
  { to: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/add-zone', icon: PlusCircle, label: 'Add New Zone' },
  { to: '/manage-zones', icon: Settings, label: 'Manage Zones' },
  { to: '/pricing-rules', icon: DollarSign, label: 'Pricing Rules' },
  { to: '/bank-details', icon: Landmark, label: 'Bank Details' },
  { to: '/change-password', icon: KeyRound, label: 'Change Password' },
];

const LANGUAGES = [
  { code: 'en', name: 'English', flag: '🇺🇸' },
  { code: 'es', name: 'Español', flag: '🇪🇸' },
  { code: 'fr', name: 'Français', flag: '🇫🇷' },
  { code: 'de', name: 'Deutsch', flag: '🇩🇪' },
  { code: 'it', name: 'Italiano', flag: '🇮🇹' },
  { code: 'pt', name: 'Português', flag: '🇵🇹' },
  { code: 'nl', name: 'Nederlands', flag: '🇳🇱' },
  { code: 'sv', name: 'Svenska', flag: '🇸🇪' },
  { code: 'da', name: 'Dansk', flag: '🇩🇰' },
  { code: 'no', name: 'Norsk', flag: '🇳🇴' },
  { code: 'fi', name: 'Suomi', flag: '🇫🇮' },
];

export default function Sidebar() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const initials = user ? `${user.first_name?.[0] || ''}${user.last_name?.[0] || ''}`.toUpperCase() : 'OP';

  const [theme, setTheme] = useState(localStorage.getItem('theme') || 'dark');
  const [language, setLanguage] = useState(localStorage.getItem('language') || 'en');
  const [showLanguageDropdown, setShowLanguageDropdown] = useState(false);

  useEffect(() => {
    if (theme === 'light') {
      document.documentElement.setAttribute('data-theme', 'light');
    } else {
      document.documentElement.removeAttribute('data-theme');
    }
    localStorage.setItem('theme', theme);
  }, [theme]);

  useEffect(() => {
    localStorage.setItem('language', language);
    // Here you would typically update the app's language
    // For now, we'll just store it
  }, [language]);

  // Close language dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event) => {
      if (showLanguageDropdown && !event.target.closest('.language-selector')) {
        setShowLanguageDropdown(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [showLanguageDropdown]);

  const toggleTheme = () => setTheme(prev => prev === 'light' ? 'dark' : 'light');

  const currentLanguage = LANGUAGES.find(lang => lang.code === language) || LANGUAGES[0];

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
        {/* Language Selector */}
        <div className="language-selector" style={{ position: 'relative', marginBottom: 16 }}>
          <button
            onClick={() => setShowLanguageDropdown(!showLanguageDropdown)}
            className="btn-secondary"
            style={{
              width: '100%',
              justifyContent: 'center',
              padding: '10px 12px',
              display: 'flex',
              alignItems: 'center',
              gap: 8
            }}
          >
            <Globe size={18} />
            <span>{currentLanguage.flag} {currentLanguage.name}</span>
          </button>

          {showLanguageDropdown && (
            <div style={{
              position: 'absolute',
              bottom: '100%',
              left: 0,
              right: 0,
              background: 'var(--bg-card)',
              border: '1px solid var(--border)',
              borderRadius: 'var(--radius-md)',
              boxShadow: 'var(--shadow-lg)',
              marginBottom: 8,
              maxHeight: '200px',
              overflowY: 'auto',
              zIndex: 1000
            }}>
              {LANGUAGES.map(lang => (
                <button
                  key={lang.code}
                  onClick={() => {
                    setLanguage(lang.code);
                    setShowLanguageDropdown(false);
                  }}
                  style={{
                    width: '100%',
                    padding: '10px 12px',
                    border: 'none',
                    background: language === lang.code ? 'var(--accent)' : 'transparent',
                    color: language === lang.code ? 'white' : 'var(--text-primary)',
                    textAlign: 'left',
                    cursor: 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 8,
                    fontSize: 14,
                    transition: 'all 0.2s ease'
                  }}
                  onMouseEnter={(e) => {
                    if (language !== lang.code) {
                      e.target.style.background = 'var(--bg-card-hover)';
                    }
                  }}
                  onMouseLeave={(e) => {
                    if (language !== lang.code) {
                      e.target.style.background = 'transparent';
                    }
                  }}
                >
                  <span>{lang.flag}</span>
                  <span>{lang.name}</span>
                </button>
              ))}
            </div>
          )}
        </div>

        <button onClick={toggleTheme} className="btn-secondary" style={{ width: '100%', marginBottom: 16, justifyContent: 'center', padding: '10px 12px' }}>
          {theme === 'light' ? <Moon size={18} /> : <Sun size={18} />}
          <span>{theme === 'light' ? 'Dark Theme' : 'Light Theme'}</span>
        </button>
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
