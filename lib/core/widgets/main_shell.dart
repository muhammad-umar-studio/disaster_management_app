import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_rounded, label: 'Home', route: '/home'),
    _NavItem(icon: Icons.map_rounded, label: 'Map', route: '/map'),
    _NavItem(icon: Icons.emergency_rounded, label: 'SOS', route: '/sos'),
    _NavItem(icon: Icons.smart_toy_rounded, label: 'AI Chat', route: '/chat'),
    _NavItem(icon: Icons.person_rounded, label: 'Profile', route: '/profile'),
  ];

  void _onTap(int index) {
    setState(() => _selectedIndex = index);
    context.go(_items[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _items.indexWhere((e) => e.route == location);
    if (idx != -1 && idx != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = idx);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: widget.child,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: const Border(top: BorderSide(color: AppColors.borderPrimary, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -5)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) => _NavButton(
              item: _items[i],
              isSelected: _selectedIndex == i,
              isSos: i == 2,
              onTap: () => _onTap(i),
            )),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem({required this.icon, required this.label, required this.route});
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final bool isSos;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.isSos,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isSos) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppColors.redGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: AppColors.dangerRed.withOpacity(0.5), blurRadius: 16, spreadRadius: 2),
            ],
          ),
          child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 24),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyanGlow : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isSelected ? AppColors.cyanPrimary : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected ? AppColors.cyanPrimary : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
