// models/ReservationCart.dart
class ReservationCart {
  final String id;
  final String renterId;
  final String renterName;
  final List<ReservationCartItem> items;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReservationCart({
    required this.id,
    required this.renterId,
    required this.renterName,
    required this.items,
    required this.createdAt,
    this.updatedAt,
  });

  double get totalPrice {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get itemCount => items.length;

  ReservationCart copyWith({
    String? id,
    String? renterId,
    String? renterName,
    List<ReservationCartItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReservationCart(
      id: id ?? this.id,
      renterId: renterId ?? this.renterId,
      renterName: renterName ?? this.renterName,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'renterId': renterId,
      'renterName': renterName,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  static ReservationCart fromMap(Map<String, dynamic> map) {
    return ReservationCart(
      id: map['id'],
      renterId: map['renterId'],
      renterName: map['renterName'],
      items: (map['items'] as List).map((itemMap) => ReservationCartItem.fromMap(itemMap)).toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt']) : null,
    );
  }
}

class ReservationCartItem {
  final String itemId;
  final String itemTitle;
  final String ownerId;
  final double dailyPrice;
  final DateTime startDate;
  final DateTime endDate;
  final String? message;

  ReservationCartItem({
    required this.itemId,
    required this.itemTitle,
    required this.ownerId,
    required this.dailyPrice,
    required this.startDate,
    required this.endDate,
    this.message,
  });

  int get numberOfDays => endDate.difference(startDate).inDays;
  double get totalPrice => numberOfDays * dailyPrice;

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemTitle': itemTitle,
      'ownerId': ownerId,
      'dailyPrice': dailyPrice,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'message': message,
    };
  }

  static ReservationCartItem fromMap(Map<String, dynamic> map) {
    return ReservationCartItem(
      itemId: map['itemId'],
      itemTitle: map['itemTitle'],
      ownerId: map['ownerId'],
      dailyPrice: map['dailyPrice'].toDouble(),
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate']),
      message: map['message'],
    );
  }

  ReservationCartItem copyWith({
    String? itemId,
    String? itemTitle,
    String? ownerId,
    double? dailyPrice,
    DateTime? startDate,
    DateTime? endDate,
    String? message,
  }) {
    return ReservationCartItem(
      itemId: itemId ?? this.itemId,
      itemTitle: itemTitle ?? this.itemTitle,
      ownerId: ownerId ?? this.ownerId,
      dailyPrice: dailyPrice ?? this.dailyPrice,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      message: message ?? this.message,
    );
  }
}