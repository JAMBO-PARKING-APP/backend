import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { submitZoneApplication } from '../utils/api';
import { isAuthenticated } from '../utils/auth';
import { MapPin, DollarSign, Send, CheckCircle2, ArrowLeft } from 'lucide-react';

const PartnerApplyPage = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    proposed_name: '',
    address: '',
    latitude: '0.347596', // Default Kampala approx
    longitude: '32.582520',
    total_slots: 10,
    proposed_hourly_rate: 1000,
    operating_hours: '24/7',
    parking_surface: 'paved',
    has_security: false,
    has_cctv: false,
    access_instructions: '',
  });
  const [loading, setLoading] = useState(false);
  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!isAuthenticated()) {
      navigate('/partner/login');
    }
  }, [navigate]);

  const handleChange = (e) => {
    const value = e.target.type === 'checkbox' ? e.target.checked : e.target.value;
    setFormData({ ...formData, [e.target.name]: value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    
    try {
      await submitZoneApplication({
        ...formData,
        total_slots: parseInt(formData.total_slots),
        proposed_hourly_rate: parseFloat(formData.proposed_hourly_rate)
      });
      setSubmitted(true);
    } catch (err) {
      setError(err.response?.data?.detail || err.response?.data?.error || 'Failed to submit application. Please check your inputs.');
    } finally {
      setLoading(false);
    }
  };

  if (submitted) {
    return (
      <div className="min-h-screen bg-surface flex flex-col pt-24 pb-12 px-4">
        <div className="max-w-md w-full mx-auto text-center glass-morphism p-10 rounded-3xl bg-white border border-gray-100 mt-10">
          <CheckCircle2 size={80} className="mx-auto mb-6 text-green-500" />
          <h2 className="text-3xl font-extrabold mb-4">Application Submitted!</h2>
          <p className="text-gray-600 mb-8">
            Thank you for applying to host your space on Space Park. Our team will review your application and be in touch soon.
          </p>
          <button 
            onClick={() => navigate('/partner/dashboard')}
            className="btn btn-primary font-bold w-full p-4"
          >
            RETURN TO DASHBOARD
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-surface pt-24 pb-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-2xl mx-auto glass-morphism p-10 rounded-[40px] bg-white border border-gray-100 shadow-xl">
        
        <button onClick={() => navigate('/partner/dashboard')} className="flex items-center text-text-muted hover:text-primary transition-colors mb-6 text-sm font-bold">
          <ArrowLeft size={16} className="mr-2" /> Back to Dashboard
        </button>

        <h2 className="text-3xl md:text-4xl font-extrabold text-text mb-2">Host a Space</h2>
        <p className="text-text-muted mb-8 text-lg">Tell us about the parking space you'd like to monetize.</p>

        {error && (
          <div className="bg-red-50 text-red-500 p-4 rounded-xl text-sm font-medium mb-6">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="flex flex-col gap-2">
            <label className="text-xs font-bold text-text-muted uppercase">Location Name</label>
            <input 
              required 
              type="text" 
              name="proposed_name"
              value={formData.proposed_name}
              onChange={handleChange}
              placeholder="e.g. Plot 10 Kampala Road" 
              className="w-full p-4 rounded-2xl bg-gray-50 border border-gray-100 focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all font-medium" 
            />
          </div>

          <div className="flex flex-col gap-2">
            <label className="text-xs font-bold text-text-muted uppercase">Street Address / Details</label>
            <div className="relative">
              <MapPin size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-text-muted" />
              <input 
                required 
                type="text" 
                name="address"
                value={formData.address}
                onChange={handleChange}
                placeholder="Full address of the parking zone" 
                className="w-full p-4 pl-12 rounded-2xl bg-gray-50 border border-gray-100 focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all font-medium" 
              />
            </div>
          </div>

          <div className="grid md:grid-cols-2 gap-6">
            <div className="flex flex-col gap-2">
              <label className="text-xs font-bold text-text-muted uppercase">Number of Slots</label>
              <input 
                required 
                type="number" 
                min="1"
                name="total_slots"
                value={formData.total_slots}
                onChange={handleChange}
                className="w-full p-4 rounded-2xl bg-gray-50 border border-gray-100 focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all font-bold" 
              />
            </div>
            
            <div className="flex flex-col gap-2">
              <label className="text-xs font-bold text-text-muted uppercase">Proposed Hourly Rate</label>
              <div className="relative">
                <DollarSign size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-text-muted" />
                <input 
                  required 
                  type="number" 
                  min="0"
                  step="0.01"
                  name="proposed_hourly_rate"
                  value={formData.proposed_hourly_rate}
                  onChange={handleChange}
                  className="w-full p-4 pl-12 rounded-2xl bg-gray-50 border border-gray-100 focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all font-bold" 
                />
              </div>
            </div>
          </div>

          <div className="grid md:grid-cols-2 gap-6">
            <div className="flex flex-col gap-2">
              <label className="text-xs font-bold text-text-muted uppercase">Operating Hours</label>
              <input 
                type="text" 
                name="operating_hours"
                value={formData.operating_hours}
                onChange={handleChange}
                placeholder="e.g. 24/7 or 8 AM - 6 PM"
                className="w-full p-4 rounded-2xl bg-gray-50 border border-gray-100 focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all font-medium" 
              />
            </div>
            <div className="flex flex-col gap-2">
              <label className="text-xs font-bold text-text-muted uppercase">Parking Surface</label>
              <select 
                name="parking_surface"
                value={formData.parking_surface}
                onChange={handleChange}
                className="w-full p-4 rounded-2xl bg-gray-50 border border-gray-100 focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all font-medium"
              >
                <option value="paved">Paved / Concrete</option>
                <option value="gravel">Gravel / Dirt</option>
                <option value="indoor">Indoor / Garage</option>
              </select>
            </div>
          </div>

          <div className="flex flex-col sm:flex-row gap-6">
            <label className="flex items-center gap-3 cursor-pointer p-4 rounded-2xl bg-gray-50 border border-gray-100 flex-1 hover:bg-gray-100 transition-colors">
              <input 
                type="checkbox" 
                name="has_security"
                checked={formData.has_security}
                onChange={handleChange}
                className="w-5 h-5 text-primary rounded border-gray-300 focus:ring-primary"
              />
              <span className="text-sm font-bold text-text">On-site Security Guard</span>
            </label>
            <label className="flex items-center gap-3 cursor-pointer p-4 rounded-2xl bg-gray-50 border border-gray-100 flex-1 hover:bg-gray-100 transition-colors">
              <input 
                type="checkbox" 
                name="has_cctv"
                checked={formData.has_cctv}
                onChange={handleChange}
                className="w-5 h-5 text-primary rounded border-gray-300 focus:ring-primary"
              />
              <span className="text-sm font-bold text-text">CCTV Coverage</span>
            </label>
          </div>

          <div className="flex flex-col gap-2">
            <label className="text-xs font-bold text-text-muted uppercase">Access Instructions</label>
            <textarea 
              name="access_instructions"
              value={formData.access_instructions}
              onChange={handleChange}
              rows="3"
              placeholder="Any specific directions on how drivers should find or enter the space?" 
              className="w-full p-4 rounded-2xl bg-gray-50 border border-gray-100 focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all font-medium resize-none" 
            />
          </div>
          
          <div className="text-xs text-text-muted bg-blue-50/50 p-4 rounded-xl border border-blue-100 mt-2">
            Coordinates (Latitude: {formData.latitude}, Longitude: {formData.longitude}) are set to default. An Admin will map the exact boundaries during the approval process.
          </div>

          <button 
            type="submit" 
            disabled={loading}
            className="btn btn-primary w-full py-5 flex items-center justify-center gap-3 text-lg mt-8"
          >
            <Send size={20} />
            {loading ? 'SUBMITTING...' : 'SUBMIT APPLICATION'}
          </button>
        </form>
      </div>
    </div>
  );
};

export default PartnerApplyPage;
