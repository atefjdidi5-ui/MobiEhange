class AppUser {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? address;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.address,
    required this.createdAt,
  });

  // Methods to convert to/from Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'address': address,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  static AppUser fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      phone: map['phone'],
      address: map['address'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}