class TopupHistory {
  final String id;
  final double amount;
  final String transRef;
  final String datetime;

  TopupHistory({
    required this.id,
    required this.amount,
    required this.transRef,
    required this.datetime,
  });

  factory TopupHistory.fromJson(Map<String, dynamic> json) {
    return TopupHistory(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      transRef: json['trans_ref'] ?? '',
      datetime: json['datetime'] ?? '',
    );
  }
}