import 'package:equatable/equatable.dart';

enum RecurrenceType {
  daily,    // Tous les jours
  weekly,   // Toutes les semaines
  monthly;  // Tous les mois

  String get displayName {
    switch (this) {
      case RecurrenceType.daily:
        return 'Quotidien';
      case RecurrenceType.weekly:
        return 'Hebdomadaire';
      case RecurrenceType.monthly:
        return 'Mensuel';
    }
  }
}

class RecurringTripModel extends Equatable {
  final String id;
  final String routeId;
  final String busId;
  final List<int> weekdays;  // Jours de la semaine (1-7)
  final String departureTime;  // Format HH:mm
  final String arrivalTime;    // Format HH:mm
  final double basePrice;
  final bool isActive;
  final DateTime validFrom;
  final DateTime? validUntil;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Propriétés pour les relations
  final String? routeName;
  final String? busPlate;

  const RecurringTripModel({
    required this.id,
    required this.routeId,
    required this.busId,
    required this.weekdays,
    required this.departureTime,
    required this.arrivalTime,
    required this.basePrice,
    required this.validFrom,
    this.validUntil,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.routeName,
    this.busPlate,
  });

  // Déduire le type de récurrence à partir des weekdays
  RecurrenceType get recurrenceType {
    if (weekdays.length == 7) {
      return RecurrenceType.daily;
    } else if (weekdays.every((day) => day <= 7)) {
      return RecurrenceType.weekly;
    } else {
      return RecurrenceType.monthly;
    }
  }

  factory RecurringTripModel.fromMap(Map<String, dynamic> map) {
    // Convertir les valeurs d'énumération en indices de jours
    final List<String> weekdayNames = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    List<int> weekdayIndices = [];
    
    if (map['weekdays'] != null) {
      final List<dynamic> weekdayValues = List<dynamic>.from(map['weekdays']);
      weekdayIndices = weekdayValues.map((day) {
        final int index = weekdayNames.indexOf(day.toString().toLowerCase()) + 1;
        return index > 0 ? index : 1; // Par défaut lundi (1) si la valeur n'est pas reconnue
      }).toList();
    }

    return RecurringTripModel(
      id: map['id'],
      routeId: map['route_id'],
      busId: map['bus_id'],
      weekdays: weekdayIndices,
      departureTime: map['departure_time'],
      arrivalTime: map['arrival_time'],
      basePrice: map['base_price']?.toDouble() ?? 0.0,
      isActive: map['is_active'] ?? true,
      validFrom: DateTime.parse(map['valid_from']),
      validUntil: map['valid_until'] != null ? DateTime.parse(map['valid_until']) : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      routeName: map['route_name'],
      busPlate: map['bus_plate'],
    );
  }

  Map<String, dynamic> toMap() {
    // Convertir les indices de jours de la semaine en valeurs d'énumération
    final List<String> weekdayNames = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    final List<String> weekdayValues = weekdays.map((day) => weekdayNames[day - 1]).toList();

    return {
      'id': id,
      'route_id': routeId,
      'bus_id': busId,
      'weekdays': weekdayValues,
      'departure_time': departureTime,
      'arrival_time': arrivalTime,
      'base_price': basePrice,
      'is_active': isActive,
      'valid_from': '${validFrom.year}-${validFrom.month.toString().padLeft(2, '0')}-${validFrom.day.toString().padLeft(2, '0')}',
      'valid_until': validUntil != null 
          ? '${validUntil!.year}-${validUntil!.month.toString().padLeft(2, '0')}-${validUntil!.day.toString().padLeft(2, '0')}'
          : null,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  RecurringTripModel copyWith({
    String? id,
    String? routeId,
    String? busId,
    List<int>? weekdays,
    String? departureTime,
    String? arrivalTime,
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

  String getWeekdaysText() {
    final weekDays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return weekdays.map((day) => weekDays[day - 1]).join(', ');
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