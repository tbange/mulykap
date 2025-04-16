import 'package:equatable/equatable.dart';
import 'package:mulykap_app/features/trips/domain/models/trip_model.dart';

abstract class TripEvent extends Equatable {
  const TripEvent();

  @override
  List<Object?> get props => [];
}

// Événement pour charger tous les voyages
class TripLoadAll extends TripEvent {}

// Événement pour charger les voyages d'un itinéraire
class TripLoadByRoute extends TripEvent {
  final String routeId;

  const TripLoadByRoute(this.routeId);

  @override
  List<Object?> get props => [routeId];
}

// Événement pour charger les voyages d'un bus
class TripLoadByBus extends TripEvent {
  final String busId;

  const TripLoadByBus(this.busId);

  @override
  List<Object?> get props => [busId];
}

// Événement pour charger les voyages d'un chauffeur
class TripLoadByDriver extends TripEvent {
  final String driverId;

  const TripLoadByDriver(this.driverId);

  @override
  List<Object?> get props => [driverId];
}

// Événement pour créer un voyage
class TripCreate extends TripEvent {
  final TripModel trip;

  const TripCreate(this.trip);

  @override
  List<Object?> get props => [trip];
}

// Événement pour mettre à jour un voyage
class TripUpdate extends TripEvent {
  final TripModel trip;

  const TripUpdate(this.trip);

  @override
  List<Object?> get props => [trip];
}

// Événement pour mettre à jour le statut d'un voyage
class TripUpdateStatus extends TripEvent {
  final String id;
  final TripStatus status;

  const TripUpdateStatus({
    required this.id,
    required this.status,
  });

  @override
  List<Object?> get props => [id, status];
}

// Événement pour supprimer un voyage
class TripDelete extends TripEvent {
  final String id;

  const TripDelete(this.id);

  @override
  List<Object?> get props => [id];
}

// Événement pour filtrer les voyages par statut
class TripFilterByStatus extends TripEvent {
  final TripStatus status;

  const TripFilterByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

// Événement pour filtrer les voyages par date
class TripFilterByDate extends TripEvent {
  final DateTime date;

  const TripFilterByDate(this.date);

  @override
  List<Object?> get props => [date];
}

// Événement pour réinitialiser tous les filtres
class TripResetFilters extends TripEvent {} 