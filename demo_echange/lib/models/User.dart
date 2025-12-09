// models/User.dart
class AppUser {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? address;
  final DateTime createdAt;

  // Review-related fields
  final double averageRating;
  final int totalReviews;
  final int totalRentals; // As owner
  final int totalRented;  // As renter

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.address,
    required this.createdAt,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.totalRentals = 0,
    this.totalRented = 0,
  });

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'totalRentals': totalRentals,
      'totalRented': totalRented,
    };
  }

  // Create from Firestore map
  static AppUser fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      averageRating: map['averageRating']?.toDouble() ?? 0.0,
      totalReviews: map['totalReviews']?.toInt() ?? 0,
      totalRentals: map['totalRentals']?.toInt() ?? 0,
      totalRented: map['totalRented']?.toInt() ?? 0,
    );
  }

  // Copy with method
  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? address,
    DateTime? createdAt,
    double? averageRating,
    int? totalReviews,
    int? totalRentals,
    int? totalRented,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalRentals: totalRentals ?? this.totalRentals,
      totalRented: totalRented ?? this.totalRented,
    );
  }
}