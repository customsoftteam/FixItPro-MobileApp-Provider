import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      ('How do I accept a booking?', 'Open the bookings tab and tap the assigned booking card.'),
      ('How are OTP completions handled?', 'The booking workflow is prepared for OTP validation at service completion.'),
      ('Where do I update my skills?', 'Use the Skills page to keep your service categories up to date.'),
      ('Can I change availability?', 'Yes, the Availability page is designed for working-day and slot updates.'),
    ];

    return ListView(
      children: [
        Text('Help', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text('Use this section for support, FAQ, and portal guidance.'),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FAQ', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                ...faqs.map(
                  (faq) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(faq.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(faq.$2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contact support', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                const Text('support@fixitpro.com\n+91 80000 12345'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
