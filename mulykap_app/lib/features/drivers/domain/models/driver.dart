import 'package:intl/intl.dart';

class Driver {
  final String id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String licenseNumber;
  final DateTime licenseExpiryDate;
  final String? agencyId;
  final String? agencyName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Driver({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.licenseNumber,
    required this.licenseExpiryDate,
    this.agencyId,
    this.agencyName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  String get formattedLicenseExpiryDate {
    return DateFormat('dd/MM/yyyy').format(licenseExpiryDate);
  }

  bool get isLicenseExpired {
    return licenseExpiryDate.isBefore(DateTime.now());
  }

  bool get isLicenseSoonExpiring {
    final now = DateTime.now();
    final oneMonthFromNow = DateTime(now.year, now.month + 1, now.day);
    return licenseExpiryDate.isAfter(now) && 
           licenseExpiryDate.isBefore(oneMonthFromNow);
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      licenseNumber: json['license_number'],
      licenseExpiryDate: DateTime.parse(json['license_expiry_date']),
      agencyId: json['agency_id'],
      agencyName: json['agency_name'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'license_number': licenseNumber,
      'license_expiry_date': licenseExpiryDate.toIso8601String(),
      'agency_id': agencyId,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toCreateJson() {
    final json = toJson();
    json.remove('id');
    return json;
  }

  Driver copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? licenseNumber,
    DateTime? licenseExpiryDate,
    String? agencyId,
    String? agencyName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Driver(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      agencyId: agencyId ?? this.agencyId,
      agencyName: agencyName ?? this.agencyName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 