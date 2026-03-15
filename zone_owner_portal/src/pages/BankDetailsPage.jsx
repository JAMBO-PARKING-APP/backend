import { useState } from 'react';
import { useAuth, api } from '../AuthContext';
import { Lock, AlertTriangle, CheckCircle2 } from 'lucide-react';
import Sidebar from '../components/Sidebar';

export default function BankDetailsPage() {
  const { user, setHasBankDetails } = useAuth();
  const [form, setForm] = useState({ bank_name: '', account_number: '', account_holder_name: '' });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const set = (k, v) => setForm(f => ({ ...f, [k]: v }));

  const handleSubmit = async e => {
    e.preventDefault();
    if (!form.bank_name || !form.account_number || !form.account_holder_name) {
      setError('All fields are required.'); return;
    }
    setLoading(true); setError(''); setSuccess('');
    try {
      await api.post('/bank-details/', form);
      setHasBankDetails(true);
      setSuccess('Bank details saved successfully.');
    } catch (e) {
      setError(e.response?.data?.error || Object.values(e.response?.data || {}).flat().join(', ') || 'Failed to save bank details.');
    } finally { setLoading(false); }
  };

  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <div className="dashboard-header" style={{ marginBottom: 30 }}>
          <h1>Bank Details</h1>
          <p>Manage your account for receiving payouts</p>
        </div>

        <div className="glass-card" style={{ maxWidth: 600 }}>
          <div className="alert alert-info" style={{ marginBottom: 24 }}>
            <Lock size={18} /> This information is kept secure and used only for depositing your parking earnings.
          </div>

          {error && <div className="alert alert-error" style={{ marginBottom: 24 }}><AlertTriangle size={18} /> {error}</div>}
          {success && <div className="alert alert-success" style={{ marginBottom: 24 }}><CheckCircle2 size={18} /> {success}</div>}

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label>Bank Name</label>
              <input className="form-input" placeholder="e.g. KCB Bank, Equity Bank" value={form.bank_name}
                onChange={e => set('bank_name', e.target.value)} required />
            </div>
            <div className="form-group">
              <label>Account Number</label>
              <input className="form-input" placeholder="Your bank account number" value={form.account_number}
                onChange={e => set('account_number', e.target.value)} required />
            </div>
            <div className="form-group">
              <label>Account Holder Name</label>
              <input className="form-input" placeholder="Name as it appears on the account" value={form.account_holder_name}
                onChange={e => set('account_holder_name', e.target.value)} required />
            </div>

            <button type="submit" className="btn-primary" disabled={loading} style={{ width: '100%', justifyContent: 'center', marginTop: 8 }}>
              <span>{loading ? 'Saving...' : 'Save Bank Details'}</span>
            </button>
          </form>
        </div>
      </main>
    </div>
  );
}
