import { useState } from 'react';
import { api } from '../AuthContext';
import Sidebar from '../components/Sidebar';
import { AlertTriangle, CheckCircle2, Lightbulb } from 'lucide-react';

export default function ChangePasswordPage() {
  const [form, setForm] = useState({ old_password: '', new_password: '', confirm_password: '' });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const set = (k, v) => setForm(f => ({ ...f, [k]: v }));

  const handleSubmit = async e => {
    e.preventDefault();
    setError(''); setSuccess('');
    if (form.new_password !== form.confirm_password) { setError('New passwords do not match.'); return; }
    if (form.new_password.length < 8) { setError('Password must be at least 8 characters.'); return; }
    setLoading(true);
    try {
      const res = await api.post('/change-password/', form);
      setSuccess(res.data.message);
      setForm({ old_password: '', new_password: '', confirm_password: '' });
    } catch (e) {
      setError(e.response?.data?.error || 'Failed to change password.');
    } finally { setLoading(false); }
  };

  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <div className="dashboard-header">
          <h1>Change Password</h1>
          <p>Update your account password to keep it secure</p>
        </div>

        <div style={{ maxWidth: 480 }}>
          <div className="glass-card" style={{ padding: 36 }}>
            {error && <div className="alert alert-error" style={{ marginBottom: 20 }}><AlertTriangle size={18} /> {error}</div>}
            {success && <div className="alert alert-success" style={{ marginBottom: 20 }}><CheckCircle2 size={18} /> {success}</div>}

            <form onSubmit={handleSubmit}>
              <div className="form-group">
                <label>Current Password</label>
                <input className="form-input" type="password" placeholder="Your current password"
                  value={form.old_password} onChange={e => set('old_password', e.target.value)} required />
              </div>
              <div className="form-group">
                <label>New Password</label>
                <input className="form-input" type="password" placeholder="At least 8 characters"
                  value={form.new_password} onChange={e => set('new_password', e.target.value)} required />
              </div>
              <div className="form-group">
                <label>Confirm New Password</label>
                <input className="form-input" type="password" placeholder="Repeat new password"
                  value={form.confirm_password} onChange={e => set('confirm_password', e.target.value)} required />
              </div>
              <button type="submit" className="btn-primary" disabled={loading} style={{ width: '100%', justifyContent: 'center', marginTop: 8 }}>
                <span>{loading ? 'Updating...' : 'Update Password'}</span>
              </button>
            </form>
          </div>

          <div className="alert alert-info" style={{ marginTop: 16 }}>
            <Lightbulb className="inline-icon" size={18} /> After changing your password, you will need to log in again on all your devices.
          </div>
        </div>
      </main>
    </div>
  );
}
