import 'package:equatable/equatable.dart';

/// Les jours de la semaine pour les voyages récurrents
enum Weekday {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  String get displayName {
    switch (this) {
      case Weekday.monday:
        return 'Lundi';
      case Weekday.tuesday:
        return 'Mardi';
      case Weekday.wednesday:
        return 'Mercredi';
      case Weekday.thursday:
        return 'Jeudi';
      case Weekday.friday:
        return 'Vendredi';
      case Weekday.saturday:
        return 'Samedi';
      case Weekday.sunday:
        return 'Dimanche';
    }
  }

  static Weekday fromInt(int value) {
    return Weekday.values[value - 1]; // 1=monday, 7=sunday
  }
  
  int toInt() {
    return index + 1; // 1=monday, 7=sunday
  }
}

/// Modèle représentant un voyage récurrent
class RecurringTripModel extends Equatable {
  final String id;
  final String routeId;
  final String? busId;
  final List<Weekday> weekdays;
  final DateTime departureTime; // Nous utilisons DateTime pour stocker le temps
  final DateTime arrivalTime; // Nous utilisons DateTime pour stocker le temps
  final double basePrice;
  final bool isActive;
  final DateTime validFrom;
  final DateTime validUntil;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Propriétés pour les relations (non stockées directement dans la table)
  final String? routeName;
  final String? busPlate;

  const RecurringTripModel({
    required this.id,
    required this.routeId,
    this.busId,
    required this.weekdays,
    required this.departureTime,
    required this.arrivalTime,
    required this.basePrice,
    required this.isActive,
    required this.validFrom,
    required this.validUntil,
    this.createdAt,
    this.updatedAt,
    this.routeName,
    this.busPlate,
  });

  /// Factory constructor pour créer un modèle à partir d'une map
  factory RecurringTripModel.fromMap(Map<String, dynamic> map) {
    // Conversion de la liste d'entiers (1-7) en enum Weekday
    List<Weekday> weekdaysList = [];
    if (map['weekdays'] != null && map['weekdays'] is List) {
      weekdaysList = List<int>.from(map['weekdays'])
          .map((day) => Weekday.fromInt(day))
          .toList();
    }

    // Pour les champs de temps, nous créons des DateTime en fixant la date à aujourd'hui
    final now = DateTime.now();
    final departureTimeString = map['departure_time'] as String;
    final arrivalTimeString = map['arrival_time'] as String;
    
    // Format: "HH:MM:SS"
    final departureTimeParts = departureTimeString.split(':');
    final arrivalTimeParts = arrivalTimeString.split(':');
    
    final departureTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(departureTimeParts[0]),
      int.parse(departureTimeParts[1]),
    );
    
    final arrivalTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(arrivalTimeParts[0]),
      int.parse(arrivalTimeParts[1]),
    );

    return RecurringTripModel(
      id: map['id'],
      routeId: map['route_id'],
      busId: map['bus_id'],
      weekdays: weekdaysList,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      basePrice: map['base_price']?.toDouble() ?? 0.0,
      isActive: map['is_active'] ?? true,
      validFrom: DateTime.parse(map['valid_from']),
      validUntil: DateTime.parse(map['valid_until']),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      routeName: map['route_name'],
      busPlate: map['bus_plate'],
    );
  }

  /// Convertir en map pour la base de données
  Map<String, dynamic> toMap() {
    // Conversion de la liste d'enum Weekday en entiers (1-7)
    final List<int> weekdaysInt = weekdays.map((w) => w.toInt()).toList();

    // Format de temps pour la base de données: "HH:MM:SS"
    final departureTimeString = 
        '${departureTime.hour.toString().padLeft(2, '0')}:${departureTime.minute.toString().padLeft(2, '0')}:00';
    final arrivalTimeString = 
        '${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}:00';

    return {
      'id': id,
      'route_id': routeId,
      'bus_id': busId,
      'weekdays': weekdaysInt,
      'departure_time': departureTimeString,
      'arrival_time': arrivalTimeString,
      'base_price': basePrice,
      'is_active': isActive,
      'valid_from': validFrom.toIso8601String().split('T')[0], // YYYY-MM-DD
      'valid_until': validUntil.toIso8601String().split('T')[0], // YYYY-MM-DD
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Créer une copie de ce modèle avec des modifications
  RecurringTripModel copyWith({
    String? id,
    String? routeId,
    String? busId,
    List<Weekday>? weekdays,
    DateTime? departureTime,
    DateTime? arrivalTime,
    double? basePrice,
    bool? isActive,
    DateTime? validFrom,
    DateTime? validUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? routeName,
    String? busPlate,
  }) {
    return RecurringTripModel(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      busId: busId ?? this.busId,
      weekdays: weekdays ?? this.weekdays,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      basePrice: basePrice ?? this.basePrice,
      isActive: isActive ?? this.isActive,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      routeName: routeName ?? this.routeName,
      busPlate: busPlate ?? this.busPlate,
    );
  }

  /// Liste formatée des jours de la semaine
  String get weekdaysDisplay {
    return weekdays.map((w) => w.displayName).join(', ');
  }

  @override
  List<Object?> get props => [
        id,
        routeId,
        busId,
        weekdays,
        departureTime,
        arrivalTime,
        basePrice,
        isActive,
        validFrom,
        validUntil,
        createdAt,
        updatedAt,
        routeName,
        busPlate,
      ];
} 