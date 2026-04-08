import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api } from '../AuthContext';
import Sidebar from '../components/Sidebar';
import { Edit, DollarSign, MapPin, Users, TrendingUp, Settings, Plus } from 'lucide-react';

export default function ManageZonesPage() {
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
      setZones(res.data);
    } catch (err) {
      setError('Failed to load zones');
    } finally {
      setLoading(false);
    }
  };

  const getOccupancyColor = (rate) => {
    if (rate >= 80) return 'var(--danger)';
    if (rate >= 60) return 'var(--warning)';
    if (rate >= 30) return 'var(--accent)';
    return 'var(--text-muted)';
  };

  if (loading) return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <div className="loading-center"><div className="spinner" /><span>Loading zones...</span></div>
      </main>
    </div>
  );

  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <div className="dashboard-header">
          <div>
            <h1>Manage Zones</h1>
            <p>Edit zone settings and manage pricing rules</p>
          </div>
          <button
            className="btn-primary"
            onClick={() => navigate('/add-zone')}
            style={{ display: 'flex', alignItems: 'center', gap: 8 }}
          >
            <Plus size={16} />
            Add New Zone
          </button>
        </div>

        {error && <div className="alert alert-error">⚠️ {error}</div>}

        {zones.length === 0 ? (
          <div className="glass-card" style={{ padding: 40, textAlign: 'center' }}>
            <MapPin size={48} color="var(--text-muted)" style={{ marginBottom: 16 }} />
            <h3 style={{ color: 'var(--text-muted)', marginBottom: 8 }}>No zones yet</h3>
            <p style={{ color: 'var(--text-muted)', marginBottom: 20 }}>
              Create your first parking zone to get started.
            </p>
            <button className="btn-primary" onClick={() => navigate('/add-zone')}>
              <Plus size={16} style={{ marginRight: 8 }} />
              Create First Zone
            </button>
          </div>
        ) : (
          <div style={{ display: 'grid', gap: 20 }}>
            {zones.map(zone => (
              <div key={zone.id} className="glass-card" style={{ padding: 24 }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
                  <div>
                    <h3 style={{ margin: 0, fontSize: 18, fontWeight: 700, display: 'flex', alignItems: 'center', gap: 8 }}>
                      <MapPin size={20} color="var(--accent)" />
                      {zone.name}
                      {zone.code && <span style={{ fontSize: 14, color: 'var(--text-muted)', fontWeight: 400 }}>({zone.code})</span>}
                    </h3>
                    <p style={{ margin: '4px 0 0 0', color: 'var(--text-muted)', fontSize: 14 }}>
                      {zone.description || 'No description'}
                    </p>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    <span className={`badge ${zone.is_active ? 'badge-approved' : 'badge-pending'}`}>
                      {zone.is_active ? 'Active' : 'Inactive'}
                    </span>

                    <div style={{ display: 'flex', gap: 8 }}>
                      <button
                        className="btn-secondary"
                        onClick={() => navigate(`/zones/${zone.id}/edit`)}
                        style={{ padding: '8px 16px', fontSize: 14, display: 'flex', alignItems: 'center', gap: 6 }}
                      >
                        <Edit size={16} />
                        Edit
                      </button>
                      <button
                        className="btn-primary"
                        onClick={() => navigate(`/zones/${zone.id}/pricing-rules`)}
                        style={{ padding: '8px 16px', fontSize: 14, display: 'flex', alignItems: 'center', gap: 6 }}
                      >
                        <DollarSign size={16} />
                        Pricing
                      </button>
                    </div>
                  </div>
                </div>

                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: 20 }}>
                  <div style={{ textAlign: 'center' }}>
                    <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--success)' }}>
                      {zone.hourly_rate}
                    </div>
                    <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>Base Rate</div>
                  </div>

                  <div style={{ textAlign: 'center' }}>
                    <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--accent)' }}>
                      {zone.total_slots}
                    </div>
                    <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>Total Slots</div>
                  </div>

                  <div style={{ textAlign: 'center' }}>
                    <div style={{ fontSize: 24, fontWeight: 700, color: getOccupancyColor(zone.occupancy_rate) }}>
                      {zone.occupancy_rate.toFixed(1)}%
                    </div>
                    <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>Occupancy</div>
                  </div>

                  <div style={{ textAlign: 'center' }}>
                    <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--warning)' }}>
                      {zone.active_sessions_count}
                    </div>
                    <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>Active Sessions</div>
                  </div>

                  <div style={{ textAlign: 'center' }}>
                    <div style={{ fontSize: 24, fontWeight: 700, color: 'var(--text-secondary)' }}>
                      {zone.active_pricing_rules_count || 0}
                    </div>
                    <div style={{ fontSize: 12, color: 'var(--text-muted)' }}>Pricing Rules</div>
                  </div>
                </div>

                <div style={{ marginTop: 16, paddingTop: 16, borderTop: '1px solid var(--border)', display: 'flex', gap: 16 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <Settings size={14} color="var(--text-muted)" />
                    <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>
                      Dynamic Pricing: {zone.supports_dynamic_pricing ? 'Enabled' : 'Disabled'}
                    </span>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <TrendingUp size={14} color="var(--text-muted)" />
                    <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>
                      Reservations: {zone.supports_reservations ? 'Enabled' : 'Disabled'}
                    </span>
                  </div>

                  <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <Users size={14} color="var(--text-muted)" />
                    <span style={{ fontSize: 12, color: 'var(--text-muted)' }}>
                      Commission: {zone.commission_rate}%
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
}