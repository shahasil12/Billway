import '../../domain/entities/pos_session.dart';

class POSSessionModel extends POSSession {
  POSSessionModel({
    required super.id,
    required super.userId,
    required super.openingCash,
    super.closingCash,
    super.expectedCash,
    super.cashDifference,
    required super.status,
    required super.openedAt,
    super.closedAt,
  });

  factory POSSessionModel.fromJson(Map<String, dynamic> json) {
    return POSSessionModel(
      id: json['id'],
      userId: json['user'],
      openingCash: double.tryParse(json['opening_cash'].toString()) ?? 0,
      closingCash: json['closing_cash'] != null ? double.tryParse(json['closing_cash'].toString()) : null,
      expectedCash: json['expected_cash'] != null ? double.tryParse(json['expected_cash'].toString()) : null,
      cashDifference: json['cash_difference'] != null ? double.tryParse(json['cash_difference'].toString()) : null,
      status: json['status'],
      openedAt: DateTime.parse(json['opened_at']),
      closedAt: json['closed_at'] != null ? DateTime.parse(json['closed_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'opening_cash': openingCash,
      'closing_cash': closingCash,
      'expected_cash': expectedCash,
      'cash_difference': cashDifference,
      'status': status,
      'opened_at': openedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
    };
  }
}
