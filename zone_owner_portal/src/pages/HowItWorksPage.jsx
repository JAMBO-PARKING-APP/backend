import { Link } from 'react-router-dom';
import { FileText, Hourglass, CheckCircle2, Landmark, BarChart3, Banknote } from 'lucide-react';

function StepCard({ num, icon, title, desc }) {
  return (
    <div className="glass-card" style={{ padding: 32, display: 'flex', gap: 24, alignItems: 'flex-start' }}>
      <div style={{ width: 56, height: 56, borderRadius: 'var(--radius-lg)', background: 'linear-gradient(135deg,var(--accent),#8b5cf6)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24, flexShrink: 0, color: '#fff' }}>{icon}</div>
      <div>
        <div style={{ fontSize: 12, fontWeight: 700, color: 'var(--accent-light)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 6 }}>Step {num}</div>
        <h3 style={{ fontSize: 20, fontWeight: 700, marginBottom: 10 }}>{title}</h3>
        <p style={{ color: 'var(--text-secondary)', lineHeight: 1.8 }}>{desc}</p>
      </div>
    </div>
  );
}

export default function HowItWorksPage() {
  return (
    <>
      <nav className="navbar">
        <Link to="/" className="navbar-logo">
          <img src="/logo.png" alt="Space Park" style={{ height: 36, objectFit: 'contain' }} />
          <span>Space Park</span>
        </Link>
        <div className="navbar-links">
          <Link to="/apply">Apply Now</Link>
          <Link to="/login" style={{ color: 'var(--accent-light)', fontWeight: 600 }}>Partner Login</Link>
        </div>
      </nav>

      <div style={{ minHeight: '100vh', paddingTop: 80, background: 'radial-gradient(ellipse 70% 50% at 50% 0%, rgba(99,102,241,0.15) 0%, transparent 60%)' }}>
        <div style={{ maxWidth: 860, margin: '0 auto', padding: '60px 24px' }}>

          <div style={{ textAlign: 'center', marginBottom: 64 }}>
            <p className="section-eyebrow">Partner Programme</p>
            <h1 style={{ fontSize: 'clamp(32px,5vw,56px)', fontWeight: 900, marginBottom: 16 }}>How Space Park Works</h1>
            <p style={{ color: 'var(--text-secondary)', fontSize: 17, lineHeight: 1.8, maxWidth: 640, margin: '0 auto' }}>
              Space Park connects private parking space owners with drivers who need reliable parking. Here's exactly how the partner programme works from start to first payout.
            </p>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 20, marginBottom: 64 }}>
            <StepCard num={1} icon={<FileText size={24} />} title="Submit Your Application"
              desc="Fill out a quick form with your personal details and zone information — name, address, number of slots, and proposed hourly rate. Pin the exact location on the map. The whole process takes under 5 minutes." />
            <StepCard num={2} icon={<Hourglass size={24} />} title="Application Review"
              desc="Our verification team reviews your submission within 2–5 business days. We may contact you to confirm ownership details. You can check your status anytime using your Application ID." />
            <StepCard num={3} icon={<CheckCircle2 size={24} />} title="Get Approved & Go Live"
              desc="Once approved, your zone is automatically created on the Space Park platform and immediately visible to drivers on the mobile app. You'll receive an email with your login credentials for the Partner Portal." />
            <StepCard num={4} icon={<Landmark size={24} />} title="Set Up Your Payout Account"
              desc="On first login, enter your bank account details. This is where your earnings will be deposited automatically — no manual withdrawal needed." />
            <StepCard num={5} icon={<BarChart3 size={24} />} title="Monitor Your Earnings"
              desc="Use your Partner Dashboard to see real-time occupancy, session history, daily and monthly earnings, and zone performance stats with beautiful charts." />
            <StepCard num={6} icon={<Banknote size={24} />} title="Get Paid"
              desc="Earnings from every completed parking session are automatically calculated, our commission is deducted transparently, and the remainder is deposited to your bank account on a rolling basis." />
          </div>

          {/* FAQ */}
          <div className="glass-card" style={{ padding: 40, marginBottom: 40 }}>
            <h2 style={{ fontSize: 26, fontWeight: 800, marginBottom: 32 }}>Frequently Asked Questions</h2>
            {[
              ['How much does Space Park charge?', 'Space Park keeps a 10% commission on every parking session. You keep 90% of all earnings. The commission rate is clearly visible on your dashboard.'],
              ['When do I get paid?', 'Earnings are deposited to your bank account on a rolling basis — typically within 3–5 business days of a session completing.'],
              ['Can I set my own rates?', 'Yes! You propose your hourly rate during the application. Once approved, you can contact support to adjust your rate at any time.'],
              ['What if a driver damages my space?', 'Every session is logged with the vehicle details and timestamp. Our support team assists with dispute resolution.'],
              ['How does the mobile app work?', 'Drivers using the Space Park app can see your zone on a map, check real-time availability, and pay digitally — completely cashless.'],
              ['Can I pause my zone?', 'Yes — contact our support team or email support@spacepark.com to temporarily deactivate your zone without losing your account.'],
            ].map(([q, a]) => (
              <div key={q} style={{ borderBottom: '1px solid var(--border)', paddingBottom: 20, marginBottom: 20 }}>
                <h4 style={{ fontWeight: 700, marginBottom: 8 }}>{q}</h4>
                <p style={{ color: 'var(--text-secondary)', fontSize: 15, lineHeight: 1.7 }}>{a}</p>
              </div>
            ))}
          </div>

          <div style={{ textAlign: 'center' }}>
            <Link to="/apply" className="btn-primary" style={{ fontSize: 17, padding: '16px 40px' }}>
              <span>Apply to Become a Partner</span><span>→</span>
            </Link>
          </div>
        </div>
      </div>
    </>
  );
}
