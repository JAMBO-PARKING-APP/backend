import { useEffect, useState } from 'react';
import { api } from '../AuthContext';
import Sidebar from '../components/Sidebar';
import {
  AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend
} from 'recharts';
import { Banknote, Calendar, Sun, CarFront, Map as MapIcon, TrendingUp, PieChart as PieChartIcon, Car } from 'lucide-react';

const COLORS = ['#6366f1', '#10b981', '#f59e0b', '#ec4899', '#8b5cf6', '#06b6d4'];

function StatCard({ label, value, sub, icon, iconColor }) {
  return (
    <div className="stat-card">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 12 }}>
        <span className="stat-label">{label}</span>
        <span style={{ color: iconColor || 'var(--text-secondary)' }}>{icon}</span>
      </div>
      <div className="stat-value">{value}</div>
      {sub && <div className="stat-sub">{sub}</div>}
    </div>
  );
}

const CustomTooltip = ({ active, payload, label }) => {
  if (active && payload?.length) {
    return (
      <div style={{ background: '#1e1e3a', border: '1px solid var(--border)', borderRadius: 10, padding: '10px 16px' }}>
        <p style={{ fontSize: 12, color: 'var(--text-muted)', marginBottom: 4 }}>{label}</p>
        <p style={{ color: 'var(--accent-light)', fontWeight: 700, fontSize: 16 }}>
          {Number(payload[0].value).toLocaleString()}
        </p>
      </div>
    );
  }
  return null;
};

