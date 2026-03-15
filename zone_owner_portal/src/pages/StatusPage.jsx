import { useState, useRef } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../AuthContext';
import { Hourglass, CheckCircle2, XCircle, AlertTriangle } from 'lucide-react';

export default function StatusPage() {
  const [appId, setAppId] = useState('');
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const check = async () => {
    if (!appId.trim()) { setError('Please enter an Application ID.'); return; }
    setLoading(true); setError(''); setResult(null);
    try {
      const res = await api.get(`/status/${appId.trim()}/`);
      setResult(res.data);
    } catch (e) {
      if (e.response?.status === 404) setError('No application found with this ID. Please check and try again.');
      else setError('Something went wrong. Please try again.');
    } finally { setLoading(false); }
  };

  const statusConfig = {
    pending: { label: 'Under Review', icon: <Hourglass size={40} color="var(--warning)" />, badge: 'badge-pending', msg: 'Your application is being reviewed by our team. This typically takes 2–5 business days.' },
    approved: { label: 'Approved', icon: <CheckCircle2 size={40} color="var(--success)" />, badge: 'badge-approved', msg: 'Congratulations! Your zone has been approved and is now live. Check your email for login credentials.' },
    rejected: { label: 'Not Approved', icon: <XCircle size={40} color="var(--danger)" />, badge: 'badge-rejected', msg: 'Unfortunately your application was not approved at this time. Please check the notes below or contact support.' },
  };

  const cfg = result ? statusConfig[result.status] : null;

  return (
    <>
      <nav className="navbar">
        <Link to="/" className="navbar-logo"><img src="/logo.png" alt="Space Park" style={{ height: 36, objectFit: 'contain' }} /><span>Space Park</span></Link>
        <div className="navbar-links">
          <Link to="/apply">Apply Now</Link>
          <Link to="/login" style={{ color: 'var(--accent-light)', fontWeight: 600 }}>Partner Login</Link>
        </div>
      </nav>

      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '100px 24px 60px',
        background: 'radial-gradient(ellipse 70% 50% at 50% 0%, rgba(99,102,241,0.15) 0%, transparent 60%)' }}>
        <div style={{ maxWidth: 580, width: '100%' }}>
          <div style={{ textAlign: 'center', marginBottom: 40 }}>
            <h1 style={{ fontSize: 36, fontWeight: 900, marginBottom: 12 }}>Check Application Status</h1>
            <p style={{ color: 'var(--text-secondary)', fontSize: 16 }}>Enter your Application ID to see the current status of your submission</p>
          </div>

          <div style={{ background: 'var(--bg-card)', border: '1px solid var(--border)', borderRadius: 20, padding: 40 }}>
            <div className="form-group">
              <label>Application ID</label>
              <input className="form-input" placeholder="e.g. a1b2c3d4-e5f6-7890-abcd-ef1234567890"
                value={appId} onChange={e => setAppId(e.target.value)}
                onKeyDown={e => e.key === 'Enter' && check()} />
            </div>
            {error && <div className="alert alert-error" style={{ marginBottom: 16 }}><AlertTriangle size={18} /> {error}</div>}
            <button className="btn-primary" onClick={check} disabled={loading} style={{ width: '100%', justifyContent: 'center' }}>
              <span>{loading ? 'Checking...' : 'Check Status'}</span>
            </button>
          </div>

          {result && cfg && (
            <div className="glass-card animate-in" style={{ marginTop: 24, padding: 32 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 20 }}>
                <div style={{ fontSize: 40 }}>{cfg.icon}</div>
                <div>
                  <h2 style={{ fontSize: 22, fontWeight: 800 }}>{result.proposed_name}</h2>
                  <span className={`badge ${cfg.badge}`}>{cfg.label}</span>
                </div>
              </div>
              <p style={{ color: 'var(--text-secondary)', lineHeight: 1.7, marginBottom: 20 }}>{cfg.msg}</p>
              {result.admin_notes && (
                <div className="alert alert-info">
                  <div><strong>Admin Notes:</strong> {result.admin_notes}</div>
                </div>
              )}
              <p style={{ fontSize: 12, color: 'var(--text-muted)' }}>
                Submitted on {new Date(result.created_at).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })}
              </p>
              {result.status === 'approved' && (
                <div style={{ marginTop: 20 }}>
                  <Link to="/login" className="btn-primary" style={{ width: '100%', justifyContent: 'center' }}>
                    <span>→ Log in to Partner Dashboard</span>
                  </Link>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </>
  );
}
