import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../constants/app_colors.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final user = ref.watch(authProvider).user;
    final role = user?.role ?? '';

    final tabs = _buildTabs(role);
    final currentIndex = _locationToIndex(location, tabs);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex.clamp(0, tabs.length - 1),
        onDestinationSelected: (i) => context.go(tabs[i].path),
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.primaryContainer,
        destinations: tabs.map((t) => NavigationDestination(
          icon: Icon(t.icon),
          selectedIcon: Icon(t.selectedIcon, color: AppColors.primary),
          label: t.label,
        )).toList(),
      ),
    );
  }

  List<_NavTab> _buildTabs(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return const [
          _NavTab('/dashboard', 'Dashboard', Icons.dashboard_outlined, Icons.dashboard),
          _NavTab('/requests', 'Requests', Icons.local_gas_station_outlined, Icons.local_gas_station),
          _NavTab('/allocations', 'Allocations', Icons.assignment_outlined, Icons.assignment),
          _NavTab('/anomalies', 'Anomalies', Icons.warning_amber_outlined, Icons.warning_amber),
          _NavTab('/profile', 'Profile', Icons.person_outline, Icons.person),
        ];
      case 'MANAGER':
        return const [
          _NavTab('/dashboard', 'Dashboard', Icons.dashboard_outlined, Icons.dashboard),
          _NavTab('/requests', 'Requests', Icons.local_gas_station_outlined, Icons.local_gas_station),
          _NavTab('/allocations', 'Allocations', Icons.assignment_outlined, Icons.assignment),
          _NavTab('/anomalies', 'Anomalies', Icons.warning_amber_outlined, Icons.warning_amber),
          _NavTab('/profile', 'Profile', Icons.person_outline, Icons.person),
        ];
      case 'FINANCE':
        return const [
          _NavTab('/dashboard', 'Dashboard', Icons.bar_chart_outlined, Icons.bar_chart),
          _NavTab('/allocations', 'Allocations', Icons.assignment_outlined, Icons.assignment),
          _NavTab('/notifications', 'Alerts', Icons.notifications_outlined, Icons.notifications),
          _NavTab('/profile', 'Profile', Icons.person_outline, Icons.person),
        ];
      default: // DRIVER
        return const [
          _NavTab('/dashboard', 'Dashboard', Icons.dashboard_outlined, Icons.dashboard),
          _NavTab('/requests', 'Requests', Icons.local_gas_station_outlined, Icons.local_gas_station),
          _NavTab('/receipts', 'Receipts', Icons.receipt_long_outlined, Icons.receipt_long),
          _NavTab('/allocations', 'Allocation', Icons.water_drop_outlined, Icons.water_drop),
          _NavTab('/profile', 'Profile', Icons.person_outline, Icons.person),
        ];
    }
  }

  int _locationToIndex(String location, List<_NavTab> tabs) {
    for (int i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].path)) return i;
    }
    return 0;
  }
}

class _NavTab {
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _NavTab(this.path, this.label, this.icon, this.selectedIcon);

  @override
  bool operator ==(Object other) =>
      other is _NavTab && other.path == path;

  @override
  int get hashCode => path.hashCode;
}
