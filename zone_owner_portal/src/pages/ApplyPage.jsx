import { useState, useRef } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { MapContainer, TileLayer, Marker, useMapEvents } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { api } from '../AuthContext';
import { AlertTriangle, CheckCircle2 } from 'lucide-react';

// Fix default marker icon
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

const STEPS = ['Personal Info', 'Zone Details', 'Pin Location', 'Documents & Submit'];

function MapPicker({ onLocationSelect, selectedPos }) {
  useMapEvents({
    click(e) { onLocationSelect(e.latlng); }
  });
  return selectedPos ? <Marker position={selectedPos} /> : null;
}

export default function ApplyPage() {
  const navigate = useNavigate();
  const [step, setStep] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [selectedPos, setSelectedPos] = useState(null);
  const fileRef = useRef();

  const [form, setForm] = useState({
    applicant_name: '', applicant_email: '', applicant_phone: '',
    proposed_name: '', address: '', total_slots: 1, proposed_hourly_rate: '',
    operating_hours: '24/7', parking_surface: 'paved',
    has_security: false, has_cctv: false, access_instructions: '',
    latitude: '', longitude: '', documents: null,
  });

  const set = (k, v) => setForm(f => ({ ...f, [k]: v }));

  const handleNext = () => {
    setError('');
    if (step === 0) {
      if (!form.applicant_name || !form.applicant_email || !form.applicant_phone) {
        setError('Please fill in all personal details.'); return;
      }
    }
    if (step === 1) {
      if (!form.proposed_name || !form.address || !form.proposed_hourly_rate) {
        setError('Please fill in all zone details.'); return;
      }
    }
    if (step === 2) {
      if (!form.latitude || !form.longitude) {
        setError('Please click on the map to pin your zone location.'); return;
      }
    }
    setStep(s => s + 1);
  };

  const handleSubmit = async () => {
    setLoading(true); setError('');
    try {
      const fd = new FormData();
      Object.entries(form).forEach(([k, v]) => {
        if (k === 'documents') { if (v) fd.append(k, v); }
        else fd.append(k, v);
      });
      const res = await api.post('/apply/', fd, {
        headers: { 'Content-Type': 'multipart/form-data' }
      });
      navigate('/apply/success', { state: { applicationId: res.data.application_id } });
    } catch (e) {
      const msg = e.response?.data;
      if (typeof msg === 'object') {
        setError(Object.values(msg).flat().join(', '));
      } else {
        setError('Submission failed. Please try again.');
      }
    } finally { setLoading(false); }
  };

  return (
    <>
      <nav className="navbar">
        <Link to="/" className="navbar-logo">
          <img src="/logo.png" alt="Space Park" style={{ height: 36, objectFit: 'contain' }} />
          <span>Space Park</span>
        </Link>
        <Link to="/" className="btn-secondary" style={{ padding: '8px 20px', fontSize: 13 }}>← Back to Home</Link>
      </nav>

      <div className="apply-page">
        <div className="apply-container">
          <div className="apply-header">
            <h1>Apply to List Your Space</h1>
            <p>Complete the form below to get your parking zone on Jambo Parking</p>
          </div>

          {/* Stepper */}
          <div className="stepper">
            {STEPS.map((label, i) => (
              <div key={i} className="step-item">
                <div className={`step-circle ${i < step ? 'done' : i === step ? 'active' : ''}`}>
                  {i < step ? '✓' : i + 1}
                </div>
                <span className="step-label" style={{ color: i === step ? 'var(--text-primary)' : undefined }}>{label}</span>
                {i < STEPS.length - 1 && <div className={`step-line ${i < step ? 'done' : ''}`} />}
              </div>
            ))}
          </div>

          <div className="apply-form-card">
            {error && <div className="alert alert-error"><AlertTriangle size={18} /> {error}</div>}

            {/* Step 0 */}
            {step === 0 && (
              <div className="animate-in">
                <h2 style={{ marginBottom: 24, fontSize: 22, fontWeight: 700 }}>Your Personal Details</h2>
                <div className="form-group">
                  <label>Full Name</label>
                  <input className="form-input" placeholder="John Kamau" value={form.applicant_name} onChange={e => set('applicant_name', e.target.value)} />
                </div>
                <div className="form-group">
                  <label>Email Address</label>
                  <input className="form-input" type="email" placeholder="john@example.com" value={form.applicant_email} onChange={e => set('applicant_email', e.target.value)} />
                </div>
                <div className="form-group">
                  <label>Phone Number</label>
                  <input className="form-input" placeholder="+254712345678" value={form.applicant_phone} onChange={e => set('applicant_phone', e.target.value)} />
                </div>
              </div>
            )}

            {/* Step 1 */}
            {step === 1 && (
              <div className="animate-in">
                <h2 style={{ marginBottom: 24, fontSize: 22, fontWeight: 700 }}>Zone Details</h2>
                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 20px' }}>
                  <div className="form-group">
                    <label>Proposed Zone Name</label>
                    <input className="form-input" placeholder="Central Nairobi Parking" value={form.proposed_name} onChange={e => set('proposed_name', e.target.value)} />
                  </div>
                  <div className="form-group">
                    <label>Address</label>
                    <input className="form-input" placeholder="Kenyatta Ave, Nairobi" value={form.address} onChange={e => set('address', e.target.value)} />
                  </div>
                  <div className="form-group">
                    <label>Total Parking Slots</label>
                    <input className="form-input" type="number" min={1} value={form.total_slots} onChange={e => set('total_slots', parseInt(e.target.value) || 1)} />
                  </div>
                  <div className="form-group">
                    <label>Hourly Rate (Local Currency)</label>
                    <input className="form-input" type="number" min={0} placeholder="500" value={form.proposed_hourly_rate} onChange={e => set('proposed_hourly_rate', e.target.value)} />
                  </div>
                  <div className="form-group">
                    <label>Operating Hours</label>
                    <input className="form-input" placeholder="24/7 or 7AM - 9PM" value={form.operating_hours} onChange={e => set('operating_hours', e.target.value)} />
                  </div>
                  <div className="form-group">
                    <label>Surface Type</label>
                    <select className="form-select" value={form.parking_surface} onChange={e => set('parking_surface', e.target.value)}>
                      <option value="paved">Paved / Concrete</option>
                      <option value="gravel">Gravel / Dirt</option>
                      <option value="indoor">Indoor / Garage</option>
                    </select>
                  </div>
                </div>
                <div style={{ display: 'flex', gap: 24, margin: '8px 0 20px' }}>
                  <label className="form-checkbox">
                    <input type="checkbox" checked={form.has_security} onChange={e => set('has_security', e.target.checked)} />
                    <span>Security Guard on-site</span>
                  </label>
                  <label className="form-checkbox">
                    <input type="checkbox" checked={form.has_cctv} onChange={e => set('has_cctv', e.target.checked)} />
                    <span>CCTV Cameras installed</span>
                  </label>
                </div>
                <div className="form-group">
                  <label>Access Instructions (optional)</label>
                  <textarea className="form-textarea" placeholder="How should drivers find or enter the space?" value={form.access_instructions} onChange={e => set('access_instructions', e.target.value)} />
                </div>
              </div>
            )}

            {/* Step 2 — Map */}
            {step === 2 && (
              <div className="animate-in">
                <h2 style={{ marginBottom: 8, fontSize: 22, fontWeight: 700 }}>Pin Your Zone Location</h2>
                <p style={{ color: 'var(--text-secondary)', fontSize: 14, marginBottom: 20 }}>Click on the map to drop a pin exactly where your parking space is located.</p>
                {selectedPos && (
                  <div className="alert alert-success" style={{ marginBottom: 16 }}>
                    <CheckCircle2 size={18} /> Location pinned at {selectedPos.lat.toFixed(6)}, {selectedPos.lng.toFixed(6)}
                  </div>
                )}
                <div className="map-container">
                  <MapContainer center={[-1.286389, 36.817223]} zoom={13} style={{ height: '100%', width: '100%' }}>
                    <TileLayer
                      url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                      attribution='© <a href="https://openstreetmap.org">OpenStreetMap</a>'
                    />
                    <MapPicker
                      onLocationSelect={pos => {
                        setSelectedPos(pos);
                        set('latitude', pos.lat.toFixed(6));
                        set('longitude', pos.lng.toFixed(6));
                      }}
                      selectedPos={selectedPos}
                    />
                  </MapContainer>
                </div>
              </div>
            )}

            {/* Step 3 — Docs & Submit */}
            {step === 3 && (
              <div className="animate-in">
                <h2 style={{ marginBottom: 8, fontSize: 22, fontWeight: 700 }}>Review & Submit</h2>
                <p style={{ color: 'var(--text-secondary)', fontSize: 14, marginBottom: 24 }}>Optionally upload proof of ownership, then submit your application.</p>

                <div className="glass-card" style={{ padding: 20, marginBottom: 24 }}>
                  {[
                    ['Applicant', form.applicant_name],
                    ['Email', form.applicant_email],
                    ['Phone', form.applicant_phone],
                    ['Zone Name', form.proposed_name],
                    ['Address', form.address],
                    ['Slots', form.total_slots],
                    ['Hourly Rate', form.proposed_hourly_rate],
                    ['Hours', form.operating_hours],
                    ['Location', form.latitude ? `${form.latitude}, ${form.longitude}` : '—'],
                  ].map(([k, v]) => (
                    <div key={k} style={{ display: 'flex', justifyContent: 'space-between', padding: '8px 0', borderBottom: '1px solid var(--border)', fontSize: 14 }}>
                      <span style={{ color: 'var(--text-muted)' }}>{k}</span>
                      <span style={{ color: 'var(--text-primary)', fontWeight: 500 }}>{v}</span>
                    </div>
                  ))}
                </div>

                <div className="form-group">
                  <label>Proof of Ownership / ID (optional)</label>
                  <input type="file" ref={fileRef} style={{ color: 'var(--text-secondary)', fontSize: 14 }}
                    onChange={e => set('documents', e.target.files[0])} />
                </div>
              </div>
            )}

            <div className="apply-nav">
              {step > 0
                ? <button className="btn-secondary" onClick={() => { setError(''); setStep(s => s - 1); }}>← Back</button>
                : <div />
              }
              {step < STEPS.length - 1
                ? <button className="btn-primary" onClick={handleNext}><span>Next →</span></button>
                : <button className="btn-primary" onClick={handleSubmit} disabled={loading}>
                    <span>{loading ? 'Submitting...' : 'Submit Application'}</span>
                  </button>
              }
            </div>
          </div>
        </div>
      </div>
    </>
  );
}
