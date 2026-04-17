class BookingItem {
  const BookingItem({
    required this.backendId,
    required this.id,
    required this.serviceName,
    required this.customerName,
    required this.status,
    required this.scheduledAt,
    required this.address,
    required this.amount,
    required this.completedSteps,
    required this.steps,
    this.customerMobile = '',
    this.notes = '',
    this.paymentMethod = 'Cash',
    this.paymentStatus = 'pending',
    this.createdAt,
    this.serviceStartTime,
    this.serviceEndTime,
    this.pausedDurationSeconds = 0,
    this.pauseStartedAt,
  });

  final String backendId;
  final String id;
  final String serviceName;
  final String customerName;
  final String status;
  final DateTime scheduledAt;
  final String address;
  final double amount;
  final int completedSteps;
  final List<String> steps;
  final String customerMobile;
  final String notes;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime? createdAt;
  final DateTime? serviceStartTime;
  final DateTime? serviceEndTime;
  final int pausedDurationSeconds;
  final DateTime? pauseStartedAt;

  BookingItem copyWith({
    String? backendId,
    String? id,
    String? serviceName,
    String? customerName,
    String? status,
    DateTime? scheduledAt,
    String? address,
    double? amount,
    int? completedSteps,
    List<String>? steps,
    String? customerMobile,
    String? notes,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? createdAt,
    DateTime? serviceStartTime,
    DateTime? serviceEndTime,
    int? pausedDurationSeconds,
    DateTime? pauseStartedAt,
  }) {
    return BookingItem(
      backendId: backendId ?? this.backendId,
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      customerName: customerName ?? this.customerName,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      address: address ?? this.address,
      amount: amount ?? this.amount,
      completedSteps: completedSteps ?? this.completedSteps,
      steps: steps ?? this.steps,
      customerMobile: customerMobile ?? this.customerMobile,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      serviceStartTime: serviceStartTime ?? this.serviceStartTime,
      serviceEndTime: serviceEndTime ?? this.serviceEndTime,
      pausedDurationSeconds: pausedDurationSeconds ?? this.pausedDurationSeconds,
      pauseStartedAt: pauseStartedAt ?? this.pauseStartedAt,
    );
  }

  double get progress {
    if (steps.isEmpty) {
      return 0;
    }
    return completedSteps / steps.length;
  }
}
