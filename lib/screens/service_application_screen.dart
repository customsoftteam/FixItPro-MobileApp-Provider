import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/provider_service_item.dart';
import '../services/api_client.dart';
import '../services/provider_services_service.dart';

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

class ServiceApplicationScreen extends StatefulWidget {
  const ServiceApplicationScreen({
    super.key,
    required this.service,
  });

  final ProviderServiceItem service;

  @override
  State<ServiceApplicationScreen> createState() => _ServiceApplicationScreenState();
}

class _ServiceApplicationScreenState extends State<ServiceApplicationScreen> {
  final ProviderServicesService _servicesService = ProviderServicesService();

  late final List<_ChecklistDraft> _checklistDraft;
  final Map<int, PlatformFile> _documentFiles = <int, PlatformFile>{};

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    final submissionChecklist = widget.service.submission?.checklist ?? const <ProviderServiceChecklistEntry>[];
    _checklistDraft = widget.service.checklist
        .map((item) {
          final matched = submissionChecklist.where((entry) => _normalize(entry.item) == _normalize(item));
          final existing = matched.isEmpty ? null : matched.first;
          return _ChecklistDraft(
            item: item,
            satisfied: existing?.satisfied ?? false,
            note: existing?.note ?? '',
          );
        })
        .toList();
  }

  String _normalize(String value) => value.trim().toLowerCase();

  String? _mimeTypeForFile(PlatformFile file) {
    final extension = (file.extension ?? file.name.split('.').last).toLowerCase();
    return switch (extension) {
      'pdf' => 'application/pdf',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };
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
    final service = widget.service;

    final unsatisfied = _checklistDraft.where((entry) => !entry.satisfied);
    if (service.checklist.isNotEmpty && unsatisfied.isNotEmpty) {
      setState(() {
        _error = 'Please mark checklist item as satisfied: ${unsatisfied.first.item}';
      });
      return;
    }

    for (var i = 0; i < service.requiredDocuments.length; i++) {
      if (_documentFiles[i] == null) {
        setState(() {
          _error = 'Please upload required document: ${service.requiredDocuments[i]}';
        });
        return;
      }

      if (_documentFiles[i]!.bytes == null) {
        setState(() {
          _error = 'Unable to read document bytes for ${service.requiredDocuments[i]}';
        });
        return;
      }

      if (_mimeTypeForFile(_documentFiles[i]!) == null) {
        setState(() {
          _error = 'Only image or PDF files are allowed.';
        });
        return;
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final docs = <ApiMultipartFile>[];
      for (var i = 0; i < service.requiredDocuments.length; i++) {
        final file = _documentFiles[i]!;
        final mimeType = _mimeTypeForFile(file);
        docs.add(
          ApiMultipartFile(
            field: 'documents',
            filename: file.name,
            bytes: file.bytes!,
            mimeType: mimeType,
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

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingDocs = widget.service.submission?.documents ?? const <ProviderServiceDocument>[];

    ProviderServiceDocument? findExistingDoc(String docName) {
      final matches = existingDocs.where((doc) => _normalize(doc.name) == _normalize(docName));
      return matches.isEmpty ? null : matches.first;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F8F7B),
        foregroundColor: Colors.white,
        title: Text(widget.service.name),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 1000 ? 24.0 : 12.0;
            return ListView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 20),
              children: [
                if (widget.service.description.isNotEmpty)
                  Text(
                    widget.service.description,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                if (widget.service.description.isNotEmpty) const SizedBox(height: 14),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B))),
                  ),
                  const SizedBox(height: 14),
                ],
                const Text(
                  'Admin Checklist',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 18),
                ),
                const SizedBox(height: 10),
                if (_checklistDraft.isEmpty)
                  const Text(
                    'No checklist required for this service.',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  )
                else
                  ...List.generate(_checklistDraft.length, (index) {
                    final entry = _checklistDraft[index];
                    final noteController = TextEditingController(text: entry.note)
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: entry.note.length),
                      );

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
                              setState(() {
                                entry.satisfied = value == true;
                              });
                            },
                          ),
                          TextField(
                            decoration: const InputDecoration(labelText: 'Note (optional)'),
                            controller: noteController,
                            onChanged: (value) {
                              entry.note = value;
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 12),
                const Text(
                  'Required Documents',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0F172A), fontSize: 18),
                ),
                const SizedBox(height: 10),
                if (widget.service.requiredDocuments.isEmpty)
                  const Text(
                    'No documents required for this service.',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  )
                else
                  ...List.generate(widget.service.requiredDocuments.length, (index) {
                    final docName = widget.service.requiredDocuments[index];
                    final selected = _documentFiles[index];
                    final existing = findExistingDoc(docName);

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
                            onPressed: () => _pickDocument(index),
                            icon: const Icon(Icons.upload_file_outlined),
                            label: Text(selected?.name ?? 'Upload Document'),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting || widget.service.submission?.status == 'VERIFIED'
                        ? null
                        : _submitService,
                    child: Text(_submitting ? 'Submitting...' : 'Submit for Verification'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
