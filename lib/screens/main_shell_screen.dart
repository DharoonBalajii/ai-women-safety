import 'package:flutter/material.dart';

import '../theme/home_theme.dart';
import 'contacts_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

/// Persistent four-tab shell around the "personal companion" surfaces.
/// Each tab keeps its own screen/state alive via [IndexedStack].
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    HistoryScreen(),
    ContactsScreen(),
    SettingsScreen(),
  ];

  static const _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.assignment_outlined, activeIcon: Icons.assignment_rounded, label: 'Activity'),
    _NavItem(icon: Icons.group_outlined, activeIcon: Icons.group_rounded, label: 'Safety Circle'),
    _NavItem(icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, label: 'Personal Details'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.97),
          border: const Border(top: BorderSide(color: HomeColors.cardBorder)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: _items[i],
                      active: i == _index,
                      onTap: () => setState(() => _index = i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  const _NavButton({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              active ? item.activeIcon : item.icon,
              size: 22,
              color: active ? HomeColors.brandIndigo : HomeColors.inactiveNav,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: HomeText.navLabel(active: active),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: 4,
              height: 4,
              child: active
                  ? const DecoratedBox(decoration: BoxDecoration(color: HomeColors.brandIndigo, shape: BoxShape.circle))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
