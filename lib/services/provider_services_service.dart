import 'dart:convert';

import '../models/provider_service_item.dart';
import 'api_client.dart';

class ProviderServicesService {
  Future<List<ProviderServiceItem>> getServices() async {
    final response = await ApiClient.instance.get('/providers/services');
    final services = (response['services'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _mapService(Map<String, dynamic>.from(item)))
        .toList();

    return services;
  }

  Future<void> submitForVerification({
    required String serviceId,
    required List<ProviderServiceChecklistEntry> checklist,
    required List<ApiMultipartFile> documents,
  }) async {
    final checklistJson = jsonEncode(
      checklist
          .map(
            (entry) => {
              'item': entry.item,
              'satisfied': entry.satisfied,
              'note': entry.note,
            },
          )
          .toList(),
    );

    await ApiClient.instance.postMultipart(
      '/providers/services/$serviceId/submit',
      fields: {'checklist': checklistJson},
      files: documents,
    );
  }

  Future<void> updateSkills(List<String> skills) async {
    await ApiClient.instance.put('/providers/skills', body: {'skills': skills});
  }

  ProviderServiceItem _mapService(Map<String, dynamic> data) {
    final submissionRaw = data['providerSubmission'];
    ProviderServiceSubmission? submission;

    if (submissionRaw is Map) {
      final submissionMap = Map<String, dynamic>.from(submissionRaw);
      submission = ProviderServiceSubmission(
        status: submissionMap['status']?.toString() ?? '',
        checklist: (submissionMap['checklist'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (entry) => ProviderServiceChecklistEntry(
                item: entry['item']?.toString() ?? '',
                satisfied: entry['satisfied'] == true,
                note: entry['note']?.toString() ?? '',
              ),
            )
            .toList(),
        documents: (submissionMap['documents'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (doc) => ProviderServiceDocument(
                name: doc['name']?.toString() ?? '',
                url: doc['url']?.toString() ?? '',
              ),
            )
            .toList(),
      );
    }

    return ProviderServiceItem(
      id: data['_id']?.toString() ?? '',
      name: data['name']?.toString().isNotEmpty == true ? data['name'].toString() : 'Service',
      description: data['description']?.toString() ?? '',
      checklist: (data['checklist'] as List? ?? const []).map((item) => item.toString()).toList(),
      requiredDocuments: (data['requiredDocuments'] as List? ?? const []).map((item) => item.toString()).toList(),
      submission: submission,
    );
  }
}
