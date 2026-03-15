import { Link } from 'react-router-dom';
import { Rocket, FileText, CheckCircle2, Banknote, BarChart3, Landmark, Map, ShieldCheck, Smartphone, Search, CreditCard, Timer, Bell } from 'lucide-react';

function FeatureCard({ icon, title, desc }) {
  return (
    <div className="glass-card" style={{ padding: '28px', display: 'flex', flexDirection: 'column', gap: '14px' }}>
      <div style={{ fontSize: 32 }}>{icon}</div>
      <h3 style={{ fontSize: 18, fontWeight: 700 }}>{title}</h3>
      <p style={{ color: 'var(--text-secondary)', fontSize: 14, lineHeight: 1.8 }}>{desc}</p>
    </div>
  );
}

function AppStoreBadge({ platform, imgSrc, href, height = 52 }) {
  return (
    <a href={href} target="_blank" rel="noopener noreferrer"
      style={{ display: 'inline-block', transition: 'opacity 0.2s', opacity: 1 }}
      onMouseEnter={e => e.currentTarget.style.opacity = 0.85}
      onMouseLeave={e => e.currentTarget.style.opacity = 1}>
      <img src={imgSrc} alt={platform} style={{ height, display: 'block' }} />
    </a>
  );
}

export default function LandingPage() {
  return (
    <>
      {/* Navbar */}
      <nav className="navbar">
        <Link to="/" className="navbar-logo">
          <img src="/logo.png" alt="Space Park" style={{ height: 38, objectFit: 'contain' }} />
          <span>Space Park</span>
        </Link>
        <div className="navbar-links">
          <Link to="/how-it-works">How It Works</Link>
          <a href="#benefits">Benefits</a>
          <a href="#download">Get the App</a>
          <Link to="/status">Check Status</Link>
          <Link to="/login" style={{ color: 'var(--accent-light)', fontWeight: 600 }}>Partner Login</Link>
        </div>
      </nav>

      {/* ── Hero ── */}
      <section className="hero-section">
        <div className="hero-bg" />
        <div className="hero-grid" />
        <div className="hero-content">
          <div className="hero-badge">
            <span style={{ display: 'flex' }}><Rocket size={16} /></span>
            <span>Earn passive income from your parking space</span>
          </div>
          <h1 className="hero-title">
            Turn Your Space Into<br />
            <span className="gradient-text">Real Income</span>
          </h1>
          <p className="hero-sub">
            List your parking space on Space Park and earn money every time someone parks.
            Real-time analytics, automatic payouts, and total control — all in your partner dashboard.
          </p>
          <div className="hero-actions">
            <Link to="/apply" className="btn-primary">
              <span>Apply Now — Free</span><span>→</span>
            </Link>
            <Link to="/how-it-works" className="btn-secondary">Learn How It Works</Link>
          </div>
        </div>
      </section>

      {/* ── Stats bar ── */}
      <div style={{ background: 'rgba(255,255,255,0.02)', borderTop: '1px solid var(--border)', borderBottom: '1px solid var(--border)', padding: '32px 40px' }}>
        <div style={{ maxWidth: 1000, margin: '0 auto', display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', textAlign: 'center', gap: 24 }}>
          {[
            { val: '500+', label: 'Partner Zones' },
            { val: '50K+', label: 'Monthly Parkers' },
            { val: '10%', label: 'Commission Only' },
            { val: '2–5 Days', label: 'Approval Time' },
          ].map(s => (
            <div key={s.label}>
              <div style={{ fontSize: 32, fontWeight: 900, background: 'linear-gradient(135deg,#fff,var(--accent-light))', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent' }}>{s.val}</div>
              <div style={{ fontSize: 13, color: 'var(--text-muted)', marginTop: 4 }}>{s.label}</div>
            </div>
          ))}
        </div>
      </div>

      {/* ── How it works teaser ── */}
      <section className="section">
        <div style={{ textAlign: 'center', marginBottom: 56 }}>
          <p className="section-eyebrow">Simple Process</p>
          <h2 className="section-title">Up and Running in 3 Steps</h2>
          <p className="section-sub" style={{ margin: '0 auto' }}>Get your parking space listed and start earning — no technical expertise needed</p>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 24 }}>
          {[
            { n: '1', icon: <FileText size={24} />, title: 'Submit Your Application', desc: 'Fill in your space details, pin your location on the map, and upload proof of ownership — takes under 5 minutes.' },
            { n: '2', icon: <CheckCircle2 size={24} />, title: 'Get Approved in Days', desc: 'Our team reviews within 2–5 business days. Check your status with your Application ID. You\'ll get login credentials by email.' },
            { n: '3', icon: <Banknote size={24} />, title: 'Earn Automatically', desc: 'Your zone goes live immediately. Monitor earnings, sessions, and performance from your dedicated partner dashboard.' },
          ].map(s => (
            <div key={s.n} className="glass-card" style={{ padding: 32, textAlign: 'center' }}>
              <div style={{ width: 56, height: 56, borderRadius: '50%', background: 'linear-gradient(135deg,var(--accent),#8b5cf6)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 24, margin: '0 auto 16px' }}>{s.icon}</div>
              <div style={{ fontSize: 11, fontWeight: 700, color: 'var(--accent-light)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 10 }}>Step {s.n}</div>
              <h3 style={{ fontSize: 18, fontWeight: 700, marginBottom: 10 }}>{s.title}</h3>
              <p style={{ color: 'var(--text-secondary)', fontSize: 14, lineHeight: 1.8 }}>{s.desc}</p>
            </div>
          ))}
        </div>
        <div style={{ textAlign: 'center', marginTop: 32 }}>
          <Link to="/how-it-works" style={{ color: 'var(--accent-light)', textDecoration: 'none', fontWeight: 600, fontSize: 15 }}>
            View full guide → 
          </Link>
        </div>
      </section>

      {/* ── Benefits ── */}
      <section id="benefits" style={{ background: 'rgba(255,255,255,0.01)', borderTop: '1px solid var(--border)', borderBottom: '1px solid var(--border)', padding: '100px 40px' }}>
        <div style={{ maxWidth: 1200, margin: '0 auto' }}>
          <div style={{ marginBottom: 56 }}>
            <p className="section-eyebrow">Why Space Park</p>
            <h2 className="section-title">Everything You Need to Succeed</h2>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 20 }}>
            <FeatureCard icon={<Banknote size={32} color="var(--success)" />} title="Keep 90% of Earnings" desc="We charge a transparent 10% commission — no hidden fees, no setup costs, no monthly charges. What you earn is yours." />
            <FeatureCard icon={<BarChart3 size={32} color="var(--accent-light)" />} title="Real-Time Analytics" desc="Monitor occupancy rates, session history, and daily earnings with a beautiful, purpose-built partner dashboard." />
            <FeatureCard icon={<Landmark size={32} color="var(--warning)" />} title="Automatic Bank Payouts" desc="Link your bank account once and receive automatic deposits — no manual withdrawal process required." />
            <FeatureCard icon={<Map size={32} color="#c084fc" />} title="Instant App Visibility" desc="Your zone appears on the Space Park mobile app the moment it's approved, visible to thousands of drivers searching for parking daily." />
            <FeatureCard icon={<ShieldCheck size={32} color="var(--success)" />} title="Verified & Trusted" desc="Every listed space is verified by our team, giving drivers confidence and driving higher occupancy for your zone." />
            <FeatureCard icon={<Smartphone size={32} color="var(--accent)" />} title="Self-Service Management" desc="Update your hourly rate, operating hours, and zone details from your dashboard anytime, without needing to contact support." />
          </div>
        </div>
      </section>

      {/* ── Download App ── */}
      <section id="download" className="section" style={{ textAlign: 'center' }}>
        <p className="section-eyebrow">Mobile App</p>
        <h2 className="section-title">Drivers Find You on Space Park</h2>
        <p className="section-sub" style={{ margin: '0 auto 48px' }}>
          Your listed zone is immediately visible to drivers using the Space Park app — search, park, and pay all in one place.
        </p>

        <div style={{ display: 'flex', gap: 16, justifyContent: 'center', flexWrap: 'wrap', marginBottom: 48 }}>
          <AppStoreBadge
            platform="App Store"
            imgSrc="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg"
            href="#"
            height={52}
          />
          <AppStoreBadge
            platform="Google Play"
            imgSrc="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png"
            href="#"
            height={76}
          />
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 20, maxWidth: 800, margin: '0 auto' }}>
          {[
            { icon: <Search size={28} color="var(--accent-light)" />, title: 'Find Parking', desc: 'Drivers search for available zones near their destination in real time.' },
            { icon: <CreditCard size={28} color="var(--success)" />, title: 'Cashless Payment', desc: 'Every session is paid digitally — no cash handling needed on your end.' },
            { icon: <Timer size={28} color="var(--warning)" />, title: 'Session Tracking', desc: 'Start, extend, and end parking sessions from the app with full audit trail.' },
            { icon: <Bell size={28} color="#c084fc" />, title: 'Instant Notifications', desc: 'Drivers get reminders and you get session alerts — seamlessly automated.' },
          ].map(f => (
            <div key={f.title} className="glass-card" style={{ padding: 24, textAlign: 'left' }}>
              <div style={{ fontSize: 28, marginBottom: 12 }}>{f.icon}</div>
              <h4 style={{ fontWeight: 700, marginBottom: 6 }}>{f.title}</h4>
              <p style={{ color: 'var(--text-secondary)', fontSize: 13, lineHeight: 1.7 }}>{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── CTA ── */}
      <section style={{ padding: '0 40px 100px', maxWidth: 1200, margin: '0 auto' }}>
        <div style={{
          padding: '64px 40px', textAlign: 'center',
          background: 'linear-gradient(135deg, rgba(99,102,241,0.15), rgba(139,92,246,0.1))',
          border: '1px solid rgba(99,102,241,0.2)', borderRadius: 24,
        }}>
          <h2 style={{ fontSize: 40, fontWeight: 900, marginBottom: 16 }}>Ready to Start Earning?</h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: 17, marginBottom: 40 }}>
            Join hundreds of parking space owners already making money on Space Park. Zero cost to apply.
          </p>
          <div style={{ display: 'flex', gap: 16, justifyContent: 'center', flexWrap: 'wrap' }}>
            <Link to="/apply" className="btn-primary" style={{ fontSize: 17, padding: '16px 40px' }}>
              <span>Apply for Free</span><span>→</span>
            </Link>
            <Link to="/status" className="btn-secondary" style={{ padding: '16px 28px' }}>
              Check Application Status
            </Link>
          </div>
        </div>
      </section>

      {/* ── Contact Form ── */}
      <section id="contact" style={{ padding: '0 40px 100px', maxWidth: 1000, margin: '0 auto' }}>
        <div style={{ textAlign: 'center', marginBottom: 40 }}>
          <h2 className="section-title">Have Questions?</h2>
          <p className="section-sub" style={{ margin: '0 auto' }}>Submit any questions you have and our team will get back to you.</p>
        </div>
        <div className="glass-card" style={{ padding: '8px', background: 'rgba(255,255,255,0.02)', overflow: 'hidden' }}>
          <iframe
            id="JotFormIFrame-260734183295057"
            title="Questions Form"
            allowtransparency="true"
            allowfullscreen="true"
            allow="geolocation; microphone; camera"
            src="https://form.jotform.com/260734183295057"
            frameBorder="0"
            style={{ 
              width: "100%", 
              height: "1200px", 
              border: "none" 
            }}
            scrolling="yes"
          />
        </div>
      </section>

      {/* ── Footer ── */}
      <footer className="footer">
        <div className="footer-grid">
          <div className="footer-brand">
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 14 }}>
              <img src="/logo.png" alt="Space Park" style={{ height: 34, objectFit: 'contain' }} />
              <span style={{ fontWeight: 800, fontSize: 17 }}>Space Park</span>
            </div>
            <p>The smart way to monetize your parking space. Connect with thousands of drivers and earn automatically.</p>
            <div style={{ display: 'flex', gap: 10, marginTop: 20 }}>
              <a href="#" target="_blank" rel="noopener noreferrer">
                <img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Download on the App Store" style={{ height: 36, display: 'block' }} />
              </a>
              <a href="#" target="_blank" rel="noopener noreferrer">
                <img src="https://play.google.com/intl/en_us/badges/static/images/badges/en_badge_web_generic.png" alt="Get it on Google Play" style={{ height: 52, display: 'block', marginTop: -8 }} />
              </a>
            </div>
          </div>
          <div className="footer-col">
            <h4>Partner Portal</h4>
            <Link to="/apply">Apply Now</Link>
            <Link to="/status">Check Status</Link>
            <Link to="/how-it-works">How It Works</Link>
            <Link to="/login">Partner Login</Link>
          </div>
          <div className="footer-col">
            <h4>Legal</h4>
            <Link to="/privacy">Privacy Policy</Link>
            <Link to="/terms">Terms of Service</Link>
            <a href="mailto:support@spacepark.com">Contact Support</a>
          </div>
        </div>
        <div className="footer-bottom">
          <p>© 2026 Space Park Ltd. All rights reserved. &nbsp;·&nbsp; <Link to="/privacy" style={{ color: 'var(--text-muted)', textDecoration: 'none' }}>Privacy</Link> &nbsp;·&nbsp; <Link to="/terms" style={{ color: 'var(--text-muted)', textDecoration: 'none' }}>Terms</Link></p>
        </div>
      </footer>
    </>
  );
}
