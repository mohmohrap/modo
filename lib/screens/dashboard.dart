import 'package:flutter/material.dart';
import 'package:modo/db/db_helper.dart';
import 'package:modo/screens/add.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const DashboardScreen({super.key, required this.onThemeToggle});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<double> today;
  late Future<double> week;
  late Future<double> month;
  late Future<List<Map<String, dynamic>>> topCategory;
  late Future<List<Map<String, dynamic>>> recent;
  late Future<List<Map<String, dynamic>>> weeklyData;

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
    topCategory = db.getTopCategoriesThisMonth();
    recent = db.getRecentTransactions();
    weeklyData = db.getWeeklySpendingPast12Weeks();
  }

  Future<void> _refresh() async {
    setState(() => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: widget.onThemeToggle,
            tooltip: 'Toggle theme',
          ),
        ],
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
            _buildLineChart(),
            const SizedBox(height: 20),
            _buildRecent(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
          _refresh();
        },
        tooltip: 'Add Expense',
        child: const Icon(Icons.add_circle_rounded),
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
            Expanded(child: _card("This Month", month)),
          ],
        ),
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
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: topCategory,
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        final monthName = DateFormat('MMMM').format(DateTime.now());

        if (data.isEmpty) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.category),
              title: Text("Top Categories in $monthName"),
              subtitle: const Text("No data"),
            ),
          );
        }

        // Build a string for top 3 categories
        final items = <String>[];
        for (int i = 0; i < data.length && i < 3; i++) {
          final entry = data[i];
          final cat = entry['category'] ?? '';
          final total = entry['total'] ?? 0;
          items.add("${i + 1}. $cat - KES $total");
        }

        return Card(
          child: ListTile(
            leading: const Icon(Icons.category),
            title: Text("Top Categories in $monthName"),
            subtitle: Text(items.join('\n')),
            isThreeLine: items.length > 1,
          ),
        );
      },
    );
  }

  Widget _buildLineChart() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: weeklyData,
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];

        if (data.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No spending data for the past 12 weeks',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }

        // Prepare data for the chart
        final spots = <FlSpot>[];
        for (int i = 0; i < data.length; i++) {
          final amount = (data[i]['total'] as num?)?.toDouble() ?? 0.0;
          spots.add(FlSpot(i.toDouble(), amount));
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Spending (Past 12 Weeks)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 48,
                            getTitlesWidget: (value, meta) {
                              final kValue = value / 1000;
                              final label = kValue <= 0
                                  ? '0'
                                  : kValue >= 1
                                  ? '${kValue.toStringAsFixed(kValue % 1 == 0 ? 0 : 1)}k'
                                  : kValue >= 0.1
                                  ? '${kValue.toStringAsFixed(1)}k'
                                  : '${kValue.toStringAsFixed(2)}k';
                              return Text(
                                label,
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < data.length) {
                                if (index % 2 == 0) {
                                  return Text(
                                    index.toString(),
                                    style: const TextStyle(fontSize: 10),
                                  );
                                }
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.grey,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                      minY: 0,
                    ),
                  ),
                ),
              ],
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...items.map((e) {
              return ListTile(
                leading: const Icon(Icons.monetization_on),
                title: Text(e['title'] ?? ''),
                subtitle: Text(
                  '${e['category']}'
                  '${(e['description'] as String?)?.isNotEmpty == true ? ' • ${e['description']}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text("KES ${e['amount']}"),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddExpenseScreen(expense: e),
                    ),
                  );
                  _refresh();
                },
              );
            }),
          ],
        );
      },
    );
  }
}
