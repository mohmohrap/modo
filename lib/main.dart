import 'package:flutter/material.dart';
import 'package:modo/db/db_helper.dart';
import 'package:modo/screens/dashboard.dart';
import 'package:modo/screens/history.dart';
import 'package:modo/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.instance.initDB();
  runApp(const ExpenseApp());
}

class ExpenseApp extends StatefulWidget {
  const ExpenseApp({super.key});

  @override
  State<ExpenseApp> createState() => _ExpenseAppState();
}

class _ExpenseAppState extends State<ExpenseApp> {
  final ThemeProvider _themeProvider = ThemeProvider();

  @override
  void initState() {
    super.initState();
    _themeProvider.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _themeProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: _themeProvider.value,
      home: HomePage(onThemeToggle: _themeProvider.toggleTheme),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const HomePage({super.key, required this.onThemeToggle});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _controller,
      children: [
        DashboardScreen(onThemeToggle: widget.onThemeToggle),
        HistoryScreen(onThemeToggle: widget.onThemeToggle),
      ],
    );
  }
}