export default function DashboardPage() {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    api.get('/dashboard/')
      .then(res => setData(res.data))
      .catch(() => setError('Failed to load dashboard. Please try again.'))
      .finally(() => setLoading(false));
  }, []);

  const fmt = (n) => Number(n || 0).toLocaleString(undefined, { minimumFractionDigits: 0, maximumFractionDigits: 0 });

  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="dashboard-main">
        <div className="dashboard-header">
          <h1>Dashboard</h1>
          <p>Welcome back! Here's how your space is performing.</p>
        </div>

        {loading && <div className="loading-center"><div className="spinner" /><span>Loading your dashboard...</span></div>}
        {error && <div className="alert alert-error">⚠️ {error}</div>}

        {data && (
          <>
            {/* Stats */}
            <div className="stats-grid">
              <StatCard label="Total Earnings" value={fmt(data.summary.total_earnings)} sub="All time" icon={<Banknote size={24} />} iconColor="var(--success)" />
              <StatCard label="This Month" value={fmt(data.summary.month_earnings)} sub="Current month" icon={<Calendar size={24} />} iconColor="var(--accent-light)" />
              <StatCard label="Today" value={fmt(data.summary.today_earnings)} sub="Today's earnings" icon={<Sun size={24} />} iconColor="var(--warning)" />
              <StatCard label="Active Sessions" value={data.summary.active_sessions} sub={`${data.summary.today_sessions} today`} icon={<CarFront size={24} />} iconColor="var(--accent)" />
              <StatCard label="Reservations" value={data.summary.total_reservations} sub={`${data.summary.pending_reservations} pending`} icon={<Calendar size={24} />} iconColor="var(--accent-light)" />
            </div>

            {/* Charts section: Area Chart & Pie Chart */}
            <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: 24, marginBottom: 24 }} className="charts-grid">
              <div className="glass-card" style={{ padding: 28 }}>
                <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 20, display: 'flex', alignItems: 'center', gap: 8 }}>
                  <TrendingUp size={20} color="var(--success)" /> Earnings — Last 30 Days
                </h2>
                {data.earnings_chart.length === 0
                  ? <p style={{ color: 'var(--text-muted)', fontSize: 14, textAlign: 'center', padding: '40px 0' }}>No earnings data yet.</p>
                  : (
                    <ResponsiveContainer width="100%" height={260}>
                      <AreaChart data={data.earnings_chart} margin={{ top: 5, right: 10, left: 0, bottom: 0 }}>
                        <defs>
                          <linearGradient id="earningsGrad" x1="0" y1="0" x2="0" y2="1">
                            <stop offset="5%" stopColor="#6366f1" stopOpacity={0.3} />
                            <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
                          </linearGradient>
                        </defs>
                        <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" />
                        <XAxis dataKey="date" tick={{ fill: '#475569', fontSize: 11 }} tickLine={false} axisLine={false}
                          tickFormatter={d => new Date(d).toLocaleDateString('en-GB', { day: 'numeric', month: 'short' })} />
                        <YAxis tick={{ fill: '#475569', fontSize: 11 }} tickLine={false} axisLine={false}
                          tickFormatter={v => v.toLocaleString()} />
                        <Tooltip content={<CustomTooltip />} cursor={{ stroke: 'rgba(99,102,241,0.3)', strokeWidth: 1 }} />
                        <Area type="monotone" dataKey="amount" stroke="#6366f1" strokeWidth={2.5}
                          fill="url(#earningsGrad)" dot={false} activeDot={{ r: 5, fill: '#818cf8' }} />
                      </AreaChart>
                    </ResponsiveContainer>
                  )
                }
              </div>

              {data.revenue_by_zone && data.revenue_by_zone.length > 0 && (
                <div className="glass-card" style={{ padding: 28 }}>
                  <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 20, display: 'flex', alignItems: 'center', gap: 8 }}>
                    <PieChartIcon size={20} color="var(--warning)" /> Revenue Split by Zone
                  </h2>
                  <ResponsiveContainer width="100%" height={260}>
                    <PieChart>
                      <Pie
                        data={data.revenue_by_zone}
                        dataKey="value"
                        nameKey="name"
                        cx="50%"
                        cy="50%"
                        innerRadius={60}
                        outerRadius={80}
                        paddingAngle={5}
                      >
                        {data.revenue_by_zone.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                        ))}
                      </Pie>
                      <Tooltip content={<CustomTooltip />} />
                      <Legend verticalAlign="bottom" height={36} iconType="circle" />
                    </PieChart>
                  </ResponsiveContainer>
                </div>
              )}
            </div>

            {/* Zones table */}
            {data.zones.length > 0 && (
              <div className="glass-card" style={{ padding: 28, marginBottom: 24 }}>
                <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 20, display: 'flex', alignItems: 'center', gap: 8 }}>
                  <MapIcon size={20} color="var(--accent-light)" /> Your Zones
                </h2>
                <div className="table-wrapper">
                  <table>
                    <thead>
                      <tr>
                        <th>Zone</th><th>Slots</th><th>Hourly Rate</th>
                        <th>Active Sessions</th><th>Occupancy</th><th>Reservations</th><th>Pricing</th>
                      </tr>
                    </thead>
                    <tbody>
                      {data.zones.map(z => (
                        <tr key={z.id}>
                          <td style={{ fontWeight: 600, color: 'var(--text-primary)' }}>{z.name}</td>
                          <td>{z.total_slots}</td>
                          <td>{fmt(z.hourly_rate)}</td>
                          <td><span className="badge badge-active">{z.active_sessions}</span></td>
                          <td>
                            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                              <div style={{ flex: 1, height: 6, background: 'rgba(255,255,255,0.08)', borderRadius: 3 }}>
                                <div style={{ width: `${z.occupancy_rate}%`, height: '100%', borderRadius: 3, background: 'linear-gradient(90deg,var(--accent),#8b5cf6)' }} />
                              </div>
                              <span style={{ fontSize: 12, color: 'var(--text-muted)', minWidth: 36 }}>{z.occupancy_rate}%</span>
                            </div>
                          </td>
                          <td style={{ textAlign: 'center' }}>
                             <span className={`badge ${z.supports_reservations ? 'badge-approved' : 'badge-pending'}`} style={{ opacity: z.supports_reservations ? 1 : 0.4 }}>
                               {z.supports_reservations ? 'Yes' : 'No'}
                             </span>
                          </td>
                          <td style={{ textAlign: 'center' }}>
                             <span className={`badge ${z.supports_pricing ? 'badge-approved' : 'badge-pending'}`} style={{ opacity: z.supports_pricing ? 1 : 0.4 }}>
                               {z.supports_pricing ? 'Yes' : 'No'}
                             </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* Recent sessions */}
            <div className="glass-card" style={{ padding: 28 }}>
              <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 20, display: 'flex', alignItems: 'center', gap: 8 }}>
                <Car size={20} color="var(--text-secondary)" /> Recent Sessions
              </h2>
              {data.recent_sessions.length === 0
                ? <p style={{ color: 'var(--text-muted)', fontSize: 14, textAlign: 'center', padding: '40px 0' }}>No sessions yet.</p>
                : (
                  <div className="table-wrapper">
                    <table>
                      <thead><tr><th>Vehicle</th><th>Zone</th><th>Start Time</th><th>Status</th><th>Amount</th></tr></thead>
                      <tbody>
                        {data.recent_sessions.map(s => (
                          <tr key={s.id}>
                            <td style={{ fontFamily: 'monospace', letterSpacing: '0.05em' }}>
                              {s.vehicle} {s.is_guest && <span style={{ fontSize: 9, opacity: 0.6, background: '#475569', padding: '1px 4px', borderRadius: 3, verticalAlign: 'middle', marginLeft: 4 }}>GUEST</span>}
                            </td>
                            <td>{s.zone}</td>
                            <td style={{ fontSize: 13, color: 'var(--text-muted)' }}>
                              {new Date(s.start_time).toLocaleString('en-GB', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}
                            </td>
                            <td>
                              <span className={`badge ${s.status === 'active' ? 'badge-active' : s.status === 'completed' ? 'badge-approved' : 'badge-pending'}`}>
                                {s.status}
                              </span>
                            </td>
                            <td style={{ fontWeight: 600, color: 'var(--text-primary)' }}>{fmt(s.final_cost)}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )
              }
            </div>

            {/* Recent Reservations */}
            <div className="glass-card" style={{ padding: 28, marginTop: 24 }}>
              <h2 style={{ fontSize: 18, fontWeight: 700, marginBottom: 20, display: 'flex', alignItems: 'center', gap: 8 }}>
                <Calendar size={20} color="var(--accent-light)" /> Recent Reservations
              </h2>
              {data.recent_reservations.length === 0
                ? <p style={{ color: 'var(--text-muted)', fontSize: 14, textAlign: 'center', padding: '40px 0' }}>No reservations yet.</p>
                : (
                  <div className="table-wrapper">
                    <table>
                      <thead><tr><th>User</th><th>Zone</th><th>Planned Start</th><th>Status</th><th>Fee Deducted</th></tr></thead>
                      <tbody>
                        {data.recent_reservations.map(r => (
                          <tr key={r.id}>
                            <td style={{ fontWeight: 600 }}>{r.user}</td>
                            <td>{r.zone}</td>
                            <td style={{ fontSize: 13, color: 'var(--text-muted)' }}>
                              {new Date(r.start_time).toLocaleString('en-GB', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}
                            </td>
                            <td>
                              <span className={`badge ${r.status === 'pending' ? 'badge-warning' : r.status === 'active' ? 'badge-active' : 'badge-approved'}`}>
                                {r.status}
                              </span>
                            </td>
                            <td style={{ fontWeight: 600, color: 'var(--success)' }}>{fmt(r.service_fee)}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )
              }
            </div>
          </>
        )}
      </main>
    </div>
  );
}
