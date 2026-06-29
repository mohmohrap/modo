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
  late Future<List<Map<String, dynamic>>> topAllTime;
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
    topAllTime = db.getTopCategoriesAllTime();
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
            _buildTopAllTime(),
            const SizedBox(height: 20),
            _buildTopCategory(),
            const SizedBox(height: 20),
            _buildWeeklyChart(),
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
              leading: const Icon(Icons.arrow_upward_rounded),
              title: Text("Top Categories in $monthName"),
              subtitle: const Text("No data"),
            ),
          );
        }

        // Build a string for top 5 categories
        final items = <String>[];
        for (int i = 0; i < data.length && i < 5; i++) {
          final entry = data[i];
          final cat = entry['category'] ?? '';
          final total = entry['total'] ?? 0;
          items.add("${i + 1}. $cat - KES $total");
        }

        return Card(
          child: ListTile(
            leading: const Icon(Icons.arrow_upward_rounded),
            title: Text("Top Categories in $monthName"),
            subtitle: Text(items.join('\n')),
            isThreeLine: items.length > 1,
            onTap: () => _showMonthExpenses(data, monthName),
          ),
        );
      },
    );
  }

  Widget _buildTopAllTime() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: topAllTime,
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        //final monthName = DateFormat('MMMM').format(DateTime.now());

        if (data.isEmpty) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.arrow_upward_rounded),
              title: Text("Cummulative expenditure"),
              subtitle: const Text("No data"),
            ),
          );
        }

        // Build a string for top 5 categories
        final items = <String>[];
        for (int i = 0; i < data.length && i < 5; i++) {
          final entry = data[i];
          final cat = entry['category'] ?? '';
          final total = entry['total'] ?? 0;
          items.add("${i + 1}. $cat - KES $total");
        }

        return Card(
          child: ListTile(
            leading: const Icon(Icons.arrow_upward_rounded),
            title: Text("Cummulative expenditure"),
            subtitle: Text(items.join('\n')),
            //isThreeLine: items.length > 1,
            onTap: () => _showAllExpenses(data),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyChart() {
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

        final bars = <BarChartGroupData>[];

        for (int i = 0; i < data.length; i++) {
          final amount = (data[i]['total'] as num?)?.toDouble() ?? 0;

          bars.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: amount,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Weekly Spending (Last 12 Weeks)",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  height: 260,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,

                      gridData: const FlGridData(show: true),

                      borderData: FlBorderData(show: false),

                      barGroups: bars,

                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),

                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 48,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) {
                                return const Text("0");
                              }

                              if (value >= 1000) {
                                return Text(
                                  "${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k",
                                  style: const TextStyle(fontSize: 10),
                                );
                              }

                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),

                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "W${value.toInt() + 1}",
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
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

  void _showMonthExpenses(
    List<Map<String, dynamic>> categories,
    String monthName,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$monthName expenditure",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final item = categories[index];

                      return ListTile(
                        leading: CircleAvatar(child: Text("${index + 1}")),
                        title: Text(item['category']),
                        trailing: Text("KES ${item['total']}"),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAllExpenses(List<Map<String, dynamic>> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Cummulative expenditure",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final item = categories[index];

                      return ListTile(
                        leading: CircleAvatar(child: Text("${index + 1}")),
                        title: Text(item['category']),
                        trailing: Text("KES ${item['total']}"),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
