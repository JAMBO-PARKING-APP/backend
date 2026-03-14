import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { fetchOwnerZones, updateOwnerZone } from '../utils/api';
import { isAuthenticated, logout, getUser } from '../utils/auth';
import { LogOut, MapPin, Edit3, Save, TrendingUp } from 'lucide-react';

const PartnerDashboard = () => {
  const [zones, setZones] = useState([]);
  const [loading, setLoading] = useState(true);
  const [editingId, setEditingId] = useState(null);
  const [editRate, setEditRate] = useState('');
  const navigate = useNavigate();
  const user = getUser();

  useEffect(() => {
    if (!isAuthenticated()) {
      navigate('/partner/login');
      return;
    }
    loadZones();
  }, [navigate]);

  const loadZones = async () => {
    try {
      const data = await fetchOwnerZones();
      setZones(data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  const handleEditClick = (zone) => {
    setEditingId(zone.id);
    setEditRate(zone.hourly_rate);
  };

  const handleSaveRate = async (id) => {
    try {
      await updateOwnerZone(id, { hourly_rate: editRate });
      setEditingId(null);
      loadZones();
    } catch (err) {
      console.error('Failed to update rate', err);
    }
  };

  if (loading) {
    return <div className="min-h-screen flex items-center justify-center bg-surface">Loading Dashboard...</div>;
  }

  return (
    <div className="min-h-screen bg-surface pt-24 pb-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-6xl mx-auto">
        
        {/* Header section */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center mb-10 gap-4">
          <div>
            <h1 className="text-3xl font-extrabold text-text">Partner Dashboard</h1>
            <p className="text-text-muted mt-1">Welcome back, {user?.first_name || 'Partner'}</p>
          </div>
          <div className="flex gap-4">
            <button 
              onClick={() => navigate('/partner/apply')}
              className="btn btn-primary"
            >
              + ADD NEW SPACE
            </button>
            <button 
              onClick={handleLogout}
              className="btn bg-red-50 text-red-600 hover:bg-red-100 flex items-center gap-2"
            >
              <LogOut size={18} /> Logout
            </button>
          </div>
        </div>

        {/* Stats / Zones section */}
        <div className="grid lg:grid-cols-3 gap-8">
          
          <div className="lg:col-span-2 space-y-6">
            <h3 className="text-xl font-bold border-b pb-2">Your Approved Zones</h3>
            
            {zones.length === 0 ? (
              <div className="glass-morphism p-8 text-center rounded-3xl border border-gray-100 bg-white">
                <MapPin className="mx-auto text-gray-300 mb-4" size={48} />
                <h4 className="font-bold text-lg mb-2">No Active Zones</h4>
                <p className="text-text-muted mb-6">You don't have any approved parking spaces currently active on the platform.</p>
                <button onClick={() => navigate('/partner/apply')} className="btn btn-primary text-sm">
                  Apply to Host a Space
                </button>
              </div>
            ) : (
              zones.map(zone => (
                <div key={zone.id} className="glass-morphism bg-white p-6 rounded-3xl border border-gray-100 flex flex-col md:flex-row justify-between items-start md:items-center gap-6 shadow-sm">
                  
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <h4 className="font-bold text-lg">{zone.name}</h4>
                      <span className="px-2 py-1 text-xs font-bold rounded-md bg-green-100 text-green-700">ACTIVE</span>
                    </div>
                    <p className="text-text-muted text-sm line-clamp-2">{zone.description || 'No description provided.'}</p>
                    
                    <div className="flex gap-6 mt-4 opacity-80 text-sm font-medium">
                      <div>Slots: <span className="text-primary font-bold">{zone.available_slots_count} / {zone.total_slots}</span> available</div>
                      <div>Commission Rate: <span className="font-bold">{zone.commission_rate}%</span></div>
                    </div>
                  </div>

                  <div className="bg-gray-50 p-4 rounded-2xl w-full md:w-auto shrink-0 md:min-w-[150px]">
                    <p className="text-xs font-bold text-text-muted uppercase mb-1">Hourly Rate</p>
                    {editingId === zone.id ? (
                      <div className="flex items-center gap-2">
                        <input 
                          type="number" 
                          step="0.01"
                          value={editRate} 
                          onChange={(e) => setEditRate(e.target.value)}
                          className="w-24 p-2 rounded-lg border border-gray-200 text-sm font-bold"
                        />
                        <button onClick={() => handleSaveRate(zone.id)} className="text-green-600 hover:text-green-800 p-1">
                          <Save size={18} />
                        </button>
                      </div>
                    ) : (
                      <div className="flex items-center justify-between">
                        <span className="text-xl font-extrabold text-primary">{zone.hourly_rate}</span>
                        <button onClick={() => handleEditClick(zone)} className="text-gray-400 hover:text-primary transition-colors p-1">
                          <Edit3 size={16} />
                        </button>
                      </div>
                    )}
                  </div>
                  
                </div>
              ))
            )}
          </div>

          <div className="space-y-6">
            <h3 className="text-xl font-bold border-b pb-2">Analytics Summary</h3>
            <div className="glass-morphism bg-white p-6 rounded-3xl border border-gray-100 shadow-sm">
              <div className="flex items-center gap-4 mb-6">
                <div className="w-12 h-12 rounded-xl bg-green-50 text-green-600 flex items-center justify-center">
                  <TrendingUp size={24} />
                </div>
                <div>
                  <p className="text-sm font-bold text-text-muted uppercase">Total Active Sessions</p>
                  <h4 className="text-2xl font-extrabold">{zones.reduce((acc, z) => acc + (z.active_sessions_count || 0), 0)}</h4>
                </div>
              </div>
              
              <div className="pt-6 border-t border-gray-100">
                <p className="text-sm text-text-muted">
                  Wallet balance and historical earnings can be viewed on the Driver/Partner Mobile Application under the "Wallet" tab.
                </p>
              </div>
            </div>
          </div>
          
        </div>
      </div>
    </div>
  );
};

export default PartnerDashboard;
