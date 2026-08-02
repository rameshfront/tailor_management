import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/customer_provider.dart';
import 'providers/order_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/customers/customers_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for tailor shop usage
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: const TailorShopApp(),
    ),
  );
}

class TailorShopApp extends StatefulWidget {
  const TailorShopApp({super.key});

  @override
  State<TailorShopApp> createState() => _TailorShopAppState();
}

class _TailorShopAppState extends State<TailorShopApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final settings = context.read<SettingsProvider>();
    await settings.loadSettings();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'G Tailoring',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: _initialized ? const MainNav() : const _SplashScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5C3D11), // G Tailoring brand: warm golden-brown
      brightness: brightness,
      secondary: const Color(0xFFB71C1C), // Red from the heart logo
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: colorScheme.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}

/// Splash / loading screen shown while settings are initializing
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E1F00),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'G Tailoring',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Shop Manager',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Main navigation with bottom nav bar
class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;

  static const List<_NavItem> _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Customers'),
    _NavItem(icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Orders'),
    _NavItem(icon: Icons.search_outlined, activeIcon: Icons.search, label: 'Search'),
    _NavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Reports'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
      context.read<OrderProvider>().loadOrders();
      context.read<OrderProvider>().loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _currentIndex == 4
          ? null // Reports has its own AppBar
          : _currentIndex == 0
              ? null // Home has its own AppBar via SliverAppBar
              : null,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          CustomersScreen(),
          OrdersScreen(filterStatus: null),
          SearchScreen(),
          ReportsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: _items
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: item.label,
                ))
            .toList(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 300),
      ),
      drawer: _buildDrawer(context, theme),
    );
  }

  Widget _buildDrawer(BuildContext context, ThemeData theme) {
    final settings = context.watch<SettingsProvider>();
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 70,
                  width: 70,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.store, size: 36,
                        color: theme.colorScheme.onPrimary),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  settings.shopName,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (settings.ownerName.isNotEmpty)
                  Text(
                    settings.ownerName,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              settings.themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            title: Text(
              settings.themeMode == ThemeMode.dark
                  ? 'Light Mode'
                  : 'Dark Mode',
            ),
            onTap: () {
              Navigator.pop(context);
              settings.toggleTheme();
            },
          ),
          const Divider(),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'G Tailoring Manager',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2025 G Tailoring',
            child: Text('About'),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label});
}
