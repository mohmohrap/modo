class Expense {
  final int? id;
  final String title;
  final String description;
  final double amount;
  final String category;
  final String expenseDate;
  final String expenseTime;

  Expense({
    this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    required this.expenseDate,
    required this.expenseTime,
  });

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      title: map['title'],
      description: map['description'] ?? '',
      amount: (map['amount'] as num).toDouble(),
      category: map['category'],
      expenseDate: map['expense_date'],
      expenseTime: map['expense_time'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'amount': amount,
      'category': category,
      'expense_date': expenseDate,
      'expense_time': expenseTime,
    };
  }
}
