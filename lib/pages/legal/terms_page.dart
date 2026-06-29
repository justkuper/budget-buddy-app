import 'package:flutter/material.dart';

import 'legal_scaffold.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      subtitle: 'Terms of Service',
      children: [
        LegalSection(
          title: '1. Acceptance of Terms',
          body:
              'By accessing or using Budget Buddy ("the App"), you agree to be bound by these Terms of Service. If you do not agree, please do not use the App.',
        ),
        LegalSection(
          title: '2. Description of Service',
          body:
              'Budget Buddy is a personal finance management application that allows users to track income and expenses, set budget goals, manage bills, view financial reports, and optionally link bank accounts through third-party providers (Plaid).',
        ),
        LegalSection(
          title: '3. User Accounts',
          body:
              'You are responsible for maintaining the confidentiality of your account credentials. You agree to provide accurate information when creating your account and to notify us immediately of any unauthorized use. You must be at least 13 years old to use the App.',
        ),
        LegalSection(
          title: '4. Third-Party Services',
          body:
              'The App integrates with third-party services including Google, Facebook, and Plaid. Your use of these integrations is subject to the respective third-party terms of service. We are not responsible for the practices of these third parties.',
        ),
        LegalSection(
          title: '5. Financial Data',
          body:
              'Budget Buddy is a personal finance tracking tool and does not provide financial, investment, tax, or legal advice. All financial data you enter or sync is for your personal tracking purposes only. We do not make investment recommendations or guarantee the accuracy of synced data.',
        ),
        LegalSection(
          title: '6. Data and Privacy',
          body:
              'Your use of the App is also governed by our Privacy Policy. By using the App, you consent to the collection and use of your information as described in our Privacy Policy.',
        ),
        LegalSection(
          title: '7. Prohibited Uses',
          body:
              'You agree not to use the App to engage in any unlawful activity, attempt to gain unauthorized access to our systems, transmit malicious code or malware, or use the App in any way that could damage or impair its functionality.',
        ),
        LegalSection(
          title: '8. Intellectual Property',
          body:
              'All content, features, and functionality of the App are owned by Budget Buddy and are protected by applicable intellectual property laws. You may not copy, modify, distribute, or create derivative works without our express written permission.',
        ),
        LegalSection(
          title: '9. Disclaimer of Warranties',
          body:
              'The App is provided "as is" without warranties of any kind, either express or implied. We do not warrant that the App will be error-free, uninterrupted, or free of viruses or other harmful components.',
        ),
        LegalSection(
          title: '10. Limitation of Liability',
          body:
              'To the maximum extent permitted by law, Budget Buddy shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the App.',
        ),
        LegalSection(
          title: '11. Changes to Terms',
          body:
              'We reserve the right to modify these Terms at any time. We will notify users of material changes via the App or email. Continued use of the App after changes constitutes acceptance of the new Terms.',
        ),
        LegalSection(
          title: '12. Contact',
          body: 'If you have questions about these Terms, please contact us at: kbank1988@gmail.com',
        ),
      ],
    );
  }
}
