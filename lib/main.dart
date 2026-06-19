import 'package:flutter/material.dart';
import 'package:modo/db/db_helper.dart';
import 'package:modo/screens/dashboard.dart';
import 'package:modo/screens/history.dart';
import 'package:modo/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DBHelper.instance.initDB();

  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(ExpenseApp(themeProvider: themeProvider));
}

class ExpenseApp extends StatefulWidget {
  final ThemeProvider themeProvider;

  const ExpenseApp({super.key, required this.themeProvider});

  @override
  State<ExpenseApp> createState() => _ExpenseAppState();
}

class _ExpenseAppState extends State<ExpenseApp> {
  late final ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();

    _themeProvider = widget.themeProvider;

    _themeProvider.addListener(_themeChanged);
  }

  void _themeChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_themeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Modo',
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: _themeProvider.value,
      home: HomePage(onThemeToggle: () => _themeProvider.toggleTheme()),
    );
  }
}

class HomePage extends StatefulWidget {
  final Future<void> Function() onThemeToggle;

  const HomePage({super.key, required this.onThemeToggle});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      children: [
        DashboardScreen(onThemeToggle: () => widget.onThemeToggle()),
        HistoryScreen(onThemeToggle: () => widget.onThemeToggle()),
      ],
    );
  }
}
