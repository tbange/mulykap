import 'package:equatable/equatable.dart';

class DriverModel extends Equatable {
  final String id;
  final String licenseNumber;
  final String? userId;
  final String? agencyId; // Cette propriété sera ajoutée après altération de la table
  final String? firstName;
  final String? lastName;
  final String? phone;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DriverModel({
    required this.id,
    required this.licenseNumber,
    this.userId,
    this.agencyId,
    this.firstName,
    this.lastName,
    this.phone,
    this.createdAt,
    this.updatedAt,
  });

  // Propriété calculée pour le nom complet
  String get fullName => '$firstName $lastName';

  // Factory constructor pour créer un objet à partir d'une map
  factory DriverModel.fromMap(Map<String, dynamic> map, {Map<String, dynamic>? userProfileMap}) {
    return DriverModel(
      id: map['id'],
      licenseNumber: map['license_number'],
      userId: map['user_id'],
      agencyId: map['agency_id'],
      firstName: userProfileMap?['first_name'] ?? '',
      lastName: userProfileMap?['last_name'] ?? '',
      phone: userProfileMap?['phone'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  // Convertir l'objet en map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'license_number': licenseNumber,
      'user_id': userId,
      'agency_id': agencyId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Méthode pour créer une copie avec des modifications
  DriverModel copyWith({
    String? id,
    String? licenseNumber,
    String? userId,
    String? agencyId,
    String? firstName,
    String? lastName,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverModel(
      id: id ?? this.id,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      userId: userId ?? this.userId,
      agencyId: agencyId ?? this.agencyId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        licenseNumber,
        userId,
        agencyId,
        firstName,
        lastName,
        phone,
        createdAt,
        updatedAt,
      ];
} 