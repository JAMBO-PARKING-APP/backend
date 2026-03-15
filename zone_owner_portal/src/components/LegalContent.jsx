import { Link } from 'react-router-dom';

/* ── Shared Legal Layout ── */
export function LegalLayout({ title, children }) {
  return (
    <>
      <nav className="navbar">
        <Link to="/" className="navbar-logo">
          <img src="/logo.png" alt="Space Park" style={{ height: 36, objectFit: 'contain' }} />
          <span>Space Park</span>
        </Link>
        <Link to="/" className="btn-secondary" style={{ padding: '8px 20px', fontSize: 13 }}>← Back to Home</Link>
      </nav>
      <div style={{ minHeight: '100vh', paddingTop: 80 }}>
        <div style={{ maxWidth: 820, margin: '0 auto', padding: '60px 24px' }}>
          <div className="glass-card" style={{ padding: '48px' }}>
            {children}
          </div>
        </div>
      </div>
    </>
  );
}

function Section({ title, children }) {
  return (
    <div style={{ marginBottom: 28 }}>
      <h3 style={{ fontSize: 18, fontWeight: 700, color: 'var(--accent-light)', marginBottom: 10 }}>{title}</h3>
      <div style={{ color: 'var(--text-secondary)', fontSize: 15, lineHeight: 1.8 }}>{children}</div>
    </div>
  );
}

export function PrivacyContent() {
  return (
    <>
      <h1 style={{ fontSize: 32, fontWeight: 900, marginBottom: 4 }}>Privacy Policy</h1>
      <p style={{ color: 'var(--text-muted)', fontSize: 13, marginBottom: 40 }}>Effective Date: February 9, 2026 &nbsp;·&nbsp; Last Updated: February 9, 2026</p>

      <Section title="1. Introduction">
        We are committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use the Space Park mobile application, partner portal, and related services.
      </Section>
      <Section title="2. Information We Collect">
        <ul style={{ paddingLeft: 20 }}>
          {['Phone Number – for account creation and authentication','Name – for account identification','Email Address – for account access and notifications','Zone & Location Data – address and coordinates of your parking space','Bank Account Details – for earnings deposits','Documents – proof of ownership uploaded during application','Usage Data – sessions, earnings, app activity'].map(item => <li key={item} style={{ marginBottom: 6 }}>{item}</li>)}
        </ul>
      </Section>
      <Section title="3. How We Use Your Information">
        <ul style={{ paddingLeft: 20 }}>
          {['Create and manage your partner account','Process parking sessions and calculate earnings','Deposit funds to your registered bank account','Send notifications about applications, sessions, and payouts','Provide customer support','Improve our services and develop new features','Comply with legal obligations'].map(item => <li key={item} style={{ marginBottom: 6 }}>{item}</li>)}
        </ul>
      </Section>
      <Section title="4. Data Sharing">
        We do <strong>NOT</strong> sell your data. We may share information with service providers (payment processors, cloud hosting), legal authorities when required by law, or business partners in case of merger or acquisition. All service providers are contractually obligated to protect your data.
      </Section>
      <Section title="5. Data Security">
        <ul style={{ paddingLeft: 20 }}>
          {['Encryption using SSL/TLS','Secure storage on protected servers','Limited employee access','Regular security audits'].map(item => <li key={item} style={{ marginBottom: 6 }}>{item}</li>)}
        </ul>
      </Section>
      <Section title="6. Your Rights">
        <ul style={{ paddingLeft: 20 }}>
          {['Access your personal information','Correct inaccurate data','Request deletion of your account','Opt out of promotional notifications','Request data export'].map(item => <li key={item} style={{ marginBottom: 6 }}>{item}</li>)}
        </ul>
      </Section>
      <Section title="7. Children's Privacy">
        Our Service is not intended for children under 13. We do not knowingly collect information from children under 13.
      </Section>
      <Section title="8. Contact Us">
        For questions regarding this Privacy Policy:<br />
        Email: <a href="mailto:support@spacepark.com" style={{ color: 'var(--accent-light)' }}>support@spacepark.com</a><br />
        Phone: +256 700 000 000
      </Section>

      <div style={{ marginTop: 32, padding: '20px 24px', background: 'rgba(99,102,241,0.08)', border: '1px solid rgba(99,102,241,0.2)', borderRadius: 12, color: 'var(--text-secondary)', fontSize: 14, lineHeight: 1.7 }}>
        By using Space Park, you consent to this Privacy Policy. This policy complies with GDPR, CCPA, Google Play Store, and Apple App Store requirements.
      </div>
    </>
  );
}

