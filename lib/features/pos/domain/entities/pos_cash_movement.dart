class POSCashMovement {
  final int? id;
  final String posSessionId;
  final double amount;
  final String movementType; // 'IN' or 'OUT'
  final String reason;
  final String? createdAt;

  POSCashMovement({
    this.id,
    required this.posSessionId,
    required this.amount,
    required this.movementType,
    required this.reason,
    this.createdAt,
  });

  factory POSCashMovement.fromJson(Map<String, dynamic> json) {
    return POSCashMovement(
      id: json['id'],
      posSessionId: json['pos_session'].toString(),
      amount: double.tryParse((json['amount'] ?? '0').toString()) ?? 0,
      movementType: json['movement_type'] ?? 'IN',
      reason: json['reason'] ?? '',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'movement_type': movementType,
      'reason': reason,
    };
  }
}
