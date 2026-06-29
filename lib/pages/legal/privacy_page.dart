import 'package:flutter/material.dart';

import 'legal_scaffold.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      subtitle: 'Privacy Policy',
      children: [
        LegalSection(
          title: '1. Information We Collect',
          body:
              'We collect information you provide directly, including your name, email address, and profile photo when you sign in with Google or Facebook. If you link a bank account via Plaid, we receive account names, balances, and transaction data from your financial institution. We also collect financial data you manually enter into the App such as transactions, budgets, and bills.',
        ),
        LegalSection(
          title: '2. How We Use Your Information',
          body:
              'We use your information to provide and improve the App, display your financial data to you, send verification codes for two-factor authentication, and communicate with you about your account. We do not sell your personal information to third parties.',
        ),
        LegalSection(
          title: '3. Data Storage',
          body:
              'Your financial data is stored locally on your device. Account session information is stored locally as well. We do not maintain a central database of your personal financial records.',
        ),
        LegalSection(
          title: '4. Third-Party Services',
          body:
              'Google: When you sign in with Google, we receive your name, email address, and profile photo, governed by Google\'s Privacy Policy. Facebook: When you sign in with Facebook, we receive your name, email address, and profile photo, governed by Meta\'s Privacy Policy. Plaid: If you connect a bank account, Plaid acts as an intermediary between the App and your bank, governed by the Plaid End User Privacy Policy.',
        ),
        LegalSection(
          title: '5. Two-Factor Authentication',
          body:
              'When you enable two-factor authentication, we send a one-time verification code to your email or phone number via Resend (email) or Twilio (SMS). These providers process your contact information solely to deliver the code and do not retain it for other purposes.',
        ),
        LegalSection(
          title: '6. Data Security',
          body:
              'We use industry-standard security practices including HTTPS encryption for all data in transit. Two-factor authentication codes are cryptographically signed and expire after 10 minutes. However, no method of transmission or storage is 100% secure, and we cannot guarantee absolute security.',
        ),
        LegalSection(
          title: '7. Your Rights',
          body:
              'You have the right to access, correct, or delete your personal information at any time. You can delete your locally stored data through the App\'s data deletion screen, or by signing out. To request deletion of any information held by third-party integrations, contact those services directly.',
        ),
        LegalSection(
          title: '8. Children\'s Privacy',
          body:
              'The App is not directed to children under the age of 13. We do not knowingly collect personal information from children under 13. If you believe a child has provided us with personal information, please contact us so we can delete it.',
        ),
        LegalSection(
          title: '9. Changes to This Policy',
          body:
              'We may update this Privacy Policy from time to time. We will notify you of significant changes via the App or by email. Your continued use of the App after changes are posted constitutes your acceptance of the updated policy.',
        ),
        LegalSection(
          title: '10. Contact Us',
          body:
              'If you have questions or concerns about this Privacy Policy or our data practices, please contact us at: kbank1988@gmail.com',
        ),
      ],
    );
  }
}
