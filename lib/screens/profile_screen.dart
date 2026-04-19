import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/provider_profile.dart';
import '../services/api_client.dart';
import '../services/provider_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProviderService _providerService = ProviderService();
  late Future<ProviderProfile> _profileFuture;
  bool _isFetchingLocation = false;
  double? _liveLatitude;
  double? _liveLongitude;
  String _locationMessage = '';

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

  void _refreshProfile() {
    setState(() {
      _profileFuture = _providerService.getProfile();
    });
  }

  Future<void> _fetchRealtimeLocation(ProviderProfile profile) async {
    if (_isFetchingLocation) return;

    setState(() {
      _isFetchingLocation = true;
      _locationMessage = '';
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationMessage = 'Please enable device location and try again.';
          _isFetchingLocation = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _locationMessage = 'Location permission is required to fetch real-time coordinates.';
          _isFetchingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      await _providerService.updateProfile(
        city: profile.city,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      setState(() {
        _liveLatitude = position.latitude;
        _liveLongitude = position.longitude;
        _locationMessage = 'Real-time location updated.';
        _isFetchingLocation = false;
      });

      _refreshProfile();
    } catch (error) {
      setState(() {
        _locationMessage = 'Unable to fetch location: $error';
        _isFetchingLocation = false;
      });
    }
  }

  String _resolveDocumentUrl(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return '';

    final parsed = Uri.tryParse(raw);
    if (parsed != null && parsed.hasScheme) {
      return raw;
    }

    final base = Uri.parse(ApiClient.instance.baseUrl);
    final origin = base.replace(path: '');
    final normalized = raw.startsWith('/') ? raw : '/$raw';
    return origin.resolve(normalized).toString();
  }

  Future<void> _showDocumentPreview({required String title, required String url}) async {
    final resolvedUrl = _resolveDocumentUrl(url);
    if (resolvedUrl.isEmpty) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860, maxHeight: 760),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.network(
                    resolvedUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('Preview not available for this file.'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditProfileSheet(ProviderProfile profile) async {
    final nameController = TextEditingController(text: profile.name);
    final emailController = TextEditingController(text: profile.email);
    final emergencyController = TextEditingController(text: profile.emergencyContact);
    final referralController = TextEditingController(text: profile.referralName);
    final cityController = TextEditingController(text: profile.city);

    String experience = profile.experience.isEmpty ? 'NO_EXPERIENCE' : profile.experience;
    String maritalStatus = profile.maritalStatus.isEmpty ? 'UNMARRIED' : profile.maritalStatus;
    bool hasVehicle = profile.hasVehicle;
    bool saving = false;

    const experienceOptions = [
      DropdownMenuItem(value: 'NO_EXPERIENCE', child: Text('No experience')),
      DropdownMenuItem(value: 'LESS_THAN_6_MONTHS', child: Text('Less than 6 months')),
      DropdownMenuItem(value: 'SIX_TO_TWELVE_MONTHS', child: Text('6 to 12 months')),
      DropdownMenuItem(value: 'MORE_THAN_1_YEAR', child: Text('More than 1 year')),
    ];

    const maritalOptions = [
      DropdownMenuItem(value: 'UNMARRIED', child: Text('Unmarried')),
      DropdownMenuItem(value: 'MARRIED', child: Text('Married')),
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Profile',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emergencyController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Emergency Contact'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: referralController,
                      decoration: const InputDecoration(labelText: 'Referral Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: cityController,
                      decoration: const InputDecoration(labelText: 'City'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: experience,
                      items: experienceOptions,
                      onChanged: (value) {
                        if (value == null) return;
                        modalSetState(() {
                          experience = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Experience'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: maritalStatus,
                      items: maritalOptions,
                      onChanged: (value) {
                        if (value == null) return;
                        modalSetState(() {
                          maritalStatus = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Marital Status'),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Own Vehicle'),
                      value: hasVehicle,
                      onChanged: (value) {
                        modalSetState(() {
                          hasVehicle = value;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: saving ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: saving
                                ? null
                                : () async {
                                    final name = nameController.text.trim();
                                    if (name.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Name is required')),
                                      );
                                      return;
                                    }

                                    modalSetState(() {
                                      saving = true;
                                    });

                                    try {
                                      await _providerService.updateProfile(
                                        name: name,
                                        email: emailController.text.trim(),
                                        emergencyContact: emergencyController.text.trim(),
                                        referralName: referralController.text.trim(),
                                        city: cityController.text.trim(),
                                        experience: experience,
                                        maritalStatus: maritalStatus,
                                        hasVehicle: hasVehicle,
                                      );

                                      if (!mounted) return;
                                      Navigator.of(context).pop();
                                      _refreshProfile();
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        const SnackBar(content: Text('Profile updated successfully')),
                                      );
                                    } catch (error) {
                                      if (!mounted) return;
                                      modalSetState(() {
                                        saving = false;
                                      });
                                      ScaffoldMessenger.of(this.context).showSnackBar(
                                        SnackBar(content: Text('Update failed: $error')),
                                      );
                                    }
                                  },
                            child: saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

  Widget _documentTile({
    required String title,
    required bool uploaded,
    required String url,
  }) {
    final canPreview = uploaded && url.trim().isNotEmpty;

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
          if (canPreview)
            TextButton(
              onPressed: () => _showDocumentPreview(title: title, url: url),
              child: const Text('Preview'),
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
          padding: EdgeInsets.fromLTRB(
            MediaQuery.of(context).size.width >= 1100 ? 24 : 12,
            10,
            MediaQuery.of(context).size.width >= 1100 ? 24 : 12,
            16,
          ),
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
                                child: Wrap(
                                  runSpacing: 6,
                                  children: [
                                    Text(
                                      _safe(profile.name, fallback: 'Service Provider'),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
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
              trailing: TextButton.icon(
                onPressed: () => _openEditProfileSheet(profile),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
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
                    child: profile.skills.isEmpty
                        ? const SizedBox.shrink()
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profile.skills.map((skill) => Chip(label: Text(skill))).toList(),
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
                  _refreshProfile();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _readOnlyField(label: 'Location', value: _safe(profile.city, fallback: 'Location not set')),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.icon(
                      onPressed: _isFetchingLocation ? null : () => _fetchRealtimeLocation(profile),
                      icon: _isFetchingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(_isFetchingLocation ? 'Fetching...' : 'Fetch Real-time Location'),
                    ),
                  ),
                  if (_locationMessage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _locationMessage,
                      style: TextStyle(
                        color: _locationMessage.startsWith('Unable') || _locationMessage.startsWith('Please')
                            ? const Color(0xFFB42318)
                            : const Color(0xFF047857),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (_liveLatitude != null && _liveLongitude != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Live Coordinates: ${_liveLatitude!.toStringAsFixed(5)}, ${_liveLongitude!.toStringAsFixed(5)}',
                      style: const TextStyle(color: Color(0xFF0F8F7B), fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ] else if (profile.latitude != null && profile.longitude != null) ...[
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
                    url: profile.documents.aadharFrontUrl,
                  ),
                  const SizedBox(height: 10),
                  _documentTile(
                    title: 'Aadhaar Back',
                    uploaded: profile.documents.aadharBackUrl.trim().isNotEmpty,
                    url: profile.documents.aadharBackUrl,
                  ),
                  const SizedBox(height: 10),
                  _documentTile(
                    title: 'PAN Card',
                    uploaded: profile.documents.panUrl.trim().isNotEmpty,
                    url: profile.documents.panUrl,
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
