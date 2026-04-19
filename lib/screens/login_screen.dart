import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
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
        if (mobile.length != 10 || int.tryParse(mobile) == null) {
          throw Exception('Enter a valid 10 digit mobile number.');
        }

        final response = await _authService.sendOtp(mobile: mobile);
        if (!mounted) return;

        setState(() {
          _otpSent = true;
          _pendingMobile = mobile;
          _debugOtp = response['debugOtp']?.toString() ?? '123456';
          _otpController.clear();
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
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              enabled: !_otpSent,
              decoration: InputDecoration(
                labelText: 'Mobile number',
                prefixIcon: const Icon(Icons.phone_outlined),
                hintText: 'Enter 10-digit mobile number',
                counterText: '',
                suffixIcon: _otpSent
                    ? TextButton(
                        onPressed: () {
                          setState(() {
                            _otpSent = false;
                            _pendingMobile = null;
                            _otpController.clear();
                            _error = null;
                          });
                        },
                        child: const Text('Change'),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _otpSent
                  ? 'Enter the 6-digit OTP sent to +91 ${_pendingMobile ?? _mobileController.text.trim()}.'
                  : 'Tap Send OTP to receive a verification code.',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OTP Verification',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'OTP',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                        hintText: 'Enter 6-digit OTP',
                        counterText: '',
                      ),
                    ),
                  ],
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
