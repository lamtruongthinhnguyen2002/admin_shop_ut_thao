class User {
  final String id;
  final String username;
  final String role; // 'admin' | 'staff'
  final String? fullName;
  final String token;

  const User({
    required this.id,
    required this.username,
    required this.role,
    this.fullName,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json, String token) => User(
        id:       json['id'],
        username: json['username'],
        role:     json['role'] ?? 'staff',
        fullName: json['full_name'],
        token:    token,
      );

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toJson() => {
        'id':        id,
        'username':  username,
        'role':      role,
        'full_name': fullName,
        'token':     token,
      };
}