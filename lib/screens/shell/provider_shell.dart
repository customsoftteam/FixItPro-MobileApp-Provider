import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../availability_screen.dart';
import '../bookings_screen.dart';
import '../dashboard_screen.dart';
import '../help_screen.dart';
import '../notifications_screen.dart';
import '../products_screen.dart';
import '../profile_screen.dart';
import '../settings_screen.dart';
import '../skills_screen.dart';

class ProviderShell extends StatefulWidget {
  const ProviderShell({super.key});

  @override
  State<ProviderShell> createState() => _ProviderShellState();
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final Widget screen;
}

class _ProviderShellState extends State<ProviderShell> {
  final AuthService _authService = AuthService();
  int _selectedIndex = 0;

  static const List<_ShellDestination> _destinations = [
    _ShellDestination(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      screen: DashboardScreen(),
    ),
    _ShellDestination(
      label: 'Bookings',
      icon: Icons.assignment_outlined,
      screen: BookingsScreen(),
    ),
    _ShellDestination(
      label: 'Products',
      icon: Icons.inventory_2_outlined,
      screen: ProductsScreen(),
    ),
    _ShellDestination(
      label: 'Profile',
      icon: Icons.person_outline,
      screen: ProfileScreen(),
    ),
    _ShellDestination(
      label: 'Skills',
      icon: Icons.handyman_outlined,
      screen: SkillsScreen(),
    ),
    _ShellDestination(
      label: 'Availability',
      icon: Icons.schedule_outlined,
      screen: AvailabilityScreen(),
    ),
    _ShellDestination(
      label: 'Notifications',
      icon: Icons.notifications_none_outlined,
      screen: NotificationsScreen(),
    ),
    _ShellDestination(
      label: 'Settings',
      icon: Icons.settings_outlined,
      screen: SettingsScreen(),
    ),
    _ShellDestination(
      label: 'Help',
      icon: Icons.help_outline,
      screen: HelpScreen(),
    ),
  ];

  Future<void> _logout() async {
    await _authService.signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _selectIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildDestinationList({required bool closeDrawerOnTap}) {
    return Scrollbar(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF111A2E), Color(0xFF111D34)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFF12D3B5),
                child: Icon(Icons.handyman_outlined, color: Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'FixItPro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Service Provider Portal',
                style: TextStyle(color: Color(0xFF97A7C1)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(_destinations.length, (index) {
          final destination = _destinations[index];
          final selected = index == _selectedIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              selected: selected,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              leading: Icon(
                destination.icon,
                color: selected ? const Color(0xFF10B981) : null,
              ),
              title: Text(
                destination.label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? const Color(0xFF10B981) : null,
                ),
              ),
              selectedTileColor: const Color(0xFFD1FAE5),
              onTap: () {
                _selectIndex(index);
                if (closeDrawerOnTap && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          );
        }),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Logout'),
          onTap: _logout,
        ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;
    final currentScreen = _destinations[_selectedIndex].screen;

    return Scaffold(
      appBar: AppBar(
        title: Text(_destinations[_selectedIndex].label),
        backgroundColor: const Color(0xFF10B981),
        elevation: 4,
        leading: isDesktop
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        actions: [
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: isDesktop ? null : Drawer(child: SafeArea(child: _buildDestinationList(closeDrawerOnTap: true))),
      body: isDesktop
          ? Row(
              children: [
                SizedBox(
                  width: 320,
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: SafeArea(
                      child: _buildDestinationList(closeDrawerOnTap: false),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: KeyedSubtree(
                        key: ValueKey<int>(_selectedIndex),
                        child: currentScreen,
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: KeyedSubtree(
                  key: ValueKey<int>(_selectedIndex),
                  child: currentScreen,
                ),
              ),
            ),
    );
  }
}
