import 'package:equatable/equatable.dart';

class AgencyModel extends Equatable {
  final String id;
  final String cityId;
  final String code;
  final String name;
  final Map<String, dynamic> address;
  final String phone;
  final String? email;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AgencyModel({
    required this.id,
    required this.cityId,
    required this.code,
    required this.name,
    required this.address,
    required this.phone,
    this.email,
    this.createdAt,
    this.updatedAt,
  });

  factory AgencyModel.fromMap(Map<String, dynamic> map) {
    return AgencyModel(
      id: map['id'] as String,
      cityId: map['city_id'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      address: map['address'] as Map<String, dynamic>,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String) 
          : null,
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'city_id': cityId,
      'code': code,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  AgencyModel copyWith({
    String? id,
    String? cityId,
    String? code,
    String? name,
    Map<String, dynamic>? address,
    String? phone,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AgencyModel(
      id: id ?? this.id,
      cityId: cityId ?? this.cityId,
      code: code ?? this.code,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        cityId,
        code,
        name,
        address,
        phone,
        email,
        createdAt,
        updatedAt,
      ];
} 