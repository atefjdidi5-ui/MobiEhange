class Reservation {
  final String id;
  final String itemId;
  final String itemTitle;
  final String ownerId;
  final String renterId;
  final String renterName;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final String? message;
  final String status; // 'pending', 'accepted', 'rejected', 'completed', 'cancelled'
  final DateTime createdAt;
  final DateTime? updatedAt;

  Reservation({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.ownerId,
    required this.renterId,
    required this.renterName,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    this.message,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  // Add copyWith method
  Reservation copyWith({
    String? id,
    String? itemId,
    String? itemTitle,
    String? ownerId,
    String? renterId,
    String? renterName,
    DateTime? startDate,
    DateTime? endDate,
    double? totalPrice,
    String? message,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemTitle: itemTitle ?? this.itemTitle,
      ownerId: ownerId ?? this.ownerId,
      renterId: renterId ?? this.renterId,
      renterName: renterName ?? this.renterName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalPrice: totalPrice ?? this.totalPrice,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'ownerId': ownerId,
      'renterId': renterId,
      'renterName': renterName,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'totalPrice': totalPrice,
      'message': message,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  static Reservation fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'],
      itemId: map['itemId'],
      itemTitle: map['itemTitle'],
      ownerId: map['ownerId'],
      renterId: map['renterId'],
      renterName: map['renterName'],
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate']),
      totalPrice: map['totalPrice'].toDouble(),
      message: map['message'],
      status: map['status'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt']) : null,
    );
  }

  // Optional: Add a helper method to calculate number of days
  int get numberOfDays => endDate.difference(startDate).inDays;

  // Optional: Add a helper method to check if reservation is active
  bool get isActive => status == 'pending' || status == 'accepted';
}