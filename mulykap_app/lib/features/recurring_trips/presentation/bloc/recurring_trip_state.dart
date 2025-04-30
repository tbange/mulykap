import 'package:equatable/equatable.dart';
import 'package:mulykap_app/features/recurring_trips/domain/models/recurring_trip_model.dart';

enum TripGenerationStatus {
  initial,
  generating,
  success,
  error
}

class RecurringTripState extends Equatable {
  final List<RecurringTripModel> trips;
  final bool isLoading;
  final String? error;
  final RecurrenceType? filterType;
  final TripGenerationStatus generationStatus;
  final int? generatedTripsCount;
  final String? generationError;

  const RecurringTripState({
    this.trips = const [],
    this.isLoading = false,
    this.error,
    this.filterType,
    this.generationStatus = TripGenerationStatus.initial,
    this.generatedTripsCount,
    this.generationError,
  });

  // État initial
  factory RecurringTripState.initial() {
    return const RecurringTripState(
      trips: [],
      isLoading: false,
      error: null,
      filterType: null,
      generationStatus: TripGenerationStatus.initial,
      generatedTripsCount: null,
      generationError: null,
    );
  }

  // État de chargement
  RecurringTripState copyWithLoading() {
    return RecurringTripState(
      trips: trips,
      isLoading: true,
      error: null,
      filterType: filterType,
      generationStatus: generationStatus,
      generatedTripsCount: generatedTripsCount,
      generationError: generationError,
    );
  }

  // État avec nouvelles données
  RecurringTripState copyWithData(List<RecurringTripModel> newTrips) {
    return RecurringTripState(
      trips: newTrips,
      isLoading: false,
      error: null,
      filterType: filterType,
      generationStatus: generationStatus,
      generatedTripsCount: generatedTripsCount,
      generationError: generationError,
    );
  }

  // État d'erreur
  RecurringTripState copyWithError(String errorMessage) {
    return RecurringTripState(
      trips: trips,
      isLoading: false,
      error: errorMessage,
      filterType: filterType,
      generationStatus: generationStatus,
      generatedTripsCount: generatedTripsCount,
      generationError: generationError,
    );
  }

  // État avec filtre
  RecurringTripState copyWithFilter(RecurrenceType? type) {
    return RecurringTripState(
      trips: trips,
      isLoading: isLoading,
      error: error,
      filterType: type,
      generationStatus: generationStatus,
      generatedTripsCount: generatedTripsCount,
      generationError: generationError,
    );
  }

  // État de génération en cours
  RecurringTripState copyWithGenerating() {
    return RecurringTripState(
      trips: trips,
      isLoading: isLoading,
      error: error,
      filterType: filterType,
      generationStatus: TripGenerationStatus.generating,
      generatedTripsCount: generatedTripsCount,
      generationError: null,
    );
  }

  // État de génération réussie
  RecurringTripState copyWithGenerationSuccess(int count) {
    return RecurringTripState(
      trips: trips,
      isLoading: isLoading,
      error: error,
      filterType: filterType,
      generationStatus: TripGenerationStatus.success,
      generatedTripsCount: count,
      generationError: null,
    );
  }

  // État d'erreur de génération
  RecurringTripState copyWithGenerationError(String errorMessage) {
    return RecurringTripState(
      trips: trips,
      isLoading: isLoading,
      error: error,
      filterType: filterType,
      generationStatus: TripGenerationStatus.error,
      generatedTripsCount: generatedTripsCount,
      generationError: errorMessage,
    );
  }

  // État avec réinitialisation de la génération
  RecurringTripState copyWithResetGeneration() {
    return RecurringTripState(
      trips: trips,
      isLoading: isLoading,
      error: error,
      filterType: filterType,
      generationStatus: TripGenerationStatus.initial,
      generatedTripsCount: null,
      generationError: null,
    );
  }

  // Vérifier si l'état contient une erreur
  bool get isError => error != null;

  // Vérifier si des filtres sont actifs
  bool get hasFilters => filterType != null;

  // Vérifier si la génération est en cours
  bool get isGenerating => generationStatus == TripGenerationStatus.generating;

  // Vérifier si la génération a réussi
  bool get isGenerationSuccess => generationStatus == TripGenerationStatus.success;

  // Vérifier si la génération a échoué
  bool get isGenerationError => generationStatus == TripGenerationStatus.error;

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
        generationStatus,
        generatedTripsCount,
        generationError,
      ];
} 