import { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { api } from '../AuthContext';
import Sidebar from '../components/Sidebar';
import { Save, MapPin, Settings, DollarSign, Clock, Users, Image as ImageIcon } from 'lucide-react';

export default function ZoneEditPage() {
  const { zoneId } = useParams();
  const navigate = useNavigate();
  const [zone, setZone] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  useEffect(() => {
    loadZone();
  }, [zoneId]);

  const loadZone = async () => {
    try {
      const res = await api.get(`/parking/owner/zones/${zoneId}/edit/`);
      setZone(res.data);
    } catch (err) {
      setError('Failed to load zone details');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    setSaving(true);
    setError('');
    setSuccess('');

    try {
      const res = await api.put(`/parking/owner/zones/${zoneId}/edit/`, zone);
      setZone(res.data);
      setSuccess('Zone updated successfully!');
      setTimeout(() => setSuccess(''), 3000);
    } catch (err) {
      setError('Failed to update zone');
    } finally {
      setSaving(false);
    }
  };

  const handleInputChange = (field, value) => {
    setZone(prev => ({ ...prev, [field]: value }));
  };

  if (loading) return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <div className="loading-center"><div className="spinner" /><span>Loading zone details...</span></div>
      </main>
    </div>
  );

  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <div className="dashboard-header">
          <div>
            <h1>Edit Zone</h1>
            <p>Manage settings for {zone?.name}</p>
          </div>
          <div style={{ display: 'flex', gap: 12 }}>
            <button
              className="btn-secondary"
              onClick={() => navigate('/dashboard')}
            >
              Back to Dashboard
            </button>
            <button
              className="btn-primary"
              onClick={handleSave}
              disabled={saving}
              style={{ display: 'flex', alignItems: 'center', gap: 8 }}
            >
              <Save size={16} />
              {saving ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </div>

        {error && <div className="alert alert-error">⚠️ {error}</div>}
        {success && <div className="alert alert-success">✅ {success}</div>}

        {zone && (
          <div style={{ display: 'grid', gap: 24 }}>
            {/* Basic Information */}
            <div className="glass-card" style={{ padding: 28 }}>
              <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 20, display: 'flex', alignItems: 'center', gap: 8 }}>
                <Settings size={20} color="var(--accent)" /> Basic Information
              </h2>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: 20 }}>
                <div>
                  <label style={{ display: 'block', marginBottom: 8, fontWeight: 600 }}>Zone Name</label>
                  <input
                    type="text"
                    value={zone.name || ''}
                    onChange={(e) => handleInputChange('name', e.target.value)}
                    className="form-input"
                    placeholder="Enter zone name"
                  />
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: 8, fontWeight: 600 }}>Zone Code</label>
                  <input
                    type="text"
                    value={zone.code || ''}
                    onChange={(e) => handleInputChange('code', e.target.value)}
                    className="form-input"
                    placeholder="e.g. JB01"
                  />
                </div>

                <div style={{ gridColumn: '1 / -1' }}>
                  <label style={{ display: 'block', marginBottom: 8, fontWeight: 600 }}>Description</label>
                  <textarea
                    value={zone.description || ''}
                    onChange={(e) => handleInputChange('description', e.target.value)}
                    className="form-input"
                    rows={3}
                    placeholder="Describe your parking zone"
                  />
                </div>
              </div>
            </div>

            {/* Pricing Settings */}
            <div className="glass-card" style={{ padding: 28 }}>
              <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 20, display: 'flex', alignItems: 'center', gap: 8 }}>
                <DollarSign size={20} color="var(--success)" /> Pricing Settings
              </h2>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: 20 }}>
                <div>
                  <label style={{ display: 'block', marginBottom: 8, fontWeight: 600 }}>Base Hourly Rate</label>
                  <input
                    type="number"
                    step="0.01"
                    value={zone.hourly_rate || ''}
                    onChange={(e) => handleInputChange('hourly_rate', parseFloat(e.target.value) || 0)}
                    className="form-input"
                    placeholder="0.00"
                  />
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: 8, fontWeight: 600 }}>Max Duration (hours)</label>
                  <input
                    type="number"
                    value={zone.max_duration_hours || ''}
                    onChange={(e) => handleInputChange('max_duration_hours', parseInt(e.target.value) || 24)}
                    className="form-input"
                    placeholder="24"
                  />
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: 8, fontWeight: 600 }}>Commission Rate (%)</label>
                  <input
                    type="number"
                    step="0.01"
                    value={zone.commission_rate || ''}
                    onChange={(e) => handleInputChange('commission_rate', parseFloat(e.target.value) || 10)}
                    className="form-input"
                    placeholder="10.00"
                  />
                </div>
              </div>

              <div style={{ marginTop: 20 }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={zone.supports_dynamic_pricing || false}
                    onChange={(e) => handleInputChange('supports_dynamic_pricing', e.target.checked)}
                  />
                  <span style={{ fontWeight: 600 }}>Enable Dynamic Pricing</span>
                </label>
                <p style={{ margin: '8px 0 0 24px', fontSize: 14, color: 'var(--text-muted)' }}>
                  Allow automatic price adjustments based on time, demand, or special events
                </p>
              </div>

              <div style={{ marginTop: 16 }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer' }}>
                  <input
                    type="checkbox"
                    checked={zone.supports_reservations || false}
                    onChange={(e) => handleInputChange('supports_reservations', e.target.checked)}
                  />
                  <span style={{ fontWeight: 600 }}>Enable Reservations</span>
                </label>
                <p style={{ margin: '8px 0 0 24px', fontSize: 14, color: 'var(--text-muted)' }}>
                  Allow users to reserve parking spots in advance
                </p>
              </div>
            </div>

            {/* Capacity & Location */}
            <div className="glass-card" style={{ padding: 28 }}>
              <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 20, display: 'flex', alignItems: 'center', gap: 8 }}>
                <MapPin size={20} color="var(--warning)" /> Capacity & Location
              </h2>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 20 }}>
                <div>
                  <label style={{ display: 'block', marginBottom: 8, fontWeight: 600 }}>Total Slots</label>
                  <input
                    type="number"
                    value={zone.total_slots || ''}
                    onChange={(e) => handleInputChange('total_slots', parseInt(e.target.value) || 0)}
                    className="form-input"
                    placeholder="0"
                  />
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: 8, fontWeight: 600 }}>Latitude</label>
                  <input
                    type="number"
                    step="0.000001"
                    value={zone.latitude || ''}
                    onChange={(e) => handleInputChange('latitude', parseFloat(e.target.value) || 0)}
                    className="form-input"
                    placeholder="0.000000"
                  />
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: 8, fontWeight: 600 }}>Longitude</label>
                  <input
                    type="number"
                    step="0.000001"
                    value={zone.longitude || ''}
                    onChange={(e) => handleInputChange('longitude', parseFloat(e.target.value) || 0)}
                    className="form-input"
                    placeholder="0.000000"
                  />
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: 8, fontWeight: 600 }}>Radius (meters)</label>
                  <input
                    type="number"
                    value={zone.radius_meters || ''}
                    onChange={(e) => handleInputChange('radius_meters', parseInt(e.target.value) || 100)}
                    className="form-input"
                    placeholder="100"
                  />
                </div>
              </div>
            </div>

            {/* Images & Diagrams */}
            <div className="glass-card" style={{ padding: 28 }}>
              <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 20, display: 'flex', alignItems: 'center', gap: 8 }}>
                <ImageIcon size={20} color="var(--text-secondary)" /> Images & Diagrams
              </h2>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: 20 }}>
                <div>
                  <label style={{ display: 'block', marginBottom: 8, fontWeight: 600 }}>Zone Photo URL</label>
                  <input
                    type="url"
                    value={zone.zone_image || ''}
                    onChange={(e) => handleInputChange('zone_image', e.target.value)}
                    className="form-input"
                    placeholder="https://example.com/zone-photo.jpg"
                  />
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: 8, fontWeight: 600 }}>Layout Diagram URL</label>
                  <input
                    type="url"
                    value={zone.diagram_image || ''}
                    onChange={(e) => handleInputChange('diagram_image', e.target.value)}
                    className="form-input"
                    placeholder="https://example.com/layout-diagram.jpg"
                  />
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: 8, fontWeight: 600 }}>Diagram Width (px)</label>
                  <input
                    type="number"
                    value={zone.diagram_width || ''}
                    onChange={(e) => handleInputChange('diagram_width', parseInt(e.target.value) || 800)}
                    className="form-input"
                    placeholder="800"
                  />
                </div>

                <div>
                  <label style={{ display: 'block', marginBottom: 8, fontWeight: 600 }}>Diagram Height (px)</label>
                  <input
                    type="number"
                    value={zone.diagram_height || ''}
                    onChange={(e) => handleInputChange('diagram_height', parseInt(e.target.value) || 600)}
                    className="form-input"
                    placeholder="600"
                  />
                </div>
              </div>
            </div>

            {/* Status & Analytics */}
            <div className="glass-card" style={{ padding: 28 }}>
              <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 20, display: 'flex', alignItems: 'center', gap: 8 }}>
                <Users size={20} color="var(--accent-light)" /> Status & Analytics
              </h2>

              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 20 }}>
                <div>
                  <label style={{ display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer' }}>
                    <input
                      type="checkbox"
                      checked={zone.is_active || false}
                      onChange={(e) => handleInputChange('is_active', e.target.checked)}
                    />
                    <span style={{ fontWeight: 600 }}>Zone is Active</span>
                  </label>
                  <p style={{ margin: '8px 0 0 24px', fontSize: 14, color: 'var(--text-muted)' }}>
                    Inactive zones won't be visible to users
                  </p>
                </div>

                <div style={{ textAlign: 'center', padding: 20, background: 'rgba(255, 255, 255, 0.02)', borderRadius: 'var(--radius-md)' }}>
                  <div style={{ fontSize: 32, fontWeight: 700, color: 'var(--accent)' }}>
                    {zone.current_occupancy_rate?.toFixed(1) || 0}%
                  </div>
                  <div style={{ fontSize: 14, color: 'var(--text-muted)' }}>Current Occupancy</div>
                </div>

                <div style={{ textAlign: 'center', padding: 20, background: 'rgba(255, 255, 255, 0.02)', borderRadius: 'var(--radius-md)' }}>
                  <div style={{ fontSize: 32, fontWeight: 700, color: 'var(--success)' }}>
                    {zone.active_pricing_rules_count || 0}
                  </div>
                  <div style={{ fontSize: 14, color: 'var(--text-muted)' }}>Active Pricing Rules</div>
                </div>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}