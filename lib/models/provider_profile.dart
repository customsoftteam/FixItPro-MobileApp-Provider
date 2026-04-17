class ProviderProfile {
  const ProviderProfile({
    required this.name,
    required this.mobile,
    required this.email,
    required this.city,
    required this.status,
    required this.rating,
    required this.completedJobs,
    required this.skills,
    required this.expertise,
    required this.workingDays,
    required this.timeSlots,
    required this.availabilitySlots,
    required this.onboardingCompleted,
    required this.experience,
    required this.maritalStatus,
    required this.emergencyContact,
    required this.referralName,
    required this.hasVehicle,
    required this.vehicleDetails,
    required this.bankDetails,
    required this.documents,
    required this.profileImage,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String mobile;
  final String email;
  final String city;
  final String status;
  final double rating;
  final int completedJobs;
  final List<String> skills;
  final List<String> expertise;
  final List<String> workingDays;
  final List<String> timeSlots;
  final List<AvailabilitySlot> availabilitySlots;
  final bool onboardingCompleted;
  final String experience;
  final String maritalStatus;
  final String emergencyContact;
  final String referralName;
  final bool hasVehicle;
  final ProviderVehicleDetails vehicleDetails;
  final ProviderBankDetails bankDetails;
  final ProviderDocuments documents;
  final String profileImage;
  final double? latitude;
  final double? longitude;
}

class AvailabilitySlot {
  const AvailabilitySlot({
    required this.start,
    required this.end,
  });

  final String start;
  final String end;
}

class ProviderVehicleDetails {
  const ProviderVehicleDetails({
    required this.type,
    required this.model,
    required this.registrationNumber,
  });

  final String type;
  final String model;
  final String registrationNumber;
}

class ProviderBankDetails {
  const ProviderBankDetails({
    required this.accountHolderName,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.branchName,
  });

  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String branchName;
}

class ProviderDocuments {
  const ProviderDocuments({
    required this.aadharFrontUrl,
    required this.aadharBackUrl,
    required this.panUrl,
  });

  final String aadharFrontUrl;
  final String aadharBackUrl;
  final String panUrl;
}
