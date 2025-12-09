class TransactionModel {
  final int? id;
  final String type; // "income" o "expense"
  final double amount;
  final DateTime date;
  final int categoryId;
  final String? note;
  final String? paymentMethod;

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.note,
    this.paymentMethod,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      categoryId: map['category_id'] as int,
      note: map['note'] as String?,
      paymentMethod: map['payment_method'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
      'category_id': categoryId,
      'note': note,
      'payment_method': paymentMethod,
    };
  }
}
