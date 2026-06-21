export default function PrivacyPage() {
  return (
    <div style={{ maxWidth: 720, margin: '0 auto', padding: '48px 24px 80px', fontFamily: 'inherit', lineHeight: 1.7 }}>
      <div style={{ marginBottom: 40 }}>
        <span style={{ fontSize: '2rem' }}>💰</span>
        <h1 style={{ fontSize: '1.8rem', fontWeight: 800, marginTop: 8, marginBottom: 4 }}>Budget Buddy</h1>
        <p style={{ color: '#6B7280', fontSize: '0.9rem' }}>Privacy Policy</p>
        <p style={{ color: '#9CA3AF', fontSize: '0.82rem' }}>Last updated: June 2025</p>
      </div>

      <Section title="1. Information We Collect">
        We collect information you provide directly, including your name, email address, and profile photo when you sign in with Google or Facebook. If you link a bank account via Plaid, we receive account names, balances, and transaction data from your financial institution. We also collect financial data you manually enter into the App such as transactions, budgets, and bills.
      </Section>

      <Section title="2. How We Use Your Information">
        We use your information to provide and improve the App, display your financial data to you, send verification codes for two-factor authentication, and communicate with you about your account. We do not sell your personal information to third parties.
      </Section>

      <Section title="3. Data Storage">
        Your financial data is stored locally on your device using your browser's local storage. Account session information is stored locally as well. We do not maintain a central database of your personal financial records.
      </Section>

      <Section title="4. Third-Party Services">
        <strong>Google:</strong> When you sign in with Google, we receive your name, email address, and profile photo from Google. This is governed by <a href="https://policies.google.com/privacy" target="_blank" rel="noopener noreferrer" style={{ color: '#6C63FF' }}>Google's Privacy Policy</a>.<br /><br />
        <strong>Facebook:</strong> When you sign in with Facebook, we receive your name, email address, and profile photo. This is governed by <a href="https://www.facebook.com/privacy/policy/" target="_blank" rel="noopener noreferrer" style={{ color: '#6C63FF' }}>Meta's Privacy Policy</a>.<br /><br />
        <strong>Plaid:</strong> If you connect a bank account, Plaid acts as an intermediary between the App and your bank. Plaid's data practices are governed by the <a href="https://plaid.com/legal/#end-user-privacy-policy" target="_blank" rel="noopener noreferrer" style={{ color: '#6C63FF' }}>Plaid End User Privacy Policy</a>.
      </Section>

      <Section title="5. Two-Factor Authentication">
        When you enable two-factor authentication, we send a one-time verification code to your email or phone number via Resend (email) or Twilio (SMS). These providers process your contact information solely to deliver the code and do not retain it for other purposes.
      </Section>

      <Section title="6. Data Security">
        We use industry-standard security practices including HTTPS encryption for all data in transit. Two-factor authentication codes are cryptographically signed and expire after 10 minutes. However, no method of transmission or storage is 100% secure, and we cannot guarantee absolute security.
      </Section>

      <Section title="7. Your Rights">
        You have the right to access, correct, or delete your personal information at any time. You can delete your locally stored data by clearing your browser's local storage, or by signing out and clearing data through your browser settings. To request deletion of any information held by third-party integrations, contact those services directly.
      </Section>

      <Section title="8. Children's Privacy">
        The App is not directed to children under the age of 13. We do not knowingly collect personal information from children under 13. If you believe a child has provided us with personal information, please contact us so we can delete it.
      </Section>

      <Section title="9. Changes to This Policy">
        We may update this Privacy Policy from time to time. We will notify you of significant changes via the App or by email. Your continued use of the App after changes are posted constitutes your acceptance of the updated policy.
      </Section>

      <Section title="10. Contact Us">
        If you have questions or concerns about this Privacy Policy or our data practices, please contact us at: <a href="mailto:kbank1988@gmail.com" style={{ color: '#6C63FF' }}>kbank1988@gmail.com</a>
      </Section>

      <div style={{ marginTop: 48, paddingTop: 24, borderTop: '1px solid #E8E9FF', display: 'flex', flexDirection: 'column', gap: 12 }}>
        <a href="/terms" style={{ color: '#6C63FF', fontWeight: 600, textDecoration: 'none', fontSize: '0.9rem' }}>
          → View Terms of Service
        </a>
        <a href="/data-deletion" style={{ color: '#D94F4F', fontWeight: 600, textDecoration: 'none', fontSize: '0.9rem' }}>
          → Request Data Deletion
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
