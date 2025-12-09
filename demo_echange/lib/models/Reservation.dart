// models/Reservation.dart - Ajoutez ces champs
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
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Champs Flutterwave (remplacez Stripe)
  final String? flutterwaveTxRef;
  final String? flutterwaveTransactionId;
  final String? flutterwaveCheckoutId;
  final String paymentStatus; // 'pending', 'paid', 'failed'
  final String? paymentReceiptUrl;

  // Review-related fields
  final bool canReviewOwner;       // Renter can review owner
  final bool canReviewRenter;      // Owner can review renter
  final bool ownerReviewed;        // Owner has reviewed renter
  final bool renterReviewed;       // Renter has reviewed owner
  final DateTime? reviewDeadline;

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
    this.flutterwaveTxRef,
    this.flutterwaveTransactionId,
    this.flutterwaveCheckoutId,
    this.paymentStatus = 'pending',
    this.paymentReceiptUrl,
    this.canReviewOwner = false,
    this.canReviewRenter = false,
    this.ownerReviewed = false,
    this.renterReviewed = false,
    this.reviewDeadline,
  });

  // Mettez à jour copyWith()
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
    String? flutterwaveTxRef,
    String? flutterwaveTransactionId,
    String? flutterwaveCheckoutId,
    String? paymentStatus,
    String? paymentReceiptUrl,
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
      flutterwaveTxRef: flutterwaveTxRef ?? this.flutterwaveTxRef,
      flutterwaveTransactionId: flutterwaveTransactionId ?? this.flutterwaveTransactionId,
      flutterwaveCheckoutId: flutterwaveCheckoutId ?? this.flutterwaveCheckoutId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentReceiptUrl: paymentReceiptUrl ?? this.paymentReceiptUrl,

      canReviewOwner: canReviewOwner ?? this.canReviewOwner,
      canReviewRenter: canReviewRenter ?? this.canReviewRenter,
      ownerReviewed: ownerReviewed ?? this.ownerReviewed,
      renterReviewed: renterReviewed ?? this.renterReviewed,
      reviewDeadline: reviewDeadline ?? this.reviewDeadline,
    );
  }

  // Mettez à jour toMap()
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
      'flutterwaveTxRef': flutterwaveTxRef,
      'flutterwaveTransactionId': flutterwaveTransactionId,
      'flutterwaveCheckoutId': flutterwaveCheckoutId,
      'paymentStatus': paymentStatus,
      'paymentReceiptUrl': paymentReceiptUrl,
    };
  }

  // Mettez à jour fromMap()
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
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      flutterwaveTxRef: map['flutterwaveTxRef'],
      flutterwaveTransactionId: map['flutterwaveTransactionId'],
      flutterwaveCheckoutId: map['flutterwaveCheckoutId'],
      paymentStatus: map['paymentStatus'] ?? 'pending',
      paymentReceiptUrl: map['paymentReceiptUrl'],



      canReviewOwner: map['canReviewOwner'] ?? false,
      canReviewRenter: map['canReviewRenter'] ?? false,
      ownerReviewed: map['ownerReviewed'] ?? false,
      renterReviewed: map['renterReviewed'] ?? false,
      reviewDeadline: map['reviewDeadline'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['reviewDeadline'])
          : null,
    );
  }

  // Helper methods
  bool get canPay => status == 'accepted' && paymentStatus == 'pending';
  bool get isPaid => paymentStatus == 'paid';
  int get numberOfDays => endDate.difference(startDate).inDays;

  bool get canReviewAsRenter =>
      status == 'accepted' &&
          paymentStatus == 'paid' &&
          canReviewOwner &&
          !renterReviewed &&
          reviewDeadline != null &&
          DateTime.now().isBefore(reviewDeadline!);

  bool get canReviewAsOwner =>
      status == 'accepted' &&
          paymentStatus == 'paid' &&
          canReviewRenter &&
          !ownerReviewed &&
          reviewDeadline != null &&
          DateTime.now().isBefore(reviewDeadline!);

  bool get isReservationComplete => status == 'accepted' && paymentStatus == 'paid';

}