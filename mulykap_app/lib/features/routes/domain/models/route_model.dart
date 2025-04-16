import 'package:equatable/equatable.dart';

class RouteModel extends Equatable {
  final String id;
  final String departureCityId;
  final String arrivalCityId;
  final double distanceKm;
  final Duration estimatedDuration;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? departureCityName;
  final String? arrivalCityName;

  const RouteModel({
    required this.id,
    required this.departureCityId,
    required this.arrivalCityId,
    required this.distanceKm,
    required this.estimatedDuration,
    this.createdAt,
    this.updatedAt,
    this.departureCityName,
    this.arrivalCityName,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map) {
    return RouteModel(
      id: map['id'] as String,
      departureCityId: map['departure_city_id'] as String,
      arrivalCityId: map['arrival_city_id'] as String,
      distanceKm: map['distance_km'] as double,
      estimatedDuration: _parseDuration(map['estimated_duration']),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      departureCityName: map['departure_city_name'] as String?,
      arrivalCityName: map['arrival_city_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'departure_city_id': departureCityId,
      'arrival_city_id': arrivalCityId,
      'distance_km': distanceKm,
      'estimated_duration': _formatDuration(estimatedDuration),
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

  RouteModel copyWith({
    String? id,
    String? departureCityId,
    String? arrivalCityId,
    double? distanceKm,
    Duration? estimatedDuration,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? departureCityName,
    String? arrivalCityName,
  }) {
    return RouteModel(
      id: id ?? this.id,
      departureCityId: departureCityId ?? this.departureCityId,
      arrivalCityId: arrivalCityId ?? this.arrivalCityId,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      departureCityName: departureCityName ?? this.departureCityName,
      arrivalCityName: arrivalCityName ?? this.arrivalCityName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        departureCityId,
        arrivalCityId,
        distanceKm,
        estimatedDuration,
        createdAt,
        updatedAt,
        departureCityName,
        arrivalCityName,
      ];

  String get routeDisplayName => '${departureCityName ?? departureCityId} - ${arrivalCityName ?? arrivalCityId}';
} 