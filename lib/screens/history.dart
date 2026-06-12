import 'package:flutter/material.dart';
import 'package:modo/db/db_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final db = DBHelper.instance;
  late Future<List<Map<String, dynamic>>> expenses;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    expenses = db.getAllExpenses();
  }

  Future<void> _refresh() async {
    setState(() => _load());
  }

  Map<String, List<Map<String, dynamic>>> groupByDate(
    List<Map<String, dynamic>> data,
  ) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var item in data) {
      String date = item['expense_date'];
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(item);
    }
    return grouped;
  }

  String formatDateLabel(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final expenseDate = DateTime(date.year, date.month, date.day);

      if (expenseDate == today) return "Today";
      if (expenseDate == yesterday) return "Yesterday";
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History")),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: expenses,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No transactions yet"));
            }

            final grouped = groupByDate(snapshot.data!);
            final keys = grouped.keys.toList();

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: keys.length,
              itemBuilder: (context, index) {
                final date = keys[index];
                final items = grouped[date]!;

                return ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(
                    formatDateLabel(date),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: items.map((e) {
                    return ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: Text(e['title']),
                      subtitle: Text("${e['category']} • ${e['expense_time']}"),
                      trailing: Text(
                        "KES ${e['amount']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
