class POSSession {
  final String id;
  final int userId;
  final double openingCash;
  final double? closingCash;
  final double? expectedCash;
  final double? cashDifference;
  final String status;
  final DateTime openedAt;
  final DateTime? closedAt;

  POSSession({
    required this.id,
    required this.userId,
    required this.openingCash,
    this.closingCash,
    this.expectedCash,
    this.cashDifference,
    required this.status,
    required this.openedAt,
    this.closedAt,
  });
}
