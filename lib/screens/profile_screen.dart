import 'package:flutter/material.dart';

import '../models/provider_profile.dart';
import '../services/provider_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProviderService _providerService = ProviderService();
  late Future<ProviderProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _providerService.getProfile();
  }

  String _initials(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'SP';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    final first = parts.first.substring(0, 1);
    final last = parts.last.substring(0, 1);
    return (first + last).toUpperCase();
  }

  String _experienceLabel(String value) {
    return switch (value) {
      'MORE_THAN_1_YEAR' => 'More than 1 year',
      'SIX_TO_TWELVE_MONTHS' => '6 to 12 months',
      'LESS_THAN_6_MONTHS' => 'Less than 6 months',
      'NO_EXPERIENCE' => 'No experience',
      _ => 'Not specified',
    };
  }

  String _maritalLabel(String value) {
    return switch (value) {
      'MARRIED' => 'Married',
      'UNMARRIED' => 'Unmarried',
      _ => 'Not specified',
    };
  }

  String _safe(String value, {String fallback = 'Not specified'}) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  Widget _statTile({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF0F8F7B), size: 21),
          const SizedBox(height: 8),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF0F8F7B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      fontSize: 18,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _readOnlyField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 46),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6EDF5)),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 14.5, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _documentTile({required String title, required bool uploaded}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  uploaded ? 'Uploaded' : 'Not uploaded',
                  style: TextStyle(
                    color: uploaded ? const Color(0xFF1F9D62) : const Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            uploaded ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            color: uploaded ? const Color(0xFF1F9D62) : const Color(0xFF94A3B8),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ProviderProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Unable to load profile details. Please try again.\n\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB42318), fontSize: 16),
              ),
            ),
          );
        }

        final profile = snapshot.data;
        if (profile == null) {
          return const Center(child: Text('Profile not available.'));
        }

        final uploadedDocs = [
          profile.documents.aadharFrontUrl,
          profile.documents.aadharBackUrl,
          profile.documents.panUrl,
        ].where((url) => url.trim().isNotEmpty).length;

        final hasProfileImage = profile.profileImage.trim().isNotEmpty;

        return ListView(
          children: [
            Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            const Text('Manage your provider profile'),
            const SizedBox(height: 16),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    height: 138,
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.topRight,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF101B35), Color(0xFF1A2F56), Color(0xFF1D4E4A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Chip(
                      avatar: const Icon(Icons.verified_user_outlined, size: 18, color: Colors.white),
                      label: Text(profile.status == 'ACTIVE' ? 'Verified' : 'Pending Verification'),
                      backgroundColor: const Color(0x33E2E8F0),
                      side: BorderSide.none,
                      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -34),
                              child: Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF12B5A4),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFF8FAFC), width: 5),
                                ),
                                child: hasProfileImage
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: Image.network(
                                          profile.profileImage,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Center(
                                            child: Text(
                                              _initials(profile.name),
                                              style: const TextStyle(
                                                color: Color(0xFFE6FFFB),
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          _initials(profile.name),
                                          style: const TextStyle(
                                            color: Color(0xFFE6FFFB),
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _safe(profile.name, fallback: 'Service Provider'),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _safe(profile.city, fallback: 'Location not set'),
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final tileWidth = constraints.maxWidth >= 900
                                ? (constraints.maxWidth - 18) / 4
                                : constraints.maxWidth >= 580
                                    ? (constraints.maxWidth - 12) / 2
                                    : constraints.maxWidth;

                            return Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                SizedBox(
                                  width: tileWidth,
                                  child: _statTile(
                                    icon: Icons.star_border_rounded,
                                    value: profile.rating > 0 ? profile.rating.toStringAsFixed(1) : 'N/A',
                                    label: 'Reviews',
                                  ),
                                ),
                                SizedBox(
                                  width: tileWidth,
                                  child: _statTile(
                                    icon: Icons.work_outline_rounded,
                                    value: _experienceLabel(profile.experience),
                                    label: 'Experience',
                                  ),
                                ),
                                SizedBox(
                                  width: tileWidth,
                                  child: _statTile(
                                    icon: Icons.check_circle_outline_rounded,
                                    value: profile.onboardingCompleted ? '100%' : '70%',
                                    label: 'Profile completion',
                                  ),
                                ),
                                SizedBox(
                                  width: tileWidth,
                                  child: _statTile(
                                    icon: Icons.currency_rupee_rounded,
                                    value: _safe(profile.status, fallback: 'INACTIVE'),
                                    label: 'Account status',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              icon: Icons.account_balance_outlined,
              title: 'Bank Details',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 820;
                  if (!isWide) {
                    return Column(
                      children: [
                        _readOnlyField(
                          label: 'Account Holder Name',
                          value: _safe(profile.bankDetails.accountHolderName),
                        ),
                        const SizedBox(height: 10),
                        _readOnlyField(label: 'Bank Name', value: _safe(profile.bankDetails.bankName)),
                        const SizedBox(height: 10),
                        _readOnlyField(label: 'Account Number', value: _safe(profile.bankDetails.accountNumber)),
                        const SizedBox(height: 10),
                        _readOnlyField(label: 'IFSC Code', value: _safe(profile.bankDetails.ifscCode)),
                        const SizedBox(height: 10),
                        _readOnlyField(label: 'Branch Name', value: _safe(profile.bankDetails.branchName)),
                      ],
                    );
                  }

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _readOnlyField(
                          label: 'Account Holder Name',
                          value: _safe(profile.bankDetails.accountHolderName),
                        ),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _readOnlyField(label: 'Bank Name', value: _safe(profile.bankDetails.bankName)),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _readOnlyField(label: 'Account Number', value: _safe(profile.bankDetails.accountNumber)),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _readOnlyField(label: 'IFSC Code', value: _safe(profile.bankDetails.ifscCode)),
                      ),
                      SizedBox(
                        width: constraints.maxWidth,
                        child: _readOnlyField(label: 'Branch Name', value: _safe(profile.bankDetails.branchName)),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              icon: Icons.person_outline_rounded,
              title: 'Personal Information',
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 820;
                  if (!isWide) {
                    return Column(
                      children: [
                        _readOnlyField(label: 'Full Name', value: _safe(profile.name, fallback: 'Provider')),
                        const SizedBox(height: 10),
                        _readOnlyField(label: 'Phone', value: _safe(profile.mobile)),
                        const SizedBox(height: 10),
                        _readOnlyField(label: 'Email', value: _safe(profile.email)),
                        const SizedBox(height: 10),
                        _readOnlyField(label: 'Emergency Contact', value: _safe(profile.emergencyContact)),
                      ],
                    );
                  }

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _readOnlyField(label: 'Full Name', value: _safe(profile.name, fallback: 'Provider')),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _readOnlyField(label: 'Phone', value: _safe(profile.mobile)),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _readOnlyField(label: 'Email', value: _safe(profile.email)),
                      ),
                      SizedBox(
                        width: (constraints.maxWidth - 12) / 2,
                        child: _readOnlyField(label: 'Emergency Contact', value: _safe(profile.emergencyContact)),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              icon: Icons.work_outline_rounded,
              title: 'Professional Information',
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 820;
                      if (!isWide) {
                        return Column(
                          children: [
                            _readOnlyField(label: 'Experience', value: _experienceLabel(profile.experience)),
                            const SizedBox(height: 10),
                            _readOnlyField(label: 'Marital Status', value: _maritalLabel(profile.maritalStatus)),
                            const SizedBox(height: 10),
                            _readOnlyField(label: 'Referral Name', value: _safe(profile.referralName)),
                            const SizedBox(height: 10),
                            _readOnlyField(label: 'Own Vehicle', value: profile.hasVehicle ? 'Yes' : 'No'),
                          ],
                        );
                      }

                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: (constraints.maxWidth - 24) / 3,
                            child: _readOnlyField(label: 'Experience', value: _experienceLabel(profile.experience)),
                          ),
                          SizedBox(
                            width: (constraints.maxWidth - 24) / 3,
                            child: _readOnlyField(label: 'Marital Status', value: _maritalLabel(profile.maritalStatus)),
                          ),
                          SizedBox(
                            width: (constraints.maxWidth - 24) / 3,
                            child: _readOnlyField(label: 'Referral Name', value: _safe(profile.referralName)),
                          ),
                          SizedBox(
                            width: (constraints.maxWidth - 24) / 3,
                            child: _readOnlyField(label: 'Own Vehicle', value: profile.hasVehicle ? 'Yes' : 'No'),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE6EDF5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Vehicle Details',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (profile.hasVehicle) ...[
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 820;
                              if (!isWide) {
                                return Column(
                                  children: [
                                    _readOnlyField(
                                      label: 'Vehicle Type',
                                      value: _safe(profile.vehicleDetails.type),
                                    ),
                                    const SizedBox(height: 10),
                                    _readOnlyField(
                                      label: 'Vehicle Model',
                                      value: _safe(profile.vehicleDetails.model),
                                    ),
                                    const SizedBox(height: 10),
                                    _readOnlyField(
                                      label: 'Registration Number',
                                      value: _safe(profile.vehicleDetails.registrationNumber),
                                    ),
                                  ],
                                );
                              }

                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: (constraints.maxWidth - 24) / 3,
                                    child: _readOnlyField(
                                      label: 'Vehicle Type',
                                      value: _safe(profile.vehicleDetails.type),
                                    ),
                                  ),
                                  SizedBox(
                                    width: (constraints.maxWidth - 24) / 3,
                                    child: _readOnlyField(
                                      label: 'Vehicle Model',
                                      value: _safe(profile.vehicleDetails.model),
                                    ),
                                  ),
                                  SizedBox(
                                    width: (constraints.maxWidth - 24) / 3,
                                    child: _readOnlyField(
                                      label: 'Registration Number',
                                      value: _safe(profile.vehicleDetails.registrationNumber),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ] else
                          const Text(
                            'No vehicle added for this provider.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.skills.isEmpty
                          ? const [
                              Chip(label: Text('No skills added')),
                            ]
                          : profile.skills
                              .map((skill) => Chip(label: Text(skill)))
                              .toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              icon: Icons.location_on_outlined,
              title: 'Service Area',
              trailing: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _profileFuture = _providerService.getProfile();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _readOnlyField(label: 'Location', value: _safe(profile.city, fallback: 'Location not set')),
                  if (profile.latitude != null && profile.longitude != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Coordinates: ${profile.latitude!.toStringAsFixed(4)}, ${profile.longitude!.toStringAsFixed(4)}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _sectionCard(
              icon: Icons.description_outlined,
              title: 'Documents',
              trailing: Chip(
                label: Text('$uploadedDocs/3 Uploaded'),
                backgroundColor: const Color(0xFFEAF8F3),
                side: BorderSide.none,
                labelStyle: const TextStyle(color: Color(0xFF0F8F7B), fontWeight: FontWeight.w700),
              ),
              child: Column(
                children: [
                  _documentTile(
                    title: 'Aadhaar Front',
                    uploaded: profile.documents.aadharFrontUrl.trim().isNotEmpty,
                  ),
                  const SizedBox(height: 10),
                  _documentTile(
                    title: 'Aadhaar Back',
                    uploaded: profile.documents.aadharBackUrl.trim().isNotEmpty,
                  ),
                  const SizedBox(height: 10),
                  _documentTile(
                    title: 'PAN Card',
                    uploaded: profile.documents.panUrl.trim().isNotEmpty,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
