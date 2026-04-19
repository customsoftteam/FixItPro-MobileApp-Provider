import 'dart:async';

import 'package:flutter/material.dart';

import '../models/service_workflow.dart';
import '../services/api_client.dart';
import '../services/booking_service.dart';

class ServiceWorkflowScreen extends StatefulWidget {
  const ServiceWorkflowScreen({
    super.key,
    required this.bookingId,
    required this.bookingCode,
    required this.bookingService,
  });

  final String bookingId;
  final String bookingCode;
  final BookingService bookingService;

  @override
  State<ServiceWorkflowScreen> createState() => _ServiceWorkflowScreenState();
}

class _ServiceWorkflowScreenState extends State<ServiceWorkflowScreen> {
  final TextEditingController _otpController = TextEditingController();

  ServiceWorkflowData? _workflow;
  String? _error;
  String? _message;
  String _demoOtp = '';
  bool _loading = true;
  bool _otpSending = false;
  bool _otpVerifying = false;
  bool _pauseActionLoading = false;
  int? _stepLoadingOrder;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadWorkflow();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final status = _workflow?.status ?? '';
      if (status == 'in_progress' || status == 'otp_sent' || status == 'paused') {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkflow() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final workflow = await widget.bookingService.fetchServiceSteps(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _workflow = workflow;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = _resolveError(err, 'Failed to fetch service steps');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  int get _elapsedSeconds {
    final workflow = _workflow;
    if (workflow == null || workflow.serviceStartTime == null) return 0;

    var elapsed = DateTime.now().difference(workflow.serviceStartTime!).inSeconds;
    elapsed -= workflow.pausedDurationSeconds;

    if (workflow.status == 'paused' && workflow.pauseStartedAt != null) {
      elapsed -= DateTime.now().difference(workflow.pauseStartedAt!).inSeconds;
    }

    return elapsed < 0 ? 0 : elapsed;
  }

  int get _totalServiceSeconds {
    return ((_workflow?.serviceDurationMinutes ?? 0) * 60).clamp(0, 1 << 31);
  }

  int get _remainingSeconds {
    final remaining = _totalServiceSeconds - _elapsedSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  int get _progressPercentage {
    if (_totalServiceSeconds <= 0) return 0;
    final value = ((_elapsedSeconds / _totalServiceSeconds) * 100).round();
    return value.clamp(0, 100);
  }

  int get _nextExpectedOrder {
    final completed = _workflow?.completedSteps ?? const <int>[];
    if (completed.isEmpty) return 1;
    return completed.last + 1;
  }

  bool get _allStepsCompleted {
    final workflow = _workflow;
    if (workflow == null || workflow.steps.isEmpty) return false;
    return workflow.completedSteps.length == workflow.steps.length;
  }

  bool get _canPauseService => _workflow?.status == 'in_progress';
  bool get _canResumeService => _workflow?.status == 'paused';
  bool get _canCompleteSteps => _workflow?.status == 'in_progress';
  bool get _canSendOtp => _workflow?.status == 'in_progress' && _allStepsCompleted;

  bool get _canVerifyOtp {
    final status = _workflow?.status ?? '';
    return status == 'otp_sent' || _demoOtp.isNotEmpty;
  }

  String _resolveError(Object err, String fallback) {
    if (err is ApiClientException && err.message.isNotEmpty) {
      return err.message;
    }
    return fallback;
  }

  String _formatDuration(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final h = (safe ~/ 3600).toString().padLeft(2, '0');
    final m = ((safe % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (safe % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _handleStepCheck(int order) async {
    setState(() {
      _stepLoadingOrder = order;
      _error = null;
      _message = null;
    });

    try {
      await widget.bookingService.completeServiceStep(widget.bookingId, order);
      await _loadWorkflow();
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = _resolveError(err, 'Failed to update service step');
      });
    } finally {
      if (mounted) {
        setState(() {
          _stepLoadingOrder = null;
        });
      }
    }
  }

  Future<void> _handleSendOtp() async {
    setState(() {
      _otpSending = true;
      _error = null;
      _message = null;
    });

    try {
      final otp = await widget.bookingService.sendCompletionOtp(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _demoOtp = otp;
        _message = 'OTP sent to customer phone (demo mode).';
      });
      await _loadWorkflow();
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = _resolveError(err, 'Failed to send OTP');
      });
    } finally {
      if (mounted) {
        setState(() {
          _otpSending = false;
        });
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    setState(() {
      _otpVerifying = true;
      _error = null;
      _message = null;
    });

    try {
      await widget.bookingService.verifyCompletionOtp(widget.bookingId, _otpController.text.trim());
      if (!mounted) return;
      setState(() {
        _message = 'OTP verified. Booking completed successfully.';
      });
      Navigator.of(context).pop(true);
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = _resolveError(err, 'Invalid OTP');
      });
    } finally {
      if (mounted) {
        setState(() {
          _otpVerifying = false;
        });
      }
    }
  }

  Future<void> _handlePauseService() async {
    setState(() {
      _pauseActionLoading = true;
      _error = null;
      _message = null;
    });

    try {
      await widget.bookingService.pauseService(widget.bookingId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = _resolveError(err, 'Failed to pause service');
      });
    } finally {
      if (mounted) {
        setState(() {
          _pauseActionLoading = false;
        });
      }
    }
  }

  Future<void> _handleResumeService() async {
    setState(() {
      _pauseActionLoading = true;
      _error = null;
      _message = null;
    });

    try {
      await widget.bookingService.resumeService(widget.bookingId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = _resolveError(err, 'Failed to resume service');
      });
    } finally {
      if (mounted) {
        setState(() {
          _pauseActionLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service Workflow • ${widget.bookingCode}'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w700)),
                      ),
                    if (_message != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9FBEF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Text(_message!, style: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w700)),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildStopwatchCard(),
                    const SizedBox(height: 12),
                    Expanded(child: _buildBodyContent()),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStopwatchCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Service Stopwatch', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF15803D))),
                  const SizedBox(height: 6),
                  Text(_formatDuration(_elapsedSeconds), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF15803D))),
                  const SizedBox(height: 4),
                  Text('Out of ${_formatDuration(_totalServiceSeconds)}', style: const TextStyle(fontSize: 13, color: Color(0xFF65A30D))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Remaining', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF15803D), fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(_formatDuration(_remainingSeconds), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF4ADE80))),
                  const SizedBox(height: 4),
                  Text('$_progressPercentage% Complete', style: const TextStyle(fontSize: 12, color: Color(0xFF65A30D))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _progressPercentage / 100,
              minHeight: 7,
              backgroundColor: const Color(0xFFDCFCE7),
              color: const Color(0xFF15803D),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_canPauseService)
                ElevatedButton(
                  onPressed: _pauseActionLoading ? null : _handlePauseService,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C)),
                  child: Text(_pauseActionLoading ? 'Pausing...' : 'Pause Service'),
                ),
              if (_canResumeService)
                ElevatedButton(
                  onPressed: _pauseActionLoading ? null : _handleResumeService,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  child: Text(_pauseActionLoading ? 'Resuming...' : 'Resume Service'),
                ),
            ],
          ),
          if (_workflow?.status == 'paused') ...[
            const SizedBox(height: 8),
            const Text(
              'Service is paused. Click Resume Service to continue checklist and OTP flow.',
              style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    final workflow = _workflow;
    if (workflow == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Checklist', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          if (workflow.steps.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Text('No service steps configured by admin for this booking.'),
            )
          else
            ...workflow.steps.map((step) {
              final checked = workflow.completedSteps.contains(step.order);
              final disabled = !_canCompleteSteps || checked || _stepLoadingOrder != null || step.order != _nextExpectedOrder;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: checked ? const Color(0xFFF0FDF4) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: CheckboxListTile(
                  value: checked,
                  onChanged: disabled ? null : (_) => _handleStepCheck(step.order),
                  title: Text(step.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: step.description.isEmpty ? null : Text(step.description),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              );
            }),
          const SizedBox(height: 8),
          if (_canSendOtp)
            ElevatedButton(
              onPressed: _otpSending ? null : _handleSendOtp,
              child: Text(_otpSending ? 'Sending OTP...' : 'Send OTP'),
            ),
          if (_canVerifyOtp) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                _demoOtp.isNotEmpty ? 'Demo OTP is $_demoOtp' : 'OTP has been sent. Enter customer OTP to complete.',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                hintText: '6-digit OTP',
              ),
              onChanged: (value) {
                final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (digitsOnly != value) {
                  _otpController.value = TextEditingValue(
                    text: digitsOnly,
                    selection: TextSelection.collapsed(offset: digitsOnly.length),
                  );
                }
              },
            ),
            const SizedBox(height: 6),
            ElevatedButton(
              onPressed: _otpVerifying || _otpController.text.trim().length != 6 ? null : _handleVerifyOtp,
              child: Text(_otpVerifying ? 'Verifying...' : 'Verify OTP and Complete'),
            ),
          ],
        ],
      ),
    );
  }
}