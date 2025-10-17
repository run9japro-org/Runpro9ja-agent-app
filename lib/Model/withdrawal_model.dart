class WithdrawalModel {
  final String id;
  final double amount;
  final String status;
  final DateTime createdAt;

  WithdrawalModel({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalModel(
      id: json['_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
