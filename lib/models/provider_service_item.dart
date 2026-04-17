class ProviderServiceItem {
  const ProviderServiceItem({
    required this.id,
    required this.name,
    required this.description,
    required this.checklist,
    required this.requiredDocuments,
    required this.submission,
  });

  final String id;
  final String name;
  final String description;
  final List<String> checklist;
  final List<String> requiredDocuments;
  final ProviderServiceSubmission? submission;
}

class ProviderServiceSubmission {
  const ProviderServiceSubmission({
    required this.status,
    required this.checklist,
    required this.documents,
  });

  final String status;
  final List<ProviderServiceChecklistEntry> checklist;
  final List<ProviderServiceDocument> documents;
}

class ProviderServiceChecklistEntry {
  const ProviderServiceChecklistEntry({
    required this.item,
    required this.satisfied,
    required this.note,
  });

  final String item;
  final bool satisfied;
  final String note;
}

class ProviderServiceDocument {
  const ProviderServiceDocument({
    required this.name,
    required this.url,
  });

  final String name;
  final String url;
}
