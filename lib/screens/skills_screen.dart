import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/provider_profile.dart';
import '../models/provider_service_item.dart';
import '../services/api_client.dart';
import '../services/provider_service.dart';
import '../services/provider_services_service.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _ChecklistDraft {
  _ChecklistDraft({
    required this.item,
    required this.satisfied,
    required this.note,
  });

  final String item;
  bool satisfied;
  String note;
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
  bool _serviceSubmitting = false;

  String? _message;
  String? _error;

  ProviderServiceItem? _activeService;
  List<_ChecklistDraft> _checklistDraft = <_ChecklistDraft>[];
  final Map<int, PlatformFile> _documentFiles = <int, PlatformFile>{};

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

  int get _verifiedCount {
    return _services.where((service) => service.submission?.status == 'VERIFIED').length;
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

  void _openServiceDialog(ProviderServiceItem service) {
    final submissionChecklist = service.submission?.checklist ?? const <ProviderServiceChecklistEntry>[];

    final nextChecklist = service.checklist
        .map(
          (item) {
            final matched = submissionChecklist.where((entry) => _normalize(entry.item) == _normalize(item));
            final existing = matched.isEmpty ? null : matched.first;
            return _ChecklistDraft(
              item: item,
              satisfied: existing?.satisfied ?? false,
              note: existing?.note ?? '',
            );
          },
        )
        .toList();

    setState(() {
      _activeService = service;
      _checklistDraft = nextChecklist;
      _documentFiles.clear();
      _error = null;
      _message = null;
    });
  }

  void _closeServiceDialog() {
    setState(() {
      _activeService = null;
      _checklistDraft = <_ChecklistDraft>[];
      _documentFiles.clear();
    });
  }

  Future<void> _pickDocument(int index) async {
    final picked = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );

    if (picked == null || picked.files.isEmpty) {
      return;
    }

    setState(() {
      _documentFiles[index] = picked.files.first;
    });
  }

  Future<void> _submitService() async {
    final service = _activeService;
    if (service == null) {
      return;
    }

    final unsatisfied = _checklistDraft.where((entry) => !entry.satisfied);
    if (service.checklist.isNotEmpty && unsatisfied.isNotEmpty) {
      _setError('Please mark checklist item as satisfied: ${unsatisfied.first.item}');
      return;
    }

    for (var i = 0; i < service.requiredDocuments.length; i++) {
      if (_documentFiles[i] == null) {
        _setError('Please upload required document: ${service.requiredDocuments[i]}');
        return;
      }

      if (_documentFiles[i]!.bytes == null) {
        _setError('Unable to read document bytes for ${service.requiredDocuments[i]}');
        return;
      }
    }

    setState(() {
      _serviceSubmitting = true;
      _error = null;
      _message = null;
    });

    try {
      final docs = <ApiMultipartFile>[];
      for (var i = 0; i < service.requiredDocuments.length; i++) {
        final file = _documentFiles[i]!;
        docs.add(
          ApiMultipartFile(
            field: 'documents',
            filename: file.name,
            bytes: file.bytes!,
          ),
        );
      }

      await _servicesService.submitForVerification(
        serviceId: service.id,
        checklist: _checklistDraft
            .map(
              (entry) => ProviderServiceChecklistEntry(
                item: entry.item,
                satisfied: entry.satisfied,
                note: entry.note,
              ),
            )
            .toList(),
        documents: docs,
      );

      await _loadData();
      if (!mounted) return;
      _closeServiceDialog();
      _setMessage('${service.name} submitted for admin verification');
    } catch (error) {
      if (!mounted) return;
      _setError(error);
    } finally {
      if (mounted) {
        setState(() {
          _serviceSubmitting = false;
        });
      }
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

  Widget _serviceCard(ProviderServiceItem service) {
    final status = service.submission?.status ?? '';
    final canApply = status != 'VERIFIED' && status != 'UNDER_REVIEW';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
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
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FilledButton.tonal(
                      onPressed: canApply ? () => _openServiceDialog(service) : null,
                      child: Text(
                        status == 'VERIFIED'
                            ? 'Verified'
                            : status == 'UNDER_REVIEW'
                                ? 'Under Review'
                                : status == 'REJECTED'
                                    ? 'Re-Submit'
                                    : 'Apply',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _openServiceDialog(service),
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showServiceDialog(ProviderServiceItem service) async {
    _openServiceDialog(service);
    await showDialog<void>(
      context: context,
      barrierDismissible: !_serviceSubmitting,
      builder: (context) {
        return StatefulBuilder(
          builder: (dialogContext, dialogSetState) {
            final active = _activeService;
            if (active == null) {
              return const SizedBox.shrink();
            }

            final existingDocs = active.submission?.documents ?? const <ProviderServiceDocument>[];

            ProviderServiceDocument? _findExistingDoc(String docName) {
              final matches = existingDocs.where(
                (doc) => _normalize(doc.name) == _normalize(docName),
              );
              return matches.isEmpty ? null : matches.first;
            }

            return AlertDialog(
              title: Text(active.name, style: const TextStyle(fontWeight: FontWeight.w800)),
              content: SizedBox(
                width: 680,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        active.description.isEmpty ? 'No description available' : active.description,
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text(
                        'Admin Checklist',
                        style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      if (_checklistDraft.isEmpty)
                        const Text(
                          'No checklist required for this service.',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        )
                      else
                        ...List.generate(_checklistDraft.length, (index) {
                          final entry = _checklistDraft[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: entry.satisfied,
                                  title: Text(entry.item),
                                  onChanged: (value) {
                                    dialogSetState(() {
                                      entry.satisfied = value == true;
                                    });
                                  },
                                ),
                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Note (optional)',
                                  ),
                                  controller: TextEditingController(text: entry.note)
                                    ..selection = TextSelection.fromPosition(
                                      TextPosition(offset: entry.note.length),
                                    ),
                                  onChanged: (value) {
                                    entry.note = value;
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 10),
                      const Text(
                        'Required Documents',
                        style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      if (active.requiredDocuments.isEmpty)
                        const Text(
                          'No documents required for this service.',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        )
                      else
                        ...List.generate(active.requiredDocuments.length, (index) {
                          final docName = active.requiredDocuments[index];
                          final selected = _documentFiles[index];
                          final existing = _findExistingDoc(docName);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(docName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                if (existing != null)
                                  const Text(
                                    'Previously uploaded file available',
                                    style: TextStyle(color: Color(0xFF0F766E), fontSize: 13.5),
                                  ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await _pickDocument(index);
                                    dialogSetState(() {});
                                  },
                                  icon: const Icon(Icons.upload_file_outlined),
                                  label: Text(selected?.name ?? 'Upload Document'),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _serviceSubmitting
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                          _closeServiceDialog();
                        },
                  child: const Text('Close'),
                ),
                FilledButton(
                  onPressed: _serviceSubmitting || active.submission?.status == 'VERIFIED'
                      ? null
                      : () async {
                          await _submitService();
                          if (!mounted) return;
                          if (_activeService == null) {
                            Navigator.of(dialogContext).pop();
                          } else {
                            dialogSetState(() {});
                          }
                        },
                  child: Text(_serviceSubmitting ? 'Submitting...' : 'Submit for Verification'),
                ),
              ],
            );
          },
        );
      },
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

        return ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Services & Skills', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 6),
                      const Text(
                        'Apply for services, complete checklist, and upload required documents',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Chip(
                  label: Text('Verified Services: $_verifiedCount'),
                  backgroundColor: const Color(0xFFDCFCE7),
                  side: BorderSide.none,
                  labelStyle: const TextStyle(color: Color(0xFF166534), fontWeight: FontWeight.w700),
                ),
              ],
            ),
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
            ..._services.map(
              (service) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _showServiceDialog(service),
                  child: _serviceCard(service),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom Skills',
                        style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 24),
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
                FilledButton.icon(
                  onPressed: _skillsSaving || !_skillsDirty ? null : _saveSkills,
                  icon: _skillsSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_skillsSaving ? 'Saving...' : 'Save Skills'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
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
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _addSkill,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
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
        );
      },
    );
  }
}
