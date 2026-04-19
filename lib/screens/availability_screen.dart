import 'package:flutter/material.dart';

import '../models/provider_profile.dart';
import '../services/provider_service.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  static const List<Map<String, String>> _days = [
    {'key': 'MON', 'label': 'Mon'},
    {'key': 'TUE', 'label': 'Tue'},
    {'key': 'WED', 'label': 'Wed'},
    {'key': 'THU', 'label': 'Thu'},
    {'key': 'FRI', 'label': 'Fri'},
    {'key': 'SAT', 'label': 'Sat'},
    {'key': 'SUN', 'label': 'Sun'},
  ];

  final ProviderService _providerService = ProviderService();

  late Future<void> _loadFuture;

  ProviderProfile? _profile;
  List<String> _workingDays = <String>[];
  List<AvailabilitySlot> _slots = <AvailabilitySlot>[];

  List<String> _initialWorkingDays = <String>[];
  List<AvailabilitySlot> _initialSlots = <AvailabilitySlot>[];

  bool _saving = false;
  bool _showAddDialog = false;
  String? _message;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFuture = _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _providerService.getProfile();
    if (!mounted) return;

    final normalizedDays = _normalizeWorkingDays(profile.workingDays);
    final normalizedSlots = _normalizeSlots(profile.availabilitySlots);

    setState(() {
      _profile = profile;
      _workingDays = List<String>.from(normalizedDays);
      _slots = List<AvailabilitySlot>.from(normalizedSlots);
      _initialWorkingDays = List<String>.from(normalizedDays);
      _initialSlots = List<AvailabilitySlot>.from(normalizedSlots);
    });
  }

  List<String> _normalizeWorkingDays(List<String> input) {
    final allowed = _days.map((day) => day['key']!).toSet();
    final unique = input.where(allowed.contains).toSet().toList();
    unique.sort((a, b) => _dayOrder(a).compareTo(_dayOrder(b)));
    return unique;
  }

  List<AvailabilitySlot> _normalizeSlots(List<AvailabilitySlot> input) {
    final cleaned = input
        .map((slot) => AvailabilitySlot(start: slot.start.trim(), end: slot.end.trim()))
        .where((slot) => slot.start.isNotEmpty || slot.end.isNotEmpty)
        .toList();

    if (cleaned.isEmpty) {
      return const [AvailabilitySlot(start: '', end: '')];
    }

    return cleaned;
  }

  int _dayOrder(String key) {
    final idx = _days.indexWhere((day) => day['key'] == key);
    return idx == -1 ? 999 : idx;
  }

  String _serializeState(List<String> days, List<AvailabilitySlot> slots) {
    final sortedDays = List<String>.from(days)..sort((a, b) => _dayOrder(a).compareTo(_dayOrder(b)));
    final slotsValue = slots.map((slot) => '${slot.start}-${slot.end}').join('|');
    return '${sortedDays.join(',')}::$slotsValue';
  }

  bool get _isDirty {
    final current = _serializeState(_workingDays, _slots);
    final initial = _serializeState(_initialWorkingDays, _initialSlots);
    return current != initial;
  }

  List<AvailabilitySlot> get _validSlots {
    return _slots.where((slot) => slot.start.isNotEmpty && slot.end.isNotEmpty).toList();
  }

  double get _weeklyHours {
    final totalMinutesPerDay = _validSlots.fold<int>(0, (sum, slot) {
      final minutes = _minutesDiff(slot.start, slot.end);
      return sum + (minutes > 0 ? minutes : 0);
    });

    return (totalMinutesPerDay * _workingDays.length) / 60;
  }

  int _minutesDiff(String start, String end) {
    final startMinutes = _toMinutes(start);
    final endMinutes = _toMinutes(end);
    if (startMinutes == null || endMinutes == null) return -1;
    return endMinutes - startMinutes;
  }

  int? _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return (h * 60) + m;
  }

  String _durationLabel(String start, String end) {
    final diff = _minutesDiff(start, end);
    if (diff <= 0) return 'Invalid';
    final h = diff ~/ 60;
    final m = diff % 60;
    return '${h}h ${m}m';
  }

  bool _hasOverlap(List<AvailabilitySlot> slots) {
    final ranges = slots
        .where((slot) => slot.start.isNotEmpty && slot.end.isNotEmpty)
        .map((slot) {
          final start = _toMinutes(slot.start);
          final end = _toMinutes(slot.end);
          if (start == null || end == null) return null;
          return {'start': start, 'end': end};
        })
        .whereType<Map<String, int>>()
        .toList()
      ..sort((a, b) => a['start']!.compareTo(b['start']!));

    for (var i = 1; i < ranges.length; i++) {
      if (ranges[i]['start']! < ranges[i - 1]['end']!) {
        return true;
      }
    }

    return false;
  }

  Future<void> _pickTime(int index, bool isStart) async {
    final slot = _slots[index];
    final current = isStart ? slot.start : slot.end;

    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
    if (current.contains(':')) {
      final parts = current.split(':');
      final h = int.tryParse(parts.first);
      final m = int.tryParse(parts.last);
      if (h != null && m != null) {
        initial = TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: isStart ? 'Select start time' : 'Select end time',
    );

    if (picked == null || !mounted) return;

    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');

    setState(() {
      final updated = AvailabilitySlot(
        start: isStart ? '$hh:$mm' : slot.start,
        end: isStart ? slot.end : '$hh:$mm',
      );
      _slots[index] = updated;
    });
  }

  void _toggleDay(String dayKey) {
    setState(() {
      if (_workingDays.contains(dayKey)) {
        _workingDays = _workingDays.where((day) => day != dayKey).toList();
      } else {
        _workingDays = [..._workingDays, dayKey];
        _workingDays.sort((a, b) => _dayOrder(a).compareTo(_dayOrder(b)));
      }
    });
  }

  void _removeSlot(int index) {
    setState(() {
      final next = List<AvailabilitySlot>.from(_slots)..removeAt(index);
      _slots = next.isEmpty ? const [AvailabilitySlot(start: '', end: '')] : next;
    });
  }

  void _addSlot() {
    setState(() {
      _slots = [..._slots, const AvailabilitySlot(start: '', end: '')];
      _showAddDialog = false;
    });
  }

  void _resetChanges() {
    setState(() {
      _workingDays = List<String>.from(_initialWorkingDays);
      _slots = List<AvailabilitySlot>.from(_initialSlots);
      _message = null;
      _error = null;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
      _error = null;
    });

    try {
      final orderedDays = _normalizeWorkingDays(_workingDays);
      if (orderedDays.isEmpty) {
        setState(() {
          _error = 'Please select at least one working day';
        });
        return;
      }

      final validSlots = _validSlots;
      if (validSlots.isEmpty) {
        setState(() {
          _error = 'Please add at least one valid time slot';
        });
        return;
      }

      final hasInvalidOrder = validSlots.any((slot) => _minutesDiff(slot.start, slot.end) <= 0);
      if (hasInvalidOrder) {
        setState(() {
          _error = 'End time must be later than start time for each slot';
        });
        return;
      }

      if (_hasOverlap(validSlots)) {
        setState(() {
          _error = 'Time slots overlap. Please adjust the schedule.';
        });
        return;
      }

      await _providerService.updateAvailability(
        workingDays: orderedDays,
        slots: validSlots,
      );

      await _loadData();
      if (!mounted) return;
      setState(() {
        _message = 'Availability updated successfully';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _buildSlotCard(BuildContext context, int index, AvailabilitySlot slot) {
    final duration = _durationLabel(slot.start, slot.end);
    final isValid = slot.start.isNotEmpty && slot.end.isNotEmpty && duration != 'Invalid';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isValid ? const Color(0xFFF0FDFA) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValid ? const Color(0xFF8DE4D6) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Color(0xFF0F766E), size: 20),
              const SizedBox(width: 6),
              Text(
                'Slot ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (isValid) const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 18),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 350;

              final startField = _TimeField(
                label: 'Start',
                value: slot.start,
                onTap: () => _pickTime(index, true),
              );

              final endField = _TimeField(
                label: 'End',
                value: slot.end,
                onTap: () => _pickTime(index, false),
              );

              final removeButton = IconButton(
                tooltip: 'Remove slot',
                onPressed: () => _removeSlot(index),
                icon: const Icon(Icons.delete_outline),
              );

              if (compact) {
                return Column(
                  children: [
                    startField,
                    const SizedBox(height: 8),
                    endField,
                    Align(
                      alignment: Alignment.centerRight,
                      child: removeButton,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: startField),
                  const SizedBox(width: 8),
                  Expanded(child: endField),
                  const SizedBox(width: 8),
                  removeButton,
                ],
              );
            },
          ),
          if (isValid) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('${slot.start} - ${slot.end}')),
                Chip(label: Text(duration)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done && _profile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_profile == null) {
          return Center(
            child: Text(_error ?? 'Availability not available.'),
          );
        }

        final validSlots = _validSlots;
        final perDayHours = _workingDays.isEmpty ? 0.0 : _weeklyHours / _workingDays.length;

        return ListView(
          padding: EdgeInsets.fromLTRB(
            MediaQuery.of(context).size.width >= 1100 ? 24 : 12,
            10,
            MediaQuery.of(context).size.width >= 1100 ? 24 : 12,
            14,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8FBF6), Color(0xFFF2FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFFBFEDE2)),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final weeklyHoursCard = Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDFF7F1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFAEE6DA)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Weekly Hours',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        Text(
                          '${_weeklyHours.toStringAsFixed(1)}h',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                        ),
                      ],
                    ),
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Availability Schedule',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Manage your working days and available time slots',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 10),
                        Align(alignment: Alignment.centerLeft, child: weeklyHoursCard),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Availability Schedule',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Manage your working days and available time slots',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      weeklyHoursCard,
                    ],
                  );
                },
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F9EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7E3B8)),
                ),
                child: Text(_message!, style: const TextStyle(color: Color(0xFF166534))),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(_error!, style: const TextStyle(color: Color(0xFF991B1B))),
              ),
            ],
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Working Days',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _days.map((day) {
                        final key = day['key']!;
                        final selected = _workingDays.contains(key);
                        return ChoiceChip(
                          label: Text(day['label']!),
                          selected: selected,
                          onSelected: (_) => _toggleDay(key),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Text('Selected: ${_workingDays.length} days'),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _workingDays.length / 7,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Available Time Slots',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                              ),
                              Text('${validSlots.length} valid slot${validSlots.length == 1 ? '' : 's'}'),
                            ],
                          ),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 18),
                          label: const Text('New Slot'),
                          onPressed: () {
                            setState(() {
                              _showAddDialog = true;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_slots.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDFA),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFEDE2), style: BorderStyle.solid),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.access_time, size: 40, color: Color(0xFF94A3B8)),
                            SizedBox(height: 8),
                            Text('No time slots added yet', style: TextStyle(color: Color(0xFF64748B))),
                          ],
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 940;
                          final isMedium = constraints.maxWidth >= 620;
                          final columns = isWide ? 3 : (isMedium ? 2 : 1);
                          final itemWidth = (constraints.maxWidth - (columns - 1) * 10) / columns;

                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: List.generate(
                              _slots.length,
                              (index) => SizedBox(
                                width: itemWidth,
                                child: _buildSlotCard(context, index, _slots[index]),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 14),
                    const Divider(),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        TextButton(
                          onPressed: (!_isDirty || _saving) ? null : _resetChanges,
                          child: const Text('Reset'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _saving
                              ? null
                              : () {
                                  setState(() {
                                    _showAddDialog = true;
                                  });
                                },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Another Slot'),
                        ),
                        FilledButton.icon(
                          onPressed: (_saving || !_isDirty) ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(_saving ? 'Saving...' : 'Save Availability'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (validSlots.isNotEmpty) ...[
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 680;
                  final summaryWidth = compact ? constraints.maxWidth : (constraints.maxWidth - 10) / 2;

                  Widget totalHoursCard() {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Hours (Weekly)', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              '${_weeklyHours.toStringAsFixed(1)}h',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_workingDays.length} days x ${perDayHours.toStringAsFixed(1)}h per day',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  Widget validSlotsCard() {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Valid Slots', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(
                              '${validSlots.length}/${_slots.length}',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_slots.length - validSlots.length} incomplete slot${_slots.length - validSlots.length == 1 ? '' : 's'}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SizedBox(width: summaryWidth, child: totalHoursCard()),
                      SizedBox(width: summaryWidth, child: validSlotsCard()),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_showAddDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || !_showAddDialog) return;

        final shouldAdd = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Add New Time Slot'),
            content: const Text(
              'New slots will be added as empty. Fill them with your preferred times.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Add Slot'),
              ),
            ],
          ),
        );

        if (!mounted) return;

        setState(() {
          _showAddDialog = false;
        });

        if (shouldAdd == true) {
          _addSlot();
        }
      });
    }
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          value.isEmpty ? 'Select' : value,
          style: TextStyle(
            color: value.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
