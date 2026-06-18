import 'package:flutter/material.dart';
import 'package:modo/db/db_helper.dart';

class AddExpenseScreen extends StatefulWidget {
  final Map<String, dynamic>? expense;

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => AddExpenseScreenState();
}

class AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _amountController = TextEditingController();

  String? _selectedCategory = 'Food';

  DateTime _selectedDate = DateTime.now();

  TimeOfDay _selectedTime = TimeOfDay.now();

  int? _expenseId;

  final List<String> categories = [
    'Food',
    'Travel',
    'Rent',
    'Family',
    'Utilities',
    'Business',
    'Health',
    'Entertainment',
    'Other',
  ];

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  TimeOfDay _parseTime(String timeString) {
    final normalized = timeString.toLowerCase().replaceAll('.', '');
    final match = RegExp(
      r'(\d{1,2}):(\d{2})\s*([ap]m)?',
    ).firstMatch(normalized);
    if (match != null) {
      var hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      final suffix = match.group(3);
      if (suffix != null) {
        if (suffix == 'pm' && hour < 12) hour += 12;
        if (suffix == 'am' && hour == 12) hour = 0;
      }
      return TimeOfDay(hour: hour, minute: minute);
    }
    return TimeOfDay.now();
  }

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    if (expense != null) {
      _expenseId = expense['id'] as int?;
      _titleController.text = expense['title'] ?? '';
      _descriptionController.text = expense['description'] ?? '';
      _amountController.text = expense['amount']?.toString() ?? '';
      _selectedCategory = expense['category'] ?? _selectedCategory;
      try {
        _selectedDate = DateTime.parse(
          expense['expense_date'] ?? DateTime.now().toIso8601String(),
        );
      } catch (_) {
        _selectedDate = DateTime.now();
      }
      _selectedTime = _parseTime(
        expense['expense_time'] ?? _selectedTime.format(context),
      );
    }
  }

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final db = DBHelper.instance;

      final expense = {
        "title": _titleController.text.trim(),
        "description": _descriptionController.text.trim(),
        "amount": double.parse(_amountController.text),
        "category": _selectedCategory,
        "expense_date":
            "${_selectedDate.year.toString().padLeft(4, '0')}-"
            "${_selectedDate.month.toString().padLeft(2, '0')}-"
            "${_selectedDate.day.toString().padLeft(2, '0')}",
        "expense_time": _selectedTime.format(context),
      };

      if (_expenseId != null) {
        await db.updateExpense(_expenseId!, expense);
      } else {
        await db.addExpense(expense);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _expenseId != null ? 'Expense updated' : 'Expense saved',
          ),
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _expenseId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Expense' : 'Add Expense')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter title';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null ||
                        value.isEmpty ||
                        double.tryParse(value) == null) {
                      return 'Enter valid amount';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),

                const SizedBox(height: 16),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Date'),
                    subtitle: Text(
                      "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: _pickDate,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Time'),
                    subtitle: Text(_selectedTime.format(context)),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: _pickTime,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _saveExpense,
                    icon: const Icon(Icons.save),
                    label: Text(isEditing ? 'Update Expense' : 'Save Expense'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
