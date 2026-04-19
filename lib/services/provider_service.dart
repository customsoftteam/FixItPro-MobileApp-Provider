import '../models/provider_profile.dart';
import 'api_client.dart';

class ProviderService {
  Future<ProviderProfile> getProfile() async {
    final response = await ApiClient.instance.get('/providers/me');
    final provider = Map<String, dynamic>.from(response['provider'] as Map? ?? {});

    final availability = Map<String, dynamic>.from(provider['availability'] as Map? ?? {});
    final vehicleDetails = Map<String, dynamic>.from(provider['vehicleDetails'] as Map? ?? {});
    final bankDetails = Map<String, dynamic>.from(provider['bankDetails'] as Map? ?? {});
    final documents = Map<String, dynamic>.from(provider['documents'] as Map? ?? {});
    final location = Map<String, dynamic>.from(provider['location'] as Map? ?? {});

    final availabilitySlots = (availability['slots'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (slot) => AvailabilitySlot(
            start: slot['start']?.toString() ?? '',
            end: slot['end']?.toString() ?? '',
          ),
        )
        .where((slot) => slot.start.isNotEmpty || slot.end.isNotEmpty)
        .toList();

    final slots = availabilitySlots
        .map((slot) => '${slot.start} - ${slot.end}'.trim())
        .where((value) => value != '-')
        .toList();

    final profile = ProviderProfile(
      name: provider['name']?.toString().isNotEmpty == true ? provider['name'].toString() : 'Provider',
      mobile: provider['mobile']?.toString() ?? '',
      email: provider['email']?.toString() ?? '',
      city: _resolveCity(provider),
      status: provider['status']?.toString() ?? 'INACTIVE',
      rating: 4.8,
      completedJobs: int.tryParse(provider['completedJobs']?.toString() ?? '') ?? 0,
      skills: (provider['skills'] as List? ?? const []).map((skill) => skill.toString()).toList(),
      expertise: (provider['expertise'] as List? ?? const []).map((item) => item.toString()).toList(),
      workingDays: (availability['workingDays'] as List? ?? const []).map((day) => day.toString()).toList(),
      timeSlots: slots,
      availabilitySlots: availabilitySlots,
      onboardingCompleted: provider['onboardingCompleted'] == true,
      experience: provider['experience']?.toString() ?? '',
      maritalStatus: provider['maritalStatus']?.toString() ?? '',
      emergencyContact: provider['emergencyContact']?.toString() ?? '',
      referralName: provider['referralName']?.toString() ?? '',
      hasVehicle: provider['hasVehicle'] == true,
      vehicleDetails: ProviderVehicleDetails(
        type: vehicleDetails['type']?.toString() ?? '',
        model: vehicleDetails['model']?.toString() ?? '',
        registrationNumber: vehicleDetails['registrationNumber']?.toString() ?? '',
      ),
      bankDetails: ProviderBankDetails(
        accountHolderName: bankDetails['accountHolderName']?.toString() ?? '',
        bankName: bankDetails['bankName']?.toString() ?? '',
        accountNumber: bankDetails['accountNumber']?.toString() ?? '',
        ifscCode: bankDetails['ifscCode']?.toString() ?? '',
        branchName: bankDetails['branchName']?.toString() ?? '',
      ),
      documents: ProviderDocuments(
        aadharFrontUrl: documents['aadharFrontUrl']?.toString() ?? '',
        aadharBackUrl: documents['aadharBackUrl']?.toString() ?? '',
        panUrl: documents['panUrl']?.toString() ?? '',
      ),
      profileImage: provider['profileImage']?.toString() ?? '',
      latitude: _asDouble(location['latitude']),
      longitude: _asDouble(location['longitude']),
    );

    return profile;
  }

  Future<void> updateAvailability({
    required List<String> workingDays,
    required List<AvailabilitySlot> slots,
  }) async {
    await ApiClient.instance.put(
      '/providers/availability',
      body: {
        'workingDays': workingDays,
        'slots': slots
            .map(
              (slot) => {
                'start': slot.start,
                'end': slot.end,
              },
            )
            .toList(),
      },
    );
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? emergencyContact,
    String? referralName,
    String? city,
    double? latitude,
    double? longitude,
    String? experience,
    String? maritalStatus,
    bool? hasVehicle,
  }) async {
    final body = <String, dynamic>{};

    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (emergencyContact != null) body['emergencyContact'] = emergencyContact;
    if (referralName != null) body['referralName'] = referralName;
    if (experience != null) body['experience'] = experience;
    if (maritalStatus != null) body['maritalStatus'] = maritalStatus;
    if (hasVehicle != null) body['hasVehicle'] = hasVehicle;

    final hasCity = city != null && city.trim().isNotEmpty;
    final hasCoordinates = latitude != null && longitude != null;
    if (hasCity || hasCoordinates) {
      body['location'] = {
        if (hasCity) 'city': city,
        if (hasCoordinates) 'latitude': latitude,
        if (hasCoordinates) 'longitude': longitude,
      };

      if (hasCity) {
        body['city'] = city;
      }
    }

    if (body.isEmpty) {
      return;
    }

    await ApiClient.instance.put('/providers/me', body: body);
  }

  String _resolveCity(Map<String, dynamic> provider) {
    final location = provider['location'];
    if (location is Map && location['city'] != null) {
      return location['city'].toString();
    }

    return 'Bengaluru';
  }

  double? _asDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }
}
