import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _mobileController = TextEditingController(text: '9876543210');
  final TextEditingController _otpController = TextEditingController(text: '123456');
  bool _loading = false;
  bool _otpSent = false;
  String? _pendingMobile;
  String? _debugOtp;
  String? _error;

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!_otpSent) {
        final mobile = _mobileController.text.trim();
        if (mobile.length != 10) {
          throw Exception('Enter a valid 10 digit mobile number.');
        }

        final response = await _authService.sendOtp(mobile: mobile);
        if (!mounted) return;

        setState(() {
          _otpSent = true;
          _pendingMobile = mobile;
          _debugOtp = response['debugOtp']?.toString() ?? '123456';
        });
        return;
      }

      final otp = _otpController.text.trim();
      if (otp.length != 6) {
        throw Exception('Enter the 6 digit OTP.');
      }

      final session = await _authService.verifyOtp(
        mobile: _pendingMobile ?? _mobileController.text.trim(),
        otp: otp,
      );

      if (!mounted) {
        return;
      }

      final onboardingCompleted = session.provider['onboardingCompleted'] == true;
      Navigator.of(context).pushReplacementNamed(
        session.isNewUser || !onboardingCompleted ? '/onboarding' : '/shell',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget introPanel() {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF111A2E), Color(0xFF111D34)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFF12D3B5),
              child: Icon(Icons.handyman_outlined, color: Colors.white),
            ),
            SizedBox(height: 36),
            Text(
              'FixItPro Provider',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Manage bookings, profile updates, availability, and notifications from one provider workspace.',
              style: TextStyle(
                color: Color(0xFFB8C6DC),
                height: 1.5,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 36),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Badge(text: 'Responsive drawer'),
                _Badge(text: 'Booking workflow'),
                _Badge(text: 'Live notifications'),
              ],
            ),
          ],
        ),
      );
    }

    Widget formPanel() {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sign in', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 10),
            const Text('Use your provider mobile number to enter the portal.'),
            const SizedBox(height: 24),
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              enabled: !_otpSent,
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Use the OTP sent to your phone. If the backend is running in mock mode, the code may appear above.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'OTP',
                  prefixIcon: Icon(Icons.password_outlined),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFFB42318)),
              ),
            ],
            if (_debugOtp != null) ...[
              const SizedBox(height: 12),
              Text(
                'Dev OTP: $_debugOtp',
                style: const TextStyle(color: Color(0xFF075985), fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _continue,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : Text(_otpSent ? 'Verify OTP' : 'Send OTP'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Dummy OTP mode is enabled. Use 123456 to sign in.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF08111F), Color(0xFF0F1F35), Color(0xFF0B7268)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 720;
                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: introPanel()),
                                const SizedBox(width: 24),
                                Expanded(child: formPanel()),
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              introPanel(),
                              const SizedBox(height: 24),
                              formPanel(),
                            ],
                          );
                        },
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

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}
