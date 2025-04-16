import 'package:equatable/equatable.dart';
import 'package:mulykap_app/features/recurring_trips/domain/models/recurring_trip_model.dart';

class RecurringTripState extends Equatable {
  final List<RecurringTripModel> trips;
  final bool isLoading;
  final String? error;
  final RecurrenceType? filterType;

  const RecurringTripState({
    this.trips = const [],
    this.isLoading = false,
    this.error,
    this.filterType,
  });

  // État initial
  factory RecurringTripState.initial() {
    return const RecurringTripState(
      trips: [],
      isLoading: false,
      error: null,
      filterType: null,
    );
  }

  // État de chargement
  RecurringTripState copyWithLoading() {
    return RecurringTripState(
      trips: trips,
      isLoading: true,
      error: null,
      filterType: filterType,
    );
  }

  // État avec nouvelles données
  RecurringTripState copyWithData(List<RecurringTripModel> newTrips) {
    return RecurringTripState(
      trips: newTrips,
      isLoading: false,
      error: null,
      filterType: filterType,
    );
  }

  // État d'erreur
  RecurringTripState copyWithError(String errorMessage) {
    return RecurringTripState(
      trips: trips,
      isLoading: false,
      error: errorMessage,
      filterType: filterType,
    );
  }

  // État avec filtre
  RecurringTripState copyWithFilter(RecurrenceType? type) {
    return RecurringTripState(
      trips: trips,
      isLoading: isLoading,
      error: error,
      filterType: type,
    );
  }

  // Vérifier si l'état contient une erreur
  bool get isError => error != null;

  // Vérifier si des filtres sont actifs
  bool get hasFilters => filterType != null;

  // Liste des voyages filtrés
  List<RecurringTripModel> get filteredTrips {
    if (filterType == null) {
      return trips;
    }
    return trips.where((trip) => trip.recurrenceType == filterType).toList();
  }

  // Liste des voyages actifs
  List<RecurringTripModel> get activeTrips {
    return trips.where((trip) => trip.isActive).toList();
  }

  // Liste des voyages inactifs
  List<RecurringTripModel> get inactiveTrips {
    return trips.where((trip) => !trip.isActive).toList();
  }

  @override
  List<Object?> get props => [
        trips,
        isLoading,
        error,
        filterType,
      ];
} 