import 'package:equatable/equatable.dart';

/// Enum pour les statuts possibles d'un voyage
enum TripStatus {
  scheduled,
  inProgress,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case TripStatus.scheduled:
        return 'Programmé';
      case TripStatus.inProgress:
        return 'En cours';
      case TripStatus.completed:
        return 'Terminé';
      case TripStatus.cancelled:
        return 'Annulé';
    }
  }

  static TripStatus fromString(String value) {
    return TripStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TripStatus.scheduled,
    );
  }
}

/// Modèle représentant un voyage simple
class TripModel extends Equatable {
  final String id;
  final String routeId;
  final String? busId;
  final String? driverId;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final double basePrice;
  final TripStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Propriétés pour les relations (non stockées directement dans la table)
  final String? routeName;
  final String? busPlate;
  final String? driverName;

  const TripModel({
    required this.id,
    required this.routeId,
    this.busId,
    this.driverId,
    required this.departureTime,
    required this.arrivalTime,
    required this.basePrice,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.routeName,
    this.busPlate,
    this.driverName,
  });

  /// Factory constructor pour créer un modèle à partir d'une map
  factory TripModel.fromMap(Map<String, dynamic> map) {
    return TripModel(
      id: map['id'],
      routeId: map['route_id'],
      busId: map['bus_id'],
      driverId: map['driver_id'],
      departureTime: DateTime.parse(map['departure_time']),
      arrivalTime: DateTime.parse(map['arrival_time']),
      basePrice: map['base_price']?.toDouble() ?? 0.0,
      status: map['status'] != null
          ? TripStatus.fromString(map['status'])
          : TripStatus.scheduled,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      routeName: map['route_name'],
      busPlate: map['bus_plate'],
      driverName: map['driver_name'],
    );
  }

  /// Convertir en map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'route_id': routeId,
      'bus_id': busId,
      'driver_id': driverId,
      'departure_time': departureTime.toIso8601String(),
      'arrival_time': arrivalTime.toIso8601String(),
      'base_price': basePrice,
      'status': status.name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Créer une copie de ce modèle avec des modifications
  TripModel copyWith({
    String? id,
    String? routeId,
    String? busId,
    String? driverId,
    DateTime? departureTime,
    DateTime? arrivalTime,
    double? basePrice,
    TripStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? routeName,
    String? busPlate,
    String? driverName,
  }) {
    return TripModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      busId: busId ?? this.busId,
      driverId: driverId ?? this.driverId,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      basePrice: basePrice ?? this.basePrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      routeName: routeName ?? this.routeName,
      busPlate: busPlate ?? this.busPlate,
      driverName: driverName ?? this.driverName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        routeId,
        busId,
        driverId,
        departureTime,
        arrivalTime,
        basePrice,
        status,
        createdAt,
        updatedAt,
        routeName,
        busPlate,
        driverName,
      ];
} 