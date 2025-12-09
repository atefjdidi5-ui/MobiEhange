// models/Review.dart
class Review {
  final String id;
  final String reservationId;
  final String itemId;
  final String itemTitle;
  final String reviewerId;      // Person giving the review
  final String reviewerName;
  final String reviewedUserId;  // Person receiving the review
  final String reviewedUserName;
  final double rating;         // 1-5
  final String comment;
  final DateTime createdAt;
  final String? response;       // Owner's response to review
  final DateTime? respondedAt;
  final bool isOwnerReview;    // Whether this is a review of the owner or the renter

  Review({
    required this.id,
    required this.reservationId,
    required this.itemId,
    required this.itemTitle,
    required this.reviewerId,
    required this.reviewerName,
    required this.reviewedUserId,
    required this.reviewedUserName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.response,
    this.respondedAt,
    required this.isOwnerReview,
  });

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reservationId': reservationId,
      'itemId': itemId,
      'itemTitle': itemTitle,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'reviewedUserId': reviewedUserId,
      'reviewedUserName': reviewedUserName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'response': response,
      'respondedAt': respondedAt?.millisecondsSinceEpoch,
      'isOwnerReview': isOwnerReview,
    };
  }

  // Create from Firestore map
  static Review fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'],
      reservationId: map['reservationId'],
      itemId: map['itemId'],
      itemTitle: map['itemTitle'],
      reviewerId: map['reviewerId'],
      reviewerName: map['reviewerName'],
      reviewedUserId: map['reviewedUserId'],
      reviewedUserName: map['reviewedUserName'],
      rating: map['rating'].toDouble(),
      comment: map['comment'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      response: map['response'],
      respondedAt: map['respondedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['respondedAt'])
          : null,
      isOwnerReview: map['isOwnerReview'] ?? true,
    );
  }

  // Copy with method
  Review copyWith({
    String? id,
    String? reservationId,
    String? itemId,
    String? itemTitle,
    String? reviewerId,
    String? reviewerName,
    String? reviewedUserId,
    String? reviewedUserName,
    double? rating,
    String? comment,
    DateTime? createdAt,
    String? response,
    DateTime? respondedAt,
    bool? isOwnerReview,
  }) {
    return Review(
      id: id ?? this.id,
      reservationId: reservationId ?? this.reservationId,
      itemId: itemId ?? this.itemId,
      itemTitle: itemTitle ?? this.itemTitle,
      reviewerId: reviewerId ?? this.reviewerId,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewedUserId: reviewedUserId ?? this.reviewedUserId,
      reviewedUserName: reviewedUserName ?? this.reviewedUserName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      response: response ?? this.response,
      respondedAt: respondedAt ?? this.respondedAt,
      isOwnerReview: isOwnerReview ?? this.isOwnerReview,
    );
  }

  // Helper methods
  bool get hasResponse => response != null && response!.isNotEmpty;

  String get type => isOwnerReview ? 'Owner Review' : 'Renter Review';
}