import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _finishOnboarding(BuildContext context) async {
    await AuthService().completeOnboarding();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushReplacementNamed('/shell');
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Basic profile', 'Add your name, mobile, and service city.'),
      ('Professional details', 'Choose skills and service categories.'),
      ('Availability', 'Set your working days and time slots.'),
      ('Documents', 'Prepare identity and bank details for verification.'),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4FAFC), Color(0xFFE8F6F4), Color(0xFFF7FBFD)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1060),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Onboarding', style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 8),
                          const Text('Follow the same provider setup flow used by the web portal.'),
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.maxWidth >= 900 ? 2 : 1;
                              return Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  for (var index = 0; index < steps.length; index++)
                                    SizedBox(
                                      width: columns == 2
                                          ? (constraints.maxWidth - 16) / 2
                                          : constraints.maxWidth,
                                      child: _StepCard(
                                        index: index + 1,
                                        title: steps[index].$1,
                                        description: steps[index].$2,
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                OutlinedButton(
                                  onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                                  child: const Text('Back'),
                                ),
                                FilledButton(
                                  onPressed: () => _finishOnboarding(context),
                                  child: const Text('Finish setup'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.index, required this.title, required this.description});

  final int index;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE6FAF6),
            child: Text(
              '$index',
              style: const TextStyle(
                color: Color(0xFF0F766E),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(description),
        ],
      ),
    );
  }
}
