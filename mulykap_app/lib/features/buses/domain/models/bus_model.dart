import 'package:equatable/equatable.dart';

enum BusType {
  MINIBUS_20P,
  VIP_32P,
  LUXE_50P,
  BUS_40P,
  COACH_50P,
  DOUBLE_DECKER_70P,
}

extension BusTypeExtension on BusType {
  String get displayName {
    switch (this) {
      case BusType.MINIBUS_20P:
        return 'Minibus (20 places)';
      case BusType.VIP_32P:
        return 'VIP (32 places)';
      case BusType.LUXE_50P:
        return 'Luxe (50 places)';
      case BusType.BUS_40P:
        return 'Bus (40 places)';
      case BusType.COACH_50P:
        return 'Coach (50 places)';
      case BusType.DOUBLE_DECKER_70P:
        return 'Double Decker (70 places)';
    }
  }
}

class BusModel extends Equatable {
  final String id;
  final String agencyId;
  final String licensePlate;
  final String model;
  final BusType type;
  final int capacity;
  final double baggageCapacityKg;
  final double baggageVolumeM3;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BusModel({
    required this.id,
    required this.agencyId,
    required this.licensePlate,
    required this.model,
    required this.type,
    required this.capacity,
    required this.baggageCapacityKg,
    required this.baggageVolumeM3,
    this.createdAt,
    this.updatedAt,
  });

  factory BusModel.fromMap(Map<String, dynamic> map) {
    return BusModel(
      id: map['id'] as String,
      agencyId: map['agency_id'] as String,
      licensePlate: map['license_plate'] as String,
      model: map['model'] as String,
      type: _mapStringToBusType(map['type'] as String),
      capacity: map['capacity'] as int,
      baggageCapacityKg: map['baggage_capacity_kg'] as double,
      baggageVolumeM3: map['baggage_volume_m3'] as double,
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
      'agency_id': agencyId,
      'license_plate': licensePlate,
      'model': model,
      'type': type.name,
      'capacity': capacity,
      'baggage_capacity_kg': baggageCapacityKg,
      'baggage_volume_m3': baggageVolumeM3,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static BusType _mapStringToBusType(String typeStr) {
    return BusType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => BusType.MINIBUS_20P,
    );
  }

  BusModel copyWith({
    String? id,
    String? agencyId,
    String? licensePlate,
    String? model,
    BusType? type,
    int? capacity,
    double? baggageCapacityKg,
    double? baggageVolumeM3,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusModel(
      id: id ?? this.id,
      agencyId: agencyId ?? this.agencyId,
      licensePlate: licensePlate ?? this.licensePlate,
      model: model ?? this.model,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      baggageCapacityKg: baggageCapacityKg ?? this.baggageCapacityKg,
      baggageVolumeM3: baggageVolumeM3 ?? this.baggageVolumeM3,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        agencyId,
        licensePlate,
        model,
        type,
        capacity,
        baggageCapacityKg,
        baggageVolumeM3,
        createdAt,
        updatedAt,
      ];
} 