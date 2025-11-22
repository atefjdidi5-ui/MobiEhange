class Item {
  final String id;
  final String ownerId;
  final String title;
  final String description;
  final List<String> imageUrls;
  final double dailyPrice;
  final String category;
  final String location;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double rating;
  final int totalReviews;

  Item({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.dailyPrice,
    required this.category,
    required this.location,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
    this.rating = 0.0,
    this.totalReviews = 0,
  });

  @override
  String toString() {
    return 'Item{id: $id, ownerId: $ownerId, title: $title, description: $description, imageUrls: $imageUrls, dailyPrice: $dailyPrice, category: $category, location: $location, isAvailable: $isAvailable, createdAt: $createdAt, updatedAt: $updatedAt, rating: $rating, totalReviews: $totalReviews}';
  } // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'imageUrls': imageUrls,
      'dailyPrice': dailyPrice,
      'category': category,
      'location': location,
      'isAvailable': isAvailable,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'rating': rating,
      'totalReviews': totalReviews,
    };
  }

  // Create Item from Map
  static Item fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] ?? '', // Ensure ID is never null
      ownerId: map['ownerId'],
      title: map['title'],
      description: map['description'],
      imageUrls: List<String>.from(map['imageUrls']),
      dailyPrice: map['dailyPrice']?.toDouble() ?? 0.0,
      category: map['category'],
      location: map['location'],
      isAvailable: map['isAvailable'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      rating: map['rating']?.toDouble() ?? 0.0,
      totalReviews: map['totalReviews'] ?? 0,
    );
  }

  // Copy with method for updates - IMPROVED VERSION
  Item copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    List<String>? imageUrls,
    double? dailyPrice,
    String? category,
    String? location,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? rating,
    int? totalReviews,
  }) {
    return Item(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      dailyPrice: dailyPrice ?? this.dailyPrice,
      category: category ?? this.category,
      location: location ?? this.location,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(), // Always update this timestamp
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }
}