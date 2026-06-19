import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:modo/db/db_helper.dart';

class HistoryScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const HistoryScreen({super.key, required this.onThemeToggle});

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

  Future<void> _exportExpenses() async {
    final rows = await db.getAllExpenses();
    final jsonString = jsonEncode(rows);
    await Clipboard.setData(ClipboardData(text: jsonString));

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Export Complete'),
          content: const Text('Expense JSON copied to clipboard.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importExpenses() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.paste_rounded),
          title: const Text('Import Expenses?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Paste JSON text to import expenses'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.multiline,
                minLines: 4,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Paste JSON text here',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final clipboard = await Clipboard.getData('text/plain');
                controller.text = clipboard?.text ?? '';
              },
              child: const Text(
                'Paste from Clipboard',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final decoded = jsonDecode(controller.text);
                  if (decoded is List) {
                    var importedCount = 0;
                    for (final item in decoded) {
                      if (item is Map<String, dynamic> || item is Map) {
                        final map = Map<String, dynamic>.from(item as Map);
                        final expense = {
                          'title': map['title'] ?? '',
                          'description': map['description'] ?? '',
                          'amount': (map['amount'] is num)
                              ? (map['amount'] as num).toDouble()
                              : double.tryParse(
                                      map['amount']?.toString() ?? '0',
                                    ) ??
                                    0.0,
                          'category': map['category'] ?? 'Other',
                          'expense_date':
                              map['expense_date'] ??
                              DateTime.now().toIso8601String().split('T').first,
                          'expense_time': map['expense_time'] ?? '',
                        };
                        await db.addExpense(expense);
                        importedCount++;
                      }
                    }
                    await _refresh();
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text('Imported $importedCount expenses'),
                      ),
                    );
                    return;
                  }
                } catch (_) {}
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid JSON import data')),
                  );
                }
              },
              child: const Text(
                'Import',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
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
      appBar: AppBar(
        title: const Text("History"),
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
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            final description = (e['description'] as String?)
                                ?.trim();
                            final dateValue = e['expense_date'] ?? '';
                            String importedDate = '';

                            return StatefulBuilder(
                              builder: (context, setState) {
                                return AlertDialog(
                                  title: Text(e['title'] ?? 'Expense'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        description != null &&
                                                description.isNotEmpty
                                            ? description
                                            : 'No description available.',
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  }).toList(),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.menu_rounded,
        activeIcon: Icons.close,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        overlayColor: Colors.black12,
        overlayOpacity: 0.4,
        spacing: 12,
        spaceBetweenChildren: 8,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.delete_outline),
            backgroundColor: Theme.of(context).colorScheme.error,
            label: 'Clear All',
            labelBackgroundColor: Theme.of(context).colorScheme.surface,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    icon: Icon(Icons.warning_rounded),
                    title: const Text('Clear all expenses?'),
                    content: const Text(
                      'This will permanently delete all saved expense records!',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
              if (confirmed == true) {
                await db.clearExpenses();
                await _refresh();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All expenses cleared')),
                  );
                }
              }
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.upload_file),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            label: 'Export',
            labelBackgroundColor: Theme.of(context).colorScheme.surface,
            onTap: _exportExpenses,
          ),
          SpeedDialChild(
            child: const Icon(Icons.download),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            label: 'Import',
            labelBackgroundColor: Theme.of(context).colorScheme.surface,
            onTap: _importExpenses,
          ),
        ],
      ),
    );
  }
}
