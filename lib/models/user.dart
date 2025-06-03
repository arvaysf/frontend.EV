// Updated User model in user.dart
class User {
  final String username;
  final String name;
  final String email;
  final String? password;
  final String? vehicleId;      // Keep for backward compatibility
  final List<String>? vehicleIds; // NEW: Support for multiple vehicles

  User({
    required this.username,
    required this.name,
    required this.email,
    this.password,
    this.vehicleId,
    this.vehicleIds,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle both formats: single vehicleId and list of vehicleIds
    List<String>? vehicleIdsList;
    
    if (json['vehicleIds'] != null) {
      if (json['vehicleIds'] is List) {
        vehicleIdsList = List<String>.from(json['vehicleIds']);
      } else if (json['vehicleIds'] is String) {
        vehicleIdsList = [json['vehicleIds'].toString()];
      }
    }

    return User(
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      vehicleId: json['vehicleId'],
      vehicleIds: vehicleIdsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'name': name,
      'email': email,
      if (password != null) 'password': password,
      if (vehicleId != null) 'vehicleId': vehicleId,
      if (vehicleIds != null) 'vehicleIds': vehicleIds,
    };
  }
}