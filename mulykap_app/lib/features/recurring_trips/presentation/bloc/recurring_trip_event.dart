import 'package:equatable/equatable.dart';
import 'package:mulykap_app/features/recurring_trips/domain/models/recurring_trip_model.dart';

abstract class RecurringTripEvent extends Equatable {
  const RecurringTripEvent();

  @override
  List<Object?> get props => [];
}

// Événement pour charger tous les voyages récurrents
class RecurringTripLoadAll extends RecurringTripEvent {}

// Événement pour créer un voyage récurrent
class RecurringTripCreate extends RecurringTripEvent {
  final RecurringTripModel trip;

  const RecurringTripCreate(this.trip);

  @override
  List<Object?> get props => [trip];
}

// Événement pour mettre à jour un voyage récurrent
class RecurringTripUpdate extends RecurringTripEvent {
  final RecurringTripModel trip;

  const RecurringTripUpdate(this.trip);

  @override
  List<Object?> get props => [trip];
}

// Événement pour supprimer un voyage récurrent
class RecurringTripDelete extends RecurringTripEvent {
  final String id;

  const RecurringTripDelete(this.id);

  @override
  List<Object?> get props => [id];
}

// Événement pour activer/désactiver un voyage récurrent
class RecurringTripToggleStatus extends RecurringTripEvent {
  final String id;
  final bool isActive;

  const RecurringTripToggleStatus({
    required this.id,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, isActive];
}

// Événement pour filtrer les voyages récurrents par type de récurrence
class RecurringTripFilterByType extends RecurringTripEvent {
  final RecurrenceType type;

  const RecurringTripFilterByType(this.type);

  @override
  List<Object?> get props => [type];
}

// Événement pour réinitialiser les filtres
class RecurringTripResetFilters extends RecurringTripEvent {}

// Événement pour générer des voyages réels à partir d'un modèle récurrent
class RecurringTripGenerateTrips extends RecurringTripEvent {
  final String recurringTripId;
  final DateTime startDate;
  final DateTime endDate;
  final String? driverId;

  const RecurringTripGenerateTrips({
    required this.recurringTripId,
    required this.startDate,
    required this.endDate,
    this.driverId,
  });

  @override
  List<Object?> get props => [recurringTripId, startDate, endDate, driverId];
}

// Événement pour générer des voyages réels à partir de tous les modèles récurrents actifs
class RecurringTripGenerateAllTrips extends RecurringTripEvent {
  final DateTime startDate;
  final DateTime endDate;

  const RecurringTripGenerateAllTrips({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
} 