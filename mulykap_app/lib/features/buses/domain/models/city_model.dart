import 'package:equatable/equatable.dart';

class CityModel extends Equatable {
  final String id;
  final String code;
  final String name;
  final String province;
  final bool isMain;
  final String? postalCode;
  final String? country;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CityModel({
    required this.id,
    required this.code,
    required this.name,
    required this.province,
    this.isMain = false,
    this.postalCode,
    this.country,
    this.createdAt,
    this.updatedAt,
  });

  CityModel copyWith({
    String? id,
    String? code,
    String? name,
    String? province,
    bool? isMain,
    String? postalCode,
    String? country,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CityModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      province: province ?? this.province,
      isMain: isMain ?? this.isMain,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      province: json['province'] as String,
      isMain: json['is_main'] as bool? ?? false,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'province': province,
      'is_main': isMain,
      'postal_code': postalCode,
      'country': country,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        province,
        isMain,
        postalCode,
        country,
        createdAt,
        updatedAt,
      ];
} 