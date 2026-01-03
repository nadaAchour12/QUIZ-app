class AppUser {
  final String uid;
  final String name;
  final int age;
  final String email;

  AppUser({
    required this.uid,
    required this.name,
    required this.age,
    required this.email,
  });

  // 🔄 Firestore → Object
  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      age: (map['age'] as num?)?.toInt() ?? 0,
      email: map['email'] ?? '',
    );
  }

  // 🔄 Object → Firestore
  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "age": age,
      "email": email,
    };
  }
}
