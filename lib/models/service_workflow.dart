class ServiceWorkflowStep {
  const ServiceWorkflowStep({
    required this.order,
    required this.title,
    this.description = '',
  });

  final int order;
  final String title;
  final String description;

  factory ServiceWorkflowStep.fromMap(Map<String, dynamic> map, int index) {
    return ServiceWorkflowStep(
      order: (map['order'] as num?)?.toInt() ?? index + 1,
      title: map['title']?.toString() ?? 'Step ${index + 1}',
      description: map['description']?.toString() ?? '',
    );
  }
}

class ServiceWorkflowData {
  const ServiceWorkflowData({
    required this.steps,
    required this.completedSteps,
    required this.status,
    required this.serviceDurationMinutes,
    this.serviceStartTime,
    this.pausedDurationSeconds = 0,
    this.pauseStartedAt,
  });

  final List<ServiceWorkflowStep> steps;
  final List<int> completedSteps;
  final String status;
  final DateTime? serviceStartTime;
  final int pausedDurationSeconds;
  final DateTime? pauseStartedAt;
  final int serviceDurationMinutes;
}
