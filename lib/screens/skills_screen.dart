import 'package:flutter/material.dart';

import '../models/provider_profile.dart';
import '../models/provider_service_item.dart';
import '../services/provider_service.dart';
import '../services/provider_services_service.dart';
import 'service_application_screen.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  final ProviderService _providerService = ProviderService();
  final ProviderServicesService _servicesService = ProviderServicesService();
  final TextEditingController _skillInputController = TextEditingController();

  late Future<void> _initialLoadFuture;

  ProviderProfile? _profile;
  List<ProviderServiceItem> _services = const [];
  List<String> _skills = <String>[];

  bool _servicesLoading = false;
  bool _skillsSaving = false;

  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialLoadFuture = _loadData();
  }

  @override
  void dispose() {
    _skillInputController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _servicesLoading = true;
    });

    try {
      final values = await Future.wait<dynamic>([
        _providerService.getProfile(),
        _servicesService.getServices(),
      ]);

      if (!mounted) return;

      final profile = values[0] as ProviderProfile;
      final services = values[1] as List<ProviderServiceItem>;

      setState(() {
        _profile = profile;
        _services = services;
        _skills = List<String>.from(profile.skills);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _servicesLoading = false;
        });
      }
    }
  }

  List<String> get _allocatedExpertise {
    final profile = _profile;
    if (profile == null) return const [];

    final merged = [
      ...profile.expertise,
      ...profile.skills,
    ].map((item) => item.trim()).where((item) => item.isNotEmpty);

    return merged.toSet().toList();
  }

  List<ProviderServiceItem> get _applicableServices {
    final expertiseSet = _allocatedExpertise.map(_normalize).toSet();
    return _services.where((service) => !expertiseSet.contains(_normalize(service.name))).toList();
  }

  bool get _skillsDirty {
    final current = List<String>.from(_profile?.skills ?? const [])..sort();
    final draft = List<String>.from(_skills)..sort();
    if (current.length != draft.length) {
      return true;
    }
    for (var i = 0; i < current.length; i++) {
      if (current[i] != draft[i]) {
        return true;
      }
    }
    return false;
  }

  String _normalize(String value) => value.trim().toLowerCase();

  String _statusLabel(String status) {
    return switch (status) {
      'VERIFIED' => 'Verified',
      'UNDER_REVIEW' => 'Under Review',
      'REJECTED' => 'Rejected',
      _ => 'Not Applied',
    };
  }

  Color _statusColor(String status) {
    return switch (status) {
      'VERIFIED' => const Color(0xFF15803D),
      'UNDER_REVIEW' => const Color(0xFFB45309),
      'REJECTED' => const Color(0xFFB91C1C),
      _ => const Color(0xFF475569),
    };
  }

  Color _statusBgColor(String status) {
    return switch (status) {
      'VERIFIED' => const Color(0xFFDCFCE7),
      'UNDER_REVIEW' => const Color(0xFFFEF3C7),
      'REJECTED' => const Color(0xFFFEE2E2),
      _ => const Color(0xFFF1F5F9),
    };
  }

  void _setMessage(String text) {
    setState(() {
      _message = text;
      _error = null;
    });
  }

  void _setError(Object error) {
    setState(() {
      _error = error.toString().replaceFirst('Exception: ', '');
      _message = null;
    });
  }

  Future<void> _openServiceApplicationScreen(ProviderServiceItem service) async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ServiceApplicationScreen(service: service),
      ),
    );

    if (submitted == true) {
      await _loadData();
      if (!mounted) return;
      _setMessage('${service.name} submitted for admin verification');
    }
  }

  void _addSkill() {
    final value = _skillInputController.text.trim();
    if (value.isEmpty) {
      _setError('Skill cannot be empty');
      return;
    }

    if (_skills.where((item) => _normalize(item) == _normalize(value)).isNotEmpty) {
      _setError('This skill already exists');
      return;
    }

    setState(() {
      _skills = [..._skills, value];
      _skillInputController.clear();
      _error = null;
    });
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills = _skills.where((item) => item != skill).toList();
    });
  }

  Future<void> _saveSkills() async {
    setState(() {
      _skillsSaving = true;
      _error = null;
      _message = null;
    });

    try {
      await _servicesService.updateSkills(_skills);
      await _loadData();
      if (!mounted) return;
      _setMessage('Skills updated successfully');
    } catch (error) {
      if (!mounted) return;
      _setError(error);
    } finally {
      if (mounted) {
        setState(() {
          _skillsSaving = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadData();
    if (!mounted) return;
    setState(() {
      _message = 'Skills refreshed';
      _error = null;
    });
  }

  Widget _serviceCard(ProviderServiceItem service) {
    final status = service.submission?.status ?? '';
    final canApply = status != 'VERIFIED' && status != 'UNDER_REVIEW';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;

            Widget actionButtons({required bool fullWidth}) {
              final applyLabel = status == 'VERIFIED'
                  ? 'Verified'
                  : status == 'UNDER_REVIEW'
                      ? 'Under Review'
                      : status == 'REJECTED'
                          ? 'Re-Submit'
                          : 'Apply';

              final applyButton = FilledButton.tonal(
                onPressed: canApply ? () => _openServiceApplicationScreen(service) : null,
                child: Text(applyLabel),
              );

              if (!fullWidth) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    applyButton,
                  ],
                );
              }

              return SizedBox(width: double.infinity, child: applyButton);
            }

            final details = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    fontSize: 21,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  service.description.isEmpty ? 'No description available' : service.description,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 14.5),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(_statusLabel(status)),
                      backgroundColor: _statusBgColor(status),
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Chip(
                      label: Text('Checklist: ${service.checklist.length}'),
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    Chip(
                      label: Text('Docs: ${service.requiredDocuments.length}'),
                      backgroundColor: const Color(0xFFF8FAFC),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ],
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  details,
                  const SizedBox(height: 10),
                  actionButtons(fullWidth: true),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: details),
                const SizedBox(width: 12),
                actionButtons(fullWidth: false),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialLoadFuture,
      builder: (context, snapshot) {
        final profile = _profile;
        if (snapshot.connectionState != ConnectionState.done && profile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (profile == null) {
          return Center(
            child: Text(
              _error ?? 'Services not available.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width >= 1100 ? 24 : 12,
              10,
              MediaQuery.of(context).size.width >= 1100 ? 24 : 12,
              16,
            ),
            children: [
            if (_message != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F9EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7E3B8)),
                ),
                child: Text(_message!, style: const TextStyle(color: Color(0xFF166534))),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B))),
              ),
            ],
            if (_servicesLoading) ...[
              const SizedBox(height: 12),
              const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Loading services...'),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Allocated Expertise',
                      style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Expertise assigned to this service provider profile',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 10),
                    if (_allocatedExpertise.isEmpty)
                      const Text(
                        'No expertise has been allocated yet.',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _allocatedExpertise
                            .map(
                              (item) => Chip(
                                avatar: const Icon(Icons.build_outlined, size: 16),
                                label: Text(item),
                                backgroundColor: const Color(0xFFE6F6F3),
                                side: const BorderSide(color: Color(0xFFB7E3DB)),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_applicableServices.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No new skills available for application. Already assigned expertise is hidden.',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              )
            else
              ..._applicableServices.map(
                (service) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _serviceCard(service),
                ),
              ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 680;
                final saveButton = FilledButton.icon(
                  onPressed: _skillsSaving || !_skillsDirty ? null : _saveSkills,
                  icon: _skillsSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_skillsSaving ? 'Saving...' : 'Save Skills'),
                );

                return compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Custom Skills',
                            style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Add specific skills for better matching',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(width: double.infinity, child: saveButton),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Custom Skills',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    fontSize: 24,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Add specific skills for better matching',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          saveButton,
                        ],
                      );
              },
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 620;
                final input = TextField(
                  controller: _skillInputController,
                  decoration: const InputDecoration(
                    hintText: 'e.g., PCB Repair, Thermostat Replacement',
                    prefixIcon: Icon(Icons.build_outlined),
                  ),
                  onChanged: (_) {
                    if (_error != null) {
                      setState(() {
                        _error = null;
                      });
                    }
                  },
                  onSubmitted: (_) => _addSkill(),
                );

                final addButton = FilledButton.icon(
                  onPressed: _addSkill,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                );

                if (compact) {
                  return Column(
                    children: [
                      input,
                      const SizedBox(height: 10),
                      SizedBox(width: double.infinity, child: addButton),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: input),
                    const SizedBox(width: 10),
                    addButton,
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            if (_skills.isEmpty)
              const Text(
                'No custom skills added yet.',
                style: TextStyle(color: Color(0xFF94A3B8)),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _skills
                    .map(
                      (skill) => Chip(
                        label: Text(skill),
                        onDeleted: () => _removeSkill(skill),
                        avatar: const Icon(Icons.build_outlined, size: 16),
                        backgroundColor: const Color(0xFFD7ECE9),
                        side: const BorderSide(color: Color(0xFFA4D6CE)),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
