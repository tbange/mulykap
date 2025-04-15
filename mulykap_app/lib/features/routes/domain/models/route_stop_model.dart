import 'package:equatable/equatable.dart';

enum StopType {
  depart,
  intermediaire,
  arrivee,
}

extension StopTypeExtension on StopType {
  String get displayName {
    switch (this) {
      case StopType.depart:
        return 'Départ';
      case StopType.intermediaire:
        return 'Intermédiaire';
      case StopType.arrivee:
        return 'Arrivée';
    }
  }

  static StopType fromString(String value) {
    return StopType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => StopType.intermediaire,
    );
  }
}

class RouteStopModel extends Equatable {
  final String id;
  final String routeId;
  final String cityId;
  final int stopOrder;
  final StopType stopType;
  final Duration? durationFromPrevious;
  final double? distanceFromPrevious;
  final Duration? waitingTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RouteStopModel({
    required this.id,
    required this.routeId,
    required this.cityId,
    required this.stopOrder,
    required this.stopType,
    this.durationFromPrevious,
    this.distanceFromPrevious,
    this.waitingTime,
    this.createdAt,
    this.updatedAt,
  });

  factory RouteStopModel.fromMap(Map<String, dynamic> map) {
    return RouteStopModel(
      id: map['id'] as String,
      routeId: map['route_id'] as String,
      cityId: map['city_id'] as String,
      stopOrder: map['stop_order'] as int,
      stopType: StopTypeExtension.fromString(map['stop_type'] as String),
      durationFromPrevious: map['duration_from_previous'] != null
          ? _parseDuration(map['duration_from_previous'])
          : null,
      distanceFromPrevious: map['distance_from_previous'] as double?,
      waitingTime: map['waiting_time'] != null
          ? _parseDuration(map['waiting_time'])
          : null,
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
      'route_id': routeId,
      'city_id': cityId,
      'stop_order': stopOrder,
      'stop_type': stopType.name,
      'duration_from_previous': durationFromPrevious != null
          ? _formatDuration(durationFromPrevious!)
          : null,
      'distance_from_previous': distanceFromPrevious,
      'waiting_time':
          waitingTime != null ? _formatDuration(waitingTime!) : null,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Fonction helper pour parser les durées depuis Supabase (format interval)
  static Duration _parseDuration(dynamic duration) {
    if (duration is String) {
      // Format Supabase pour interval est généralement "HH:MM:SS" ou avec des jours, mois, etc.
      // Exemple simple: parsage de "01:30:00" (1h30m)
      final parts = duration.split(':');
      if (parts.length == 3) {
        return Duration(
          hours: int.parse(parts[0]),
          minutes: int.parse(parts[1]),
          seconds: int.parse(parts[2].split('.')[0]),
        );
      }
    }
    // Si format non reconnu, retourne une durée par défaut (0)
    return Duration.zero;
  }

  // Fonction helper pour formater les durées pour Supabase
  static String _formatDuration(Duration duration) {
    return '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  RouteStopModel copyWith({
    String? id,
    String? routeId,
    String? cityId,
    int? stopOrder,
    StopType? stopType,
    Duration? durationFromPrevious,
    double? distanceFromPrevious,
    Duration? waitingTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RouteStopModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      cityId: cityId ?? this.cityId,
      stopOrder: stopOrder ?? this.stopOrder,
      stopType: stopType ?? this.stopType,
      durationFromPrevious: durationFromPrevious ?? this.durationFromPrevious,
      distanceFromPrevious: distanceFromPrevious ?? this.distanceFromPrevious,
      waitingTime: waitingTime ?? this.waitingTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        routeId,
        cityId,
        stopOrder,
        stopType,
        durationFromPrevious,
        distanceFromPrevious,
        waitingTime,
        createdAt,
        updatedAt,
      ];
} 