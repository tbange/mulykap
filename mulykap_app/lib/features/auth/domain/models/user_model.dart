import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String? email;
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? status;
  final String? role;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    this.email,
    this.name,
    this.firstName,
    this.lastName,
    this.phone,
    this.status,
    this.role,
    this.createdAt,
  });

  static const empty = UserModel(id: '');

  bool get isEmpty => this == UserModel.empty;
  bool get isNotEmpty => this != UserModel.empty;
  
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    } else if (name != null) {
      return name!;
    } else if (email != null) {
      return email!.split('@').first;
    } else {
      return 'Utilisateur';
    }
  }

  String get displayRole {
    switch (role) {
      case 'admin':
        return 'Administrateur';
      case 'operateur':
        return 'Opérateur';
      case 'client':
        return 'Client';
      default:
        return role ?? 'Utilisateur';
    }
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String?,
      name: map['name'] as String?,
      firstName: map['first_name'] as String?,
      lastName: map['last_name'] as String?,
      phone: map['phone'] as String?,
      status: map['status'] as String?,
      role: map['role'] as String?,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'status': status,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, email, name, firstName, lastName, phone, status, role, createdAt];
} 