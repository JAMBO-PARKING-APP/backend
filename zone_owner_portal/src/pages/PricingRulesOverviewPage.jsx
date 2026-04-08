import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api } from '../AuthContext';
import Sidebar from '../components/Sidebar';
import { DollarSign, Plus, Clock, TrendingUp, Calendar, Settings, MapPin } from 'lucide-react';

export default function PricingRulesOverviewPage() {
  const navigate = useNavigate();
  const [zones, setZones] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    loadZones();
  }, []);

  const loadZones = async () => {
    try {
      const res = await api.get('/parking/owner/zones/');
      // Load pricing rules for each zone
      const zonesWithRules = await Promise.all(
        res.data.map(async (zone) => {
          try {
            const rulesRes = await api.get(`/parking/owner/zones/${zone.id}/pricing-rules/`);
            return { ...zone, pricing_rules: rulesRes.data };
          } catch (err) {
            return { ...zone, pricing_rules: [] };
          }
        })
      );
      setZones(zonesWithRules);
    } catch (err) {
      setError('Failed to load pricing rules');
    } finally {
      setLoading(false);
    }
  };

  const getRuleTypeIcon = (ruleType) => {
    switch (ruleType) {
      case 'time_based': return <Clock size={16} />;
      case 'demand_based': return <TrendingUp size={16} />;
      case 'special_event': return <Calendar size={16} />;
      default: return <Settings size={16} />;
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

  const totalActiveRules = zones.reduce((sum, zone) =>
    sum + (zone.pricing_rules?.filter(r => r.is_active).length || 0), 0
  );

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
            <p>Manage dynamic pricing across all your zones</p>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ textAlign: 'center' }}>
              <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--success)' }}>
                {totalActiveRules}
              </div>
              <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>Active Rules</div>
            </div>
            <button
              className="btn-primary"
              onClick={() => navigate('/manage-zones')}
              style={{ display: 'flex', alignItems: 'center', gap: 8 }}
            >
              <Settings size={16} />
              Manage Zones
            </button>
          </div>
        </div>

        {error && <div className="alert alert-error">⚠️ {error}</div>}

        {zones.length === 0 ? (
          <div className="glass-card" style={{ padding: 40, textAlign: 'center' }}>
            <MapPin size={48} color="var(--text-muted)" style={{ marginBottom: 16 }} />
            <h3 style={{ color: 'var(--text-muted)', marginBottom: 8 }}>No zones yet</h3>
            <p style={{ color: 'var(--text-muted)', marginBottom: 20 }}>
              Create your first parking zone to set up pricing rules.
            </p>
            <button className="btn-primary" onClick={() => navigate('/add-zone')}>
              <Plus size={16} style={{ marginRight: 8 }} />
              Create First Zone
            </button>
          </div>
        ) : (
          <div style={{ display: 'grid', gap: 24 }}>
            {zones.map(zone => (
              <div key={zone.id} className="glass-card" style={{ padding: 28 }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
                  <div>
                    <h3 style={{ margin: 0, fontSize: 18, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 8 }}>
                      <MapPin size={20} color="var(--accent)" />
                      {zone.name}
                      {zone.code && <span style={{ fontSize: 14, color: 'var(--text-muted)', fontWeight: 400 }}>({zone.code})</span>}
                    </h3>
                    <p style={{ margin: '4px 0 0 0', color: 'var(--text-muted)', fontSize: 14 }}>
                      Base Rate: {zone.hourly_rate} • Dynamic Pricing: {zone.supports_dynamic_pricing ? 'Enabled' : 'Disabled'}
                    </p>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    <div style={{ textAlign: 'center' }}>
                      <div style={{ fontSize: 20, fontWeight: 700, color: 'var(--success)' }}>
                        {zone.pricing_rules?.filter(r => r.is_active).length || 0}
                      </div>
                      <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>Active Rules</div>
                    </div>

                    <button
                      className="btn-primary"
                      onClick={() => navigate(`/zones/${zone.id}/pricing-rules`)}
                      style={{ padding: '10px 16px', fontSize: 14, display: 'flex', alignItems: 'center', gap: 6 }}
                    >
                      <DollarSign size={16} />
                      Manage Rules
                    </button>
                  </div>
                </div>

                {!zone.supports_dynamic_pricing ? (
                  <div style={{ padding: 20, background: 'rgba(245, 158, 11, 0.1)', border: '1px solid rgba(245, 158, 11, 0.3)', borderRadius: 'var(--radius-md)', textAlign: 'center' }}>
                    <Settings size={24} color="var(--warning)" style={{ marginBottom: 8 }} />
                    <p style={{ margin: 0, color: 'var(--warning)', fontWeight: 600 }}>Dynamic pricing is disabled for this zone</p>
                    <p style={{ margin: '8px 0 0 0', fontSize: 14, color: 'var(--text-muted)' }}>
                      Enable dynamic pricing in zone settings to create pricing rules.
                    </p>
                  </div>
                ) : zone.pricing_rules?.length === 0 ? (
                  <div style={{ padding: 20, background: 'rgba(255, 255, 255, 0.02)', border: '1px solid var(--border)', borderRadius: 'var(--radius-md)', textAlign: 'center' }}>
                    <DollarSign size={24} color="var(--text-muted)" style={{ marginBottom: 8 }} />
                    <p style={{ margin: 0, color: 'var(--text-muted)', fontWeight: 600 }}>No pricing rules yet</p>
                    <p style={{ margin: '8px 0 0 0', fontSize: 14, color: 'var(--text-muted)' }}>
                      Create your first pricing rule to optimize revenue.
                    </p>
                  </div>
                ) : (
                  <div style={{ display: 'grid', gap: 12 }}>
                    {zone.pricing_rules.map(rule => (
                      <div key={rule.id} style={{
                        padding: 16,
                        border: '1px solid var(--border)',
                        borderRadius: 'var(--radius-md)',
                        background: rule.is_active ? 'rgba(16, 185, 129, 0.05)' : 'rgba(255, 255, 255, 0.02)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between'
                      }}>
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

                        <span className={`badge ${rule.is_active ? 'badge-approved' : 'badge-pending'}`}>
                          {rule.is_active ? 'Active' : 'Inactive'}
                        </span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}