export function TermsContent() {
  return (
    <>
      <h1 style={{ fontSize: 32, fontWeight: 900, marginBottom: 4 }}>Terms of Service</h1>
      <p style={{ color: 'var(--text-muted)', fontSize: 13, marginBottom: 40 }}>Effective Date: February 9, 2026 &nbsp;·&nbsp; Last Updated: February 9, 2026</p>

      <Section title="1. Acceptance of Terms">
        By accessing or using Space Park, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service. These terms constitute a legally binding agreement between you and Space Park Ltd. If you do not agree, you must immediately cease all use of the Service.
      </Section>
      <Section title="2. User Eligibility and Responsibilities">
        <ul style={{ paddingLeft: 20 }}>
          {['You must be at least 18 years of age and possess legal authority to form a binding contract.','You are responsible for ensuring all information provided (zone details, bank info, etc.) is accurate and up to date.','You agree to comply with all local property and parking laws.','You are solely responsible for any activity that occurs under your account.'].map(item => <li key={item} style={{ marginBottom: 6 }}>{item}</li>)}
        </ul>
      </Section>
      <Section title="3. Account Security">
        <ul style={{ paddingLeft: 20 }}>
          {['You must safeguard your login credentials and not share them with third parties.','We reserve the right to suspend or terminate accounts that show suspicious activity.','Notify us immediately of any unauthorized use of your account.'].map(item => <li key={item} style={{ marginBottom: 6 }}>{item}</li>)}
        </ul>
      </Section>
      <Section title="4. Partner Zone Services">
        Space Park provides a digital platform for listing your parking space, receiving automated payments, monitoring earnings in real-time, and managing your zone remotely. Availability data is dynamic. Space Park is not responsible for modifications to parking zone accessibility by municipal authorities.
      </Section>
      <Section title="5. Financial Terms and Earnings">
        <ul style={{ paddingLeft: 20 }}>
          {['All rates are inclusive of applicable taxes unless stated otherwise.','Earnings are calculated after Space Park\'s commission is deducted (displayed on your dashboard).','Funds are deposited to your registered bank account on a rolling basis.','Earning disputes must be submitted within 7 days via support.'].map(item => <li key={item} style={{ marginBottom: 6 }}>{item}</li>)}
        </ul>
      </Section>
      <Section title="6. Data Privacy and Processing">
        We collect and process your personal data, including location information and bank details, to provide the Services. Our use of your data is governed by our Privacy Policy, aligned with applicable data protection laws.
      </Section>
      <Section title="7. Violations and Enforcement">
        Misuse of the platform, providing false information, or violating these terms may result in immediate suspension of your account and forfeiture of pending earnings.
      </Section>
      <Section title="8. Intellectual Property">
        All content, including logos, UI designs, and underlying code, is the exclusive property of Space Park Ltd. Any unauthorized reproduction or reverse engineering is strictly prohibited.
      </Section>
      <Section title="9. Dispute Resolution">
        Any disputes shall first be attempted to be resolved through good-faith mediation. If mediation fails, the dispute shall be settled by binding arbitration in accordance with applicable law.
      </Section>
      <Section title="10. Disclaimers">
        SPACE PARK IS PROVIDED "AS IS" AND "AS AVAILABLE". TO THE MAXIMUM EXTENT PERMITTED BY LAW, SPACE PARK LTD DISCLAIMS ALL WARRANTIES. YOU AGREE TO INDEMNIFY AND HOLD HARMLESS SPACE PARK LTD FROM ANY CLAIMS ARISING FROM YOUR MISUSE OF THE SERVICE.
      </Section>

      <div style={{ marginTop: 32, padding: '20px 24px', background: 'rgba(99,102,241,0.08)', border: '1px solid rgba(99,102,241,0.2)', borderRadius: 12, color: 'var(--text-secondary)', fontSize: 14, lineHeight: 1.7, textAlign: 'center', fontWeight: 600 }}>
        BY USING SPACE PARK, YOU ACKNOWLEDGE THAT YOU HAVE READ, UNDERSTOOD, AND AGREE TO BE BOUND BY THESE TERMS OF SERVICE.
      </div>
      <p style={{ textAlign: 'center', marginTop: 16, fontSize: 12, color: 'var(--text-muted)' }}>Compliant with Google Play Store and Apple App Store requirements.</p>
    </>
  );
}
