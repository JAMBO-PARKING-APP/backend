import { useLanguage } from '../LanguageContext';
import { Globe } from 'lucide-react';
import { useState, useEffect } from 'react';

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

export default function LanguageSelector({ compact = false }) {
  const { language, setLanguage } = useLanguage();
  const [showDropdown, setShowDropdown] = useState(false);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (showDropdown && !event.target.closest('.language-selector')) {
        setShowDropdown(false);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [showDropdown]);

  const currentLanguage = LANGUAGES.find(lang => lang.code === language) || LANGUAGES[0];

  if (compact) {
    return (
      <div className="language-selector" style={{ position: 'relative' }}>
        <button
          onClick={() => setShowDropdown(!showDropdown)}
          style={{
            background: 'none',
            border: 'none',
            color: 'var(--text-primary)',
            cursor: 'pointer',
            fontSize: 14,
            display: 'flex',
            alignItems: 'center',
            gap: 4,
            padding: '4px 8px',
            borderRadius: 'var(--radius-sm)'
          }}
        >
          <span>{currentLanguage.flag}</span>
          <span>{currentLanguage.code.toUpperCase()}</span>
        </button>

        {showDropdown && (
          <div style={{
            position: 'absolute',
            top: '100%',
            right: 0,
            background: 'var(--bg-card)',
            border: '1px solid var(--border)',
            borderRadius: 'var(--radius-md)',
            boxShadow: 'var(--shadow-lg)',
            marginTop: 4,
            maxHeight: '200px',
            overflowY: 'auto',
            zIndex: 1000,
            minWidth: '120px'
          }}>
            {LANGUAGES.map(lang => (
              <button
                key={lang.code}
                onClick={() => {
                  setLanguage(lang.code);
                  setShowDropdown(false);
                }}
                style={{
                  width: '100%',
                  padding: '8px 12px',
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
    );
  }

  return (
    <div className="language-selector" style={{ position: 'relative' }}>
      <button
        onClick={() => setShowDropdown(!showDropdown)}
        style={{
          background: 'none',
          border: '1px solid var(--border)',
          color: 'var(--text-primary)',
          cursor: 'pointer',
          fontSize: 14,
          display: 'flex',
          alignItems: 'center',
          gap: 8,
          padding: '8px 12px',
          borderRadius: 'var(--radius-md)',
          transition: 'all 0.2s ease'
        }}
        onMouseEnter={(e) => e.target.style.borderColor = 'var(--accent)'}
        onMouseLeave={(e) => e.target.style.borderColor = 'var(--border)'}
      >
        <Globe size={16} />
        <span>{currentLanguage.flag} {currentLanguage.name}</span>
      </button>

      {showDropdown && (
        <div style={{
          position: 'absolute',
          top: '100%',
          right: 0,
          background: 'var(--bg-card)',
          border: '1px solid var(--border)',
          borderRadius: 'var(--radius-md)',
          boxShadow: 'var(--shadow-lg)',
          marginTop: 8,
          maxHeight: '200px',
          overflowY: 'auto',
          zIndex: 1000,
          minWidth: '160px'
        }}>
          {LANGUAGES.map(lang => (
            <button
              key={lang.code}
              onClick={() => {
                setLanguage(lang.code);
                setShowDropdown(false);
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
  );
}