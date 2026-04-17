import 'package:intl/intl.dart';

import '../models/booking_item.dart';
import 'api_client.dart';

class BookingService {
  BookingService._();

  static final BookingService instance = BookingService._();

  Future<List<BookingItem>> getBookings() async {
    final response = await ApiClient.instance.get('/bookings');
    final bookings = (response['bookings'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => _parseBooking(Map<String, dynamic>.from(item)))
        .toList();

    return bookings;
  }

  Future<void> acceptBooking(String bookingId) async {
    await ApiClient.instance.patch('/bookings/$bookingId/accept');
  }

  Future<void> rejectBooking(String bookingId) async {
    await ApiClient.instance.patch('/bookings/$bookingId/reject');
  }

  Future<void> startService(String bookingId) async {
    await ApiClient.instance.patch('/bookings/$bookingId/start');
  }

  BookingItem _parseBooking(Map<String, dynamic> data) {
    final scheduledDate = data['scheduledDate'];
    final createdDate = data['createdAt'];
    final startDate = data['serviceStartTime'];
    final serviceId = data['serviceId'];
    final userId = data['userId'];
    final pricing = data['pricing'];

    return BookingItem(
      id: data['bookingId']?.toString() ?? 'N/A',
      serviceName: _readServiceName(data, serviceId),
      customerName: _readCustomerName(data, userId),
      status: _normalizeStatus(data['status']?.toString() ?? 'pending'),
      scheduledAt: _parseDate(scheduledDate) ?? _parseDate(data['scheduledAt']) ?? DateTime.now(),
      address: _parseAddress(data['address']) ?? data['customerAddress']?.toString() ?? 'Address not available',
      amount: _readAmount(data, pricing),
      completedSteps: _estimateCompletedSteps(data['status']?.toString() ?? 'pending'),
      steps: _buildSteps(data['status']?.toString() ?? 'pending'),
      customerMobile: _readCustomerMobile(data, userId),
      notes: data['notes']?.toString() ?? data['description']?.toString() ?? '',
      paymentMethod: _readPaymentMethod(data),
      paymentStatus: _readPaymentStatus(data),
      createdAt: _parseDate(createdDate) ?? DateTime.now(),
      serviceStartTime: _parseDate(startDate),
      serviceEndTime: null,
    );
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _readServiceName(Map<String, dynamic> data, dynamic serviceId) {
    if (data['serviceType'] != null && data['serviceType'].toString().isNotEmpty) {
      return data['serviceType'].toString();
    }

    if (serviceId is Map) {
      final name = serviceId['name']?.toString();
      if (name != null && name.isNotEmpty) {
        return name;
      }
      final serviceType = serviceId['serviceType']?.toString();
      if (serviceType != null && serviceType.isNotEmpty) {
        return serviceType;
      }
      final product = serviceId['productId'];
      if (product is Map && product['name'] != null) {
        return product['name'].toString();
      }
    }

    final productId = data['productId'];
    if (productId is Map) {
      final productName = productId['name']?.toString();
      if (productName != null && productName.isNotEmpty) {
        return productName;
      }
    }

    return 'Unknown Service';
  }

  double _readAmount(Map<String, dynamic> data, dynamic pricing) {
    final directAmount = (data['amount'] as num?)?.toDouble();
    if (directAmount != null && directAmount > 0) {
      return directAmount;
    }

    if (pricing is Map) {
      final totalAmount = (pricing['totalAmount'] as num?)?.toDouble();
      if (totalAmount != null && totalAmount > 0) {
        return totalAmount;
      }

      final servicePrice = (pricing['servicePrice'] as num?)?.toDouble();
      if (servicePrice != null && servicePrice > 0) {
        return servicePrice;
      }
    }

    return 0;
  }

  String _readCustomerName(Map<String, dynamic> data, dynamic userId) {
    if (data['customerName'] != null && data['customerName'].toString().isNotEmpty) {
      return data['customerName'].toString();
    }

    if (userId is Map) {
      final name = userId['name']?.toString();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }

    return 'Customer';
  }

  String _readCustomerMobile(Map<String, dynamic> data, dynamic userId) {
    if (data['customerMobile'] != null && data['customerMobile'].toString().isNotEmpty) {
      return data['customerMobile'].toString();
    }

    if (userId is Map) {
      final mobile = userId['mobile']?.toString();
      if (mobile != null && mobile.isNotEmpty) {
        return mobile;
      }
    }

    return 'N/A';
  }

  String _readPaymentMethod(Map<String, dynamic> data) {
    final payment = data['payment'];
    if (payment is Map && payment['method'] != null) {
      return payment['method'].toString();
    }

    return 'N/A';
  }

  String _readPaymentStatus(Map<String, dynamic> data) {
    final payment = data['payment'];
    if (payment is Map && payment['status'] != null) {
      return payment['status'].toString();
    }

    return 'pending';
  }

  String _normalizeStatus(String status) {
    final normalized = status.toLowerCase().replaceAll(' ', '_');
    return normalized;
  }

  String? _parseAddress(dynamic addressData) {
    if (addressData is Map) {
      final street = addressData['street']?.toString() ?? '';
      final city = addressData['city']?.toString() ?? '';
      final area = addressData['area']?.toString() ?? '';
      final fullAddress = addressData['fullAddress']?.toString() ?? '';
      final parts = [fullAddress, street, area, city].where((s) => s.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        return parts.join(', ');
      }
    }

    if (addressData != null && addressData.toString().isNotEmpty) {
      return addressData.toString();
    }

    return null;
  }

  int _estimateCompletedSteps(String status) {
    return switch (status.toLowerCase()) {
      'pending' || 'assigned' => 1,
      'accepted' => 2,
      'in_progress' || 'otp_sent' => 3,
      'completed' => 4,
      _ => 1,
    };
  }

  List<String> _buildSteps(String status) {
    return switch (status.toLowerCase()) {
      'assigned' || 'pending' => ['Assigned', 'Accepted', 'Started', 'Completed'],
      'accepted' => ['Assigned', 'Accepted', 'Started', 'Completed'],
      'in_progress' || 'otp_sent' => ['Assigned', 'Accepted', 'Started', 'OTP Sent', 'Completed'],
      'completed' => ['Assigned', 'Accepted', 'Started', 'Completed'],
      'rejected' || 'cancelled' => ['Assigned', 'Rejected'],
      _ => ['Assigned', 'Accepted', 'Started', 'Completed'],
    };
  }
}
