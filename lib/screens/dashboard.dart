import 'package:flutter/material.dart';
import 'package:modo/db/db_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<double> today;
  late Future<double> week;
  late Future<double> month;
  late Future<Map<String, dynamic>?> topCategory;
  late Future<List<Map<String, dynamic>>> recent;

  final db = DBHelper.instance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    today = db.getTodaySpending();
    week = db.getWeekSpending();
    month = db.getMonthSpending();
    topCategory = db.getTopCategoryThisMonth();
    recent = db.getRecentTransactions();
  }

  Future<void> _refresh() async {
    setState(() => _load());
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 20),
            _buildTopCategory(),
            const SizedBox(height: 20),
            _buildRecent(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _card("Today", today)),
            const SizedBox(width: 10),
            Expanded(child: _card("This Week", week)),
          ],
        ),
        const SizedBox(height: 10),
        _card("This Month", month),
      ],
    );
  }

  Widget _card(String label, Future<double> future) {
    return FutureBuilder<double>(
      future: future,
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0.0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.green.shade50,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                "KES ${value.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopCategory() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: topCategory,
      builder: (context, snapshot) {
        final data = snapshot.data;

        return Card(
          child: ListTile(
            leading: const Icon(Icons.category),
            title: const Text("Top Category (This Month)"),
            subtitle: Text(
              data == null
                  ? "No data"
                  : "${data['category']} - KES ${data['total']}",
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecent() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: recent,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recent Transactions",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...items.map((e) {
              return ListTile(
                leading: const Icon(Icons.monetization_on),
                title: Text(e['title'] ?? ''),
                subtitle: Text(e['category']),
                trailing: Text("KES ${e['amount']}"),
              );
            }),
          ],
        );
      },
    );
  }
}
