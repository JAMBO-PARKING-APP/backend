import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api } from '../AuthContext';
import Sidebar from '../components/Sidebar';
import { MapContainer, TileLayer, Marker, useMapEvents } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { PartyPopper, AlertTriangle } from 'lucide-react';

// Fix leaflet icon issue natively in React
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

function MapPicker({ position, setPosition }) {
  useMapEvents({
    click(e) {
      setPosition([e.latlng.lat, e.latlng.lng]);
    },
  });
  return position ? <Marker position={position} /> : null;
}

export default function AddZonePage() {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    proposed_name: '',
    address: '',
    total_slots: '',
    proposed_hourly_rate: '',
    operating_hours: '24/7',
    parking_surface: 'paved',
    has_security: false,
    has_cctv: false,
    access_instructions: '',
  });
  const [position, setPosition] = useState(null); // [lat, lng]
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  const handleApply = async (e) => {
    e.preventDefault();
    setError('');
    
    if (!position) {
      setError('Please select the zone location on the map.');
      return;
    }

    setLoading(true);
    const payload = {
      ...formData,
      latitude: position[0].toString(),
      longitude: position[1].toString(),
    };

    try {
      const res = await api.post('/zones/apply/', payload);
      setSuccessMsg(`Success! Your zone application (${res.data.application_id}) has been submitted and is pending approval.`);
      setFormData({
        proposed_name: '', address: '', total_slots: '', proposed_hourly_rate: '',
        operating_hours: '24/7', parking_surface: 'paved', has_security: false, has_cctv: false,
        access_instructions: '',
      });
      setPosition(null);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to submit application. Please check your inputs.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <div className="dashboard-header" style={{ marginBottom: 30 }}>
          <h1>Add New Zone</h1>
          <p>Submit a request to add another parking location under your account.</p>
        </div>

        <div className="glass-card" style={{ maxWidth: 800 }}>
          {successMsg ? (
            <div style={{ textAlign: 'center', padding: '40px 20px' }}>
              <div style={{ fontSize: 48, marginBottom: 16 }}><PartyPopper size={48} color="var(--success)" /></div>
              <h2 style={{ fontSize: 24, marginBottom: 16 }}>Zone Request Sent!</h2>
              <p style={{ color: 'var(--text-muted)', marginBottom: 24, lineHeight: 1.6 }}>{successMsg}</p>
              <button 
                className="btn-primary" 
                onClick={() => navigate('/dashboard')}
                style={{ width: 'auto', padding: '12px 32px' }}>
                Return to Dashboard
              </button>
            </div>
          ) : (
            <form onSubmit={handleApply}>
              {error && <div className="alert alert-error" style={{ marginBottom: 24 }}><AlertTriangle size={18} /> {error}</div>}
              
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
                <div className="form-group">
                  <label>Proposed Zone Name</label>
                  <input type="text" required placeholder="e.g. Downtown Plaza Express" 
                    value={formData.proposed_name} onChange={e => setFormData({...formData, proposed_name: e.target.value})} />
                </div>
                <div className="form-group">
                  <label>Physical Address</label>
                  <input type="text" required placeholder="Full street address"
                    value={formData.address} onChange={e => setFormData({...formData, address: e.target.value})} />
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
                <div className="form-group">
                  <label>Total Available Slots</label>
                  <input type="number" required min="1" placeholder="Number of spaces"
                    value={formData.total_slots} onChange={e => setFormData({...formData, total_slots: e.target.value})} />
                </div>
                <div className="form-group">
                  <label>Proposed Hourly Rate (KES/GHS)</label>
                  <input type="number" required step="0.01" min="0" placeholder="e.g. 150.00"
                    value={formData.proposed_hourly_rate} onChange={e => setFormData({...formData, proposed_hourly_rate: e.target.value})} />
                </div>
              </div>

              <div className="form-group" style={{ marginTop: 10 }}>
                <label>Pin Location on Map</label>
                <div style={{ fontSize: 13, color: 'var(--text-muted)', marginBottom: 12 }}>
                  Click anywhere on the map to accurately place your parking zone.
                </div>
                <div style={{ height: 300, width: '100%', borderRadius: 12, overflow: 'hidden', border: '1px solid var(--border)' }}>
                  <MapContainer center={[5.6037, -0.1870]} zoom={13} style={{ height: '100%', width: '100%' }}>
                    <TileLayer url="https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png" />
                    <MapPicker position={position} setPosition={setPosition} />
                  </MapContainer>
                </div>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20, marginTop: 24 }}>
                <div className="form-group">
                  <label>Parking Surface</label>
                  <select value={formData.parking_surface} onChange={e => setFormData({...formData, parking_surface: e.target.value})}>
                    <option value="paved">Paved</option>
                    <option value="gravel">Gravel</option>
                    <option value="dirt">Dirt</option>
                    <option value="grass">Grass</option>
                    <option value="covered">Covered / Indoor</option>
                  </select>
                </div>
                <div className="form-group">
                  <label>Operating Hours</label>
                  <input type="text" placeholder="e.g. 24/7 or 8AM - 6PM"
                    value={formData.operating_hours} onChange={e => setFormData({...formData, operating_hours: e.target.value})} />
                </div>
              </div>

              <div style={{ display: 'flex', gap: 24, marginTop: 16, marginBottom: 24 }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', fontSize: 14 }}>
                  <input type="checkbox" checked={formData.has_security} 
                    onChange={e => setFormData({...formData, has_security: e.target.checked})} />
                  On-site Security
                </label>
                <label style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer', fontSize: 14 }}>
                  <input type="checkbox" checked={formData.has_cctv} 
                    onChange={e => setFormData({...formData, has_cctv: e.target.checked})} />
                  CCTV Surveillance
                </label>
              </div>

              <button type="submit" className="btn-primary" disabled={loading} style={{ width: '100%', padding: '14px' }}>
                {loading ? 'Submitting Application...' : 'Submit Zone Request'}
              </button>
            </form>
          )}
        </div>
      </main>
    </div>
  );
}
