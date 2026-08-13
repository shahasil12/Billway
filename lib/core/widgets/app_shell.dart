import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width >= 600;
    
    // Determine the active index based on current location
    final String location = GoRouterState.of(context).uri.path;
    int currentIndex = _calculateSelectedIndex(location);

    if (isTablet) {
      return Scaffold(
        body: Row(
          children: [
            _buildNavigationRail(context, currentIndex),
            Expanded(child: child),
          ],
        ),
      );
    } else {
      return Scaffold(
        body: child,
        bottomNavigationBar: _buildBottomNav(context, currentIndex),
      );
    }
  }

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/dashboard') || location == '/') return 0;
    if (location.startsWith('/invoices')) return 1;
    if (location.startsWith('/pos')) return 2;
    if (location.startsWith('/products')) return 3;
    if (location.startsWith('/customers') || 
        location.startsWith('/categories') || 
        location.startsWith('/reports') || 
        location.startsWith('/settings')) {
      return 4; // 'More' on mobile, or handle separately for tablet
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/invoices');
        break;
      case 2:
        context.go('/pos');
        break;
      case 3:
        context.go('/products');
        break;
      case 4:
        // On phone, this goes to a 'More' menu. On tablet, it shouldn't be a single index.
        // For now, map 'More' to Settings on phone, or we can build a More screen.
        context.go('/settings');
        break;
    }
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: AppTextStyles.caption,
      onTap: (index) => _onItemTapped(index, context),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Billing'),
        BottomNavigationBarItem(icon: Icon(Icons.point_of_sale_outlined), activeIcon: Icon(Icons.point_of_sale), label: 'POS'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Products'),
        BottomNavigationBarItem(icon: Icon(Icons.menu), activeIcon: Icon(Icons.menu), label: 'More'),
      ],
    );
  }

  Widget _buildNavigationRail(BuildContext context, int currentIndex) {
    // Tablet has distinct destinations
    final String location = GoRouterState.of(context).uri.path;
    int railIndex = 0;
    if (location == '/') railIndex = 0;
    else if (location.startsWith('/invoices')) railIndex = 1;
    else if (location.startsWith('/pos')) railIndex = 2;
    else if (location.startsWith('/products')) railIndex = 3;
    else if (location.startsWith('/customers')) railIndex = 4;
    else if (location.startsWith('/categories')) railIndex = 5;
    else if (location.startsWith('/reports')) railIndex = 6;
    else if (location.startsWith('/settings')) railIndex = 7;

    return NavigationRail(
      selectedIndex: railIndex,
      onDestinationSelected: (int index) {
        switch (index) {
          case 0: context.go('/'); break;
          case 1: context.go('/invoices'); break;
          case 2: context.go('/pos'); break;
          case 3: context.go('/products'); break;
          case 4: context.go('/customers'); break;
          case 5: context.go('/categories'); break;
          case 6: context.go('/reports'); break;
          case 7: context.go('/settings'); break;
        }
      },
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryLight,
      selectedIconTheme: const IconThemeData(color: AppColors.primary),
      unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary),
      selectedLabelTextStyle: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
      unselectedLabelTextStyle: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
      labelType: NavigationRailLabelType.all,
      destinations: const [
        NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Home')),
        NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Billing')),
        NavigationRailDestination(icon: Icon(Icons.point_of_sale_outlined), selectedIcon: Icon(Icons.point_of_sale), label: Text('POS')),
        NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('Products')),
        NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('Customers')),
        NavigationRailDestination(icon: Icon(Icons.category_outlined), selectedIcon: Icon(Icons.category), label: Text('Categories')),
        NavigationRailDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: Text('Reports')),
        NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
      ],
    );
  }
}
