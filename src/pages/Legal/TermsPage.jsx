export default function TermsPage() {
  return (
    <div style={{ maxWidth: 720, margin: '0 auto', padding: '48px 24px 80px', fontFamily: 'inherit', lineHeight: 1.7 }}>
      <div style={{ marginBottom: 40 }}>
        <span style={{ fontSize: '2rem' }}>💰</span>
        <h1 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 8, marginBottom: 4 }}>Budget Buddy</h1>
        <p style={{ color: '#6B7280', fontSize: '0.9rem' }}>Terms of Service</p>
        <p style={{ color: '#9CA3AF', fontSize: '0.82rem' }}>Last updated: June 2025</p>
      </div>

      <Section title="1. Acceptance of Terms">
        By accessing or using Budget Buddy ("the App"), you agree to be bound by these Terms of Service. If you do not agree, please do not use the App.
      </Section>

      <Section title="2. Description of Service">
        Budget Buddy is a personal finance management application that allows users to track income and expenses, set budget goals, manage bills, view financial reports, and optionally link bank accounts through third-party providers (Plaid).
      </Section>

      <Section title="3. User Accounts">
        You are responsible for maintaining the confidentiality of your account credentials. You agree to provide accurate information when creating your account and to notify us immediately of any unauthorized use. You must be at least 13 years old to use the App.
      </Section>

      <Section title="4. Third-Party Services">
        The App integrates with third-party services including Google, Facebook, and Plaid. Your use of these integrations is subject to the respective third-party terms of service. We are not responsible for the practices of these third parties.
      </Section>

      <Section title="5. Financial Data">
        Budget Buddy is a personal finance tracking tool and does not provide financial, investment, tax, or legal advice. All financial data you enter or sync is for your personal tracking purposes only. We do not make investment recommendations or guarantee the accuracy of synced data.
      </Section>

      <Section title="6. Data and Privacy">
        Your use of the App is also governed by our Privacy Policy. By using the App, you consent to the collection and use of your information as described in our Privacy Policy.
      </Section>

      <Section title="7. Prohibited Uses">
        You agree not to use the App to engage in any unlawful activity, attempt to gain unauthorized access to our systems, transmit malicious code or malware, or use the App in any way that could damage or impair its functionality.
      </Section>

      <Section title="8. Intellectual Property">
        All content, features, and functionality of the App are owned by Budget Buddy and are protected by applicable intellectual property laws. You may not copy, modify, distribute, or create derivative works without our express written permission.
      </Section>

      <Section title="9. Disclaimer of Warranties">
        The App is provided "as is" without warranties of any kind, either express or implied. We do not warrant that the App will be error-free, uninterrupted, or free of viruses or other harmful components.
      </Section>

      <Section title="10. Limitation of Liability">
        To the maximum extent permitted by law, Budget Buddy shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the App.
      </Section>

      <Section title="11. Changes to Terms">
        We reserve the right to modify these Terms at any time. We will notify users of material changes via the App or email. Continued use of the App after changes constitutes acceptance of the new Terms.
      </Section>

      <Section title="12. Contact">
        If you have questions about these Terms, please contact us at: <a href="mailto:kbank1988@gmail.com" style={{ color: '#6C63FF' }}>kbank1988@gmail.com</a>
      </Section>

      <div style={{ marginTop: 48, paddingTop: 24, borderTop: '1px solid #E8E9FF' }}>
        <a href="/privacy" style={{ color: '#6C63FF', fontWeight: 600, textDecoration: 'none', fontSize: '0.9rem' }}>
          → View Privacy Policy
        </a>
      </div>
    </div>
  )
}

function Section({ title, children }) {
  return (
    <div style={{ marginBottom: 28 }}>
      <h2 style={{ fontSize: '1rem', fontWeight: 700, marginBottom: 8, color: '#1A1A2E' }}>{title}</h2>
      <p style={{ color: '#374151', fontSize: '0.93rem', margin: 0 }}>{children}</p>
    </div>
  )
}
