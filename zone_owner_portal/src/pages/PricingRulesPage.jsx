import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { api } from '../AuthContext';
import Sidebar from '../components/Sidebar';
import { Plus, Edit, Trash2, Clock, TrendingUp, Calendar, AlertCircle, CheckCircle } from 'lucide-react';

export default function PricingRulesPage() {
  const { zoneId } = useParams();
  const navigate = useNavigate();
  const [rules, setRules] = useState([]);
  const [zone, setZone] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [editingRule, setEditingRule] = useState(null);

  useEffect(() => {
    loadData();
  }, [zoneId]);

  const loadData = async () => {
    try {
      const [rulesRes, zoneRes] = await Promise.all([
        api.get(`/parking/owner/zones/${zoneId}/pricing-rules/`),
        api.get(`/parking/owner/zones/${zoneId}/edit/`)
      ]);
      setRules(rulesRes.data);
      setZone(zoneRes.data);
    } catch (err) {
      setError('Failed to load pricing rules');
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (ruleId) => {
    if (!confirm('Are you sure you want to delete this pricing rule?')) return;

    try {
      await api.delete(`/parking/owner/pricing-rules/${ruleId}/`);
      setRules(rules.filter(r => r.id !== ruleId));
    } catch (err) {
      setError('Failed to delete pricing rule');
    }
  };

  const toggleRule = async (ruleId, isActive) => {
    try {
      await api.patch(`/parking/owner/pricing-rules/${ruleId}/`, { is_active: !isActive });
      setRules(rules.map(r => r.id === ruleId ? { ...r, is_active: !isActive } : r));
    } catch (err) {
      setError('Failed to update pricing rule');
    }
  };

  const getRuleTypeIcon = (ruleType) => {
    switch (ruleType) {
      case 'time_based': return <Clock size={16} />;
      case 'demand_based': return <TrendingUp size={16} />;
      case 'special_event': return <Calendar size={16} />;
      default: return <AlertCircle size={16} />;
    }
  };

  const getRuleTypeLabel = (ruleType) => {
    switch (ruleType) {
      case 'time_based': return 'Time Based';
      case 'demand_based': return 'Demand Based';
      case 'special_event': return 'Special Event';
      default: return ruleType;
    }
  };

  if (loading) return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <div className="loading-center"><div className="spinner" /><span>Loading pricing rules...</span></div>
      </main>
    </div>
  );

  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <div className="dashboard-header">
          <div>
            <h1>Pricing Rules</h1>
            <p>Manage dynamic pricing for {zone?.name}</p>
          </div>
          <button
            className="btn-primary"
            onClick={() => setShowCreateForm(true)}
            style={{ display: 'flex', alignItems: 'center', gap: 8 }}
          >
            <Plus size={16} />
            Add Rule
          </button>
        </div>

        {error && <div className="alert alert-error">⚠️ {error}</div>}

        {/* Zone Status */}
        <div className="glass-card" style={{ padding: 20, marginBottom: 24 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div>
              <h3 style={{ margin: 0, fontSize: 16, fontWeight: 600 }}>{zone?.name}</h3>
              <p style={{ margin: '4px 0 0 0', color: 'var(--text-muted)', fontSize: 14 }}>
                Base Rate: {zone?.hourly_rate} | Dynamic Pricing: {zone?.supports_dynamic_pricing ? 'Enabled' : 'Disabled'}
              </p>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--accent)' }}>
                  {zone?.current_occupancy_rate?.toFixed(1)}%
                </div>
                <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>Current Occupancy</div>
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--success)' }}>
                  {rules.filter(r => r.is_active).length}
                </div>
                <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>Active Rules</div>
              </div>
            </div>
          </div>
        </div>

        {/* Rules List */}
        <div className="glass-card" style={{ padding: 28 }}>
          <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 20 }}>
            Pricing Rules ({rules.length})
          </h2>

          {rules.length === 0 ? (
            <div style={{ textAlign: 'center', padding: '40px 20px' }}>
              <AlertCircle size={48} color="var(--text-muted)" style={{ marginBottom: 16 }} />
              <h3 style={{ color: 'var(--text-muted)', marginBottom: 8 }}>No pricing rules yet</h3>
              <p style={{ color: 'var(--text-muted)', marginBottom: 20 }}>
                Create your first dynamic pricing rule to optimize revenue based on time or demand.
              </p>
              <button className="btn-primary" onClick={() => setShowCreateForm(true)}>
                <Plus size={16} style={{ marginRight: 8 }} />
                Create First Rule
              </button>
            </div>
          ) : (
            <div style={{ display: 'grid', gap: 16 }}>
              {rules.map(rule => (
                <div key={rule.id} style={{
                  padding: 20,
                  border: '1px solid var(--border)',
                  borderRadius: 'var(--radius-md)',
                  background: rule.is_active ? 'rgba(16, 185, 129, 0.05)' : 'rgba(255, 255, 255, 0.02)'
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                      <div style={{
                        padding: 8,
                        borderRadius: 'var(--radius-sm)',
                        background: rule.is_active ? 'var(--success)' : 'var(--text-muted)',
                        color: 'white'
                      }}>
                        {getRuleTypeIcon(rule.rule_type)}
                      </div>
                      <div>
                        <h4 style={{ margin: 0, fontSize: 16, fontWeight: 600 }}>{rule.name}</h4>
                        <p style={{ margin: '4px 0 0 0', color: 'var(--text-muted)', fontSize: 14 }}>
                          {getRuleTypeLabel(rule.rule_type)} • Priority: {rule.priority} • Rate: {rule.hourly_rate}
                        </p>
                      </div>
                    </div>

                    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                      <span className={`badge ${rule.is_active ? 'badge-approved' : 'badge-pending'}`}>
                        {rule.is_active ? 'Active' : 'Inactive'}
                      </span>

                      <div style={{ display: 'flex', gap: 8 }}>
                        <button
                          className="btn-secondary"
                          onClick={() => toggleRule(rule.id, rule.is_active)}
                          style={{ padding: '6px 12px', fontSize: 12 }}
                        >
                          {rule.is_active ? 'Disable' : 'Enable'}
                        </button>
                        <button
                          className="btn-secondary"
                          onClick={() => setEditingRule(rule)}
                          style={{ padding: '6px 12px', fontSize: 12 }}
                        >
                          <Edit size={14} />
                        </button>
                        <button
                          className="btn-danger"
                          onClick={() => handleDelete(rule.id)}
                          style={{ padding: '6px 12px', fontSize: 12 }}
                        >
                          <Trash2 size={14} />
                        </button>
                      </div>
                    </div>
                  </div>

                  {rule.description && (
                    <p style={{ margin: '12px 0 0 0', color: 'var(--text-secondary)', fontSize: 14 }}>
                      {rule.description}
                    </p>
                  )}

                  {/* Rule-specific details */}
                  <div style={{ marginTop: 12, padding: 12, background: 'rgba(255, 255, 255, 0.02)', borderRadius: 'var(--radius-sm)' }}>
                    {rule.rule_type === 'time_based' && (
                      <div style={{ display: 'flex', gap: 16, fontSize: 13, color: 'var(--text-muted)' }}>
                        <span>Time: {rule.start_time} - {rule.end_time}</span>
                        <span>Days: {rule.days_of_week?.join(', ') || 'All days'}</span>
                      </div>
                    )}
                    {rule.rule_type === 'demand_based' && (
                      <div style={{ display: 'flex', gap: 16, fontSize: 13, color: 'var(--text-muted)' }}>
                        <span>Occupancy: {rule.comparison === 'gte' ? '≥' : '≤'} {rule.occupancy_threshold}%</span>
                      </div>
                    )}
                    {rule.rule_type === 'special_event' && (
                      <div style={{ display: 'flex', gap: 16, fontSize: 13, color: 'var(--text-muted)' }}>
                        <span>Period: {new Date(rule.start_datetime).toLocaleDateString()} - {new Date(rule.end_datetime).toLocaleDateString()}</span>
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Create/Edit Form Modal would go here */}
        {showCreateForm && <PricingRuleForm onClose={() => setShowCreateForm(false)} onSave={() => { setShowCreateForm(false); loadData(); }} zoneId={zoneId} />}
        {editingRule && <PricingRuleForm rule={editingRule} onClose={() => setEditingRule(null)} onSave={() => { setEditingRule(null); loadData(); }} zoneId={zoneId} />}
      </main>
    </div>
  );
}

// Placeholder for the form component - would need to be implemented
function PricingRuleForm({ rule, onClose, onSave, zoneId }) {
  return (
    <div style={{
      position: 'fixed',
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      background: 'rgba(0, 0, 0, 0.5)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      zIndex: 1000
    }}>
      <div style={{
        background: 'var(--bg-primary)',
        border: '1px solid var(--border)',
        borderRadius: 'var(--radius-lg)',
        padding: 24,
        maxWidth: 500,
        width: '90%'
      }}>
        <h3>{rule ? 'Edit' : 'Create'} Pricing Rule</h3>
        <p>Form implementation needed - this is a placeholder</p>
        <div style={{ display: 'flex', gap: 12, justifyContent: 'flex-end', marginTop: 20 }}>
          <button className="btn-secondary" onClick={onClose}>Cancel</button>
          <button className="btn-primary" onClick={onSave}>Save</button>
        </div>
      </div>
    </div>
  );
}