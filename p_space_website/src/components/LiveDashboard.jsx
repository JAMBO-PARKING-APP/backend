import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { motion, AnimatePresence } from 'framer-motion';
import { MapPin, Info, RefreshCw } from 'lucide-react';

const LiveDashboard = () => {
  const [zones, setZones] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchZones = async () => {
    setLoading(true);
    try {
      const response = await axios.get('https://backend.p-space.ai/api/parking/zones/');
      // Handling potential DRF pagination or direct list
      const data = response.data.results || response.data;
      setZones(data.slice(0, 6)); // Show top 6
      setError(null);
    } catch (err) {
      console.error("Error fetching zones:", err);
      // Mock data if backend is unreachable during dev
      setZones([
        { id: '1', name: 'City Center Alpha', available_slots: 12, total_slots: 50, hourly_rate: 2000 },
        { id: '2', name: 'Industrial Area B', available_slots: 5, total_slots: 30, hourly_rate: 1500 },
        { id: '3', name: 'Business District Z', available_slots: 0, total_slots: 40, hourly_rate: 3000 },
      ]);
      setError("Note: Showing demo data while backend syncs.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchZones();
    const interval = setInterval(fetchZones, 30000); // Pulse every 30s
    return () => clearInterval(interval);
  }, []);

  return (
    <section id="real-time-map" className="section-padding bg-surface">
      <div className="container">
        <div className="flex flex-col md:flex-row justify-between items-end mb-12 gap-6">
          <div className="max-w-xl">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/10 text-primary text-[10px] font-bold mb-4 uppercase tracking-tighter">
              <span className="w-2 h-2 rounded-full bg-primary animate-pulse" />
              LIVE DATA STREAM
            </div>
            <h2 className="text-4xl font-extrabold text-text mb-4">Real-time Zone Status</h2>
            <p className="text-text-muted">
              Access live occupancy data directly from our municipal backend. See what's available before you arrive.
            </p>
          </div>
          <button 
            onClick={fetchZones}
            disabled={loading}
            className="btn bg-white border border-gray-200 flex items-center gap-2 text-sm"
          >
            <RefreshCw size={16} className={loading ? 'animate-spin' : ''} />
            REFRESH FEED
          </button>
        </div>

        {error && (
          <div className="mb-8 p-4 bg-accent/10 border border-accent/20 rounded-2xl flex items-center gap-3 text-accent text-sm font-medium">
            <Info size={18} />
            {error}
          </div>
        )}

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          <AnimatePresence mode='popLayout'>
            {zones.map((zone) => (
              <motion.div
                key={zone.id}
                layout
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                exit={{ opacity: 0, scale: 0.9 }}
                className="glass-morphism bg-white/50 p-6 rounded-[32px] border border-white hover:shadow-lg transition-all"
              >
                <div className="flex justify-between items-start mb-6">
                  <div className="p-3 rounded-2xl bg-primary/10 text-primary">
                    <MapPin size={24} />
                  </div>
                  <div className={`px-3 py-1 rounded-full text-[10px] font-bold uppercase tracking-wider ${
                    zone.available_slots > 0 ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                  }`}>
                    {zone.available_slots > 0 ? 'AVAILABLE' : 'FULL'}
                  </div>
                </div>
                
                <h3 className="text-lg font-bold text-text mb-1">{zone.name}</h3>
                <div className="text-2xl font-black text-primary mb-4">
                  {zone.available_slots} <span className="text-sm font-medium text-text-muted">/ {zone.total_slots} slots</span>
                </div>

                <div className="w-full bg-gray-100 h-2 rounded-full overflow-hidden mb-4">
                  <motion.div 
                    initial={{ width: 0 }}
                    animate={{ width: `${(zone.available_slots / zone.total_slots) * 100}%` }}
                    className="h-full bg-primary"
                  />
                </div>

                <div className="flex justify-between items-center text-xs font-bold text-text-muted uppercase">
                  <span>Current Rate</span>
                  <span className="text-text">{zone.hourly_rate?.toLocaleString()} UGX/hr</span>
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      </div>
    </section>
  );
};

export default LiveDashboard;
