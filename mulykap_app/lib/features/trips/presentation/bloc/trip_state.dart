import 'package:equatable/equatable.dart';
import 'package:mulykap_app/features/trips/domain/models/trip_model.dart';

class TripState extends Equatable {
  final List<TripModel> trips;
  final bool isLoading;
  final String? error;
  final String? filterRouteId;
  final String? filterBusId;
  final String? filterDriverId;
  final TripStatus? filterStatus;
  final DateTime? filterDate;

  const TripState({
    this.trips = const [],
    this.isLoading = false,
    this.error,
    this.filterRouteId,
    this.filterBusId,
    this.filterDriverId,
    this.filterStatus,
    this.filterDate,
  });

  // État initial
  factory TripState.initial() {
    return const TripState(
      trips: [],
      isLoading: false,
      error: null,
      filterRouteId: null,
      filterBusId: null,
      filterDriverId: null,
      filterStatus: null,
      filterDate: null,
    );
  }

  // État de chargement
  TripState copyWithLoading() {
    return TripState(
      trips: trips,
      isLoading: true,
      error: null,
      filterRouteId: filterRouteId,
      filterBusId: filterBusId,
      filterDriverId: filterDriverId,
      filterStatus: filterStatus,
      filterDate: filterDate,
    );
  }

  // État avec nouvelles données
  TripState copyWithData(List<TripModel> newTrips) {
    return TripState(
      trips: newTrips,
      isLoading: false,
      error: null,
      filterRouteId: filterRouteId,
      filterBusId: filterBusId,
      filterDriverId: filterDriverId,
      filterStatus: filterStatus,
      filterDate: filterDate,
    );
  }

  // État d'erreur
  TripState copyWithError(String errorMessage) {
    return TripState(
      trips: trips,
      isLoading: false,
      error: errorMessage,
      filterRouteId: filterRouteId,
      filterBusId: filterBusId,
      filterDriverId: filterDriverId,
      filterStatus: filterStatus,
      filterDate: filterDate,
    );
  }

  // État avec filtres
  TripState copyWithFilters({
    String? filterRouteId,
    String? filterBusId,
    String? filterDriverId,
    TripStatus? filterStatus,
    DateTime? filterDate,
  }) {
    return TripState(
      trips: trips,
      isLoading: isLoading,
      error: error,
      filterRouteId: filterRouteId ?? this.filterRouteId,
      filterBusId: filterBusId ?? this.filterBusId,
      filterDriverId: filterDriverId ?? this.filterDriverId,
      filterStatus: filterStatus ?? this.filterStatus,
      filterDate: filterDate ?? this.filterDate,
    );
  }

  // État avec réinitialisation des filtres
  TripState copyWithResetFilters() {
    return TripState(
      trips: trips,
      isLoading: isLoading,
      error: error,
      filterRouteId: null,
      filterBusId: null,
      filterDriverId: null,
      filterStatus: null,
      filterDate: null,
    );
  }

  // Vérifier si l'état contient une erreur
  bool get isError => error != null;

  // Vérifier si des filtres sont actifs
  bool get hasFilters =>
      filterRouteId != null ||
      filterBusId != null ||
      filterDriverId != null ||
      filterStatus != null ||
      filterDate != null;

  // Liste des voyages filtrés
  List<TripModel> get filteredTrips {
    List<TripModel> filteredList = List.from(trips);

    if (filterRouteId != null) {
      filteredList = filteredList.where((trip) => trip.routeId == filterRouteId).toList();
    }

    if (filterBusId != null) {
      filteredList = filteredList.where((trip) => trip.busId == filterBusId).toList();
    }

    if (filterDriverId != null) {
      filteredList = filteredList.where((trip) => trip.driverId == filterDriverId).toList();
    }

    if (filterStatus != null) {
      filteredList = filteredList.where((trip) => trip.status == filterStatus).toList();
    }

    if (filterDate != null) {
      filteredList = filteredList.where((trip) {
        final tripDate = DateTime(
          trip.departureTime.year,
          trip.departureTime.month,
          trip.departureTime.day,
        );
        final filter = DateTime(
          filterDate!.year,
          filterDate!.month,
          filterDate!.day,
        );
        return tripDate.isAtSameMomentAs(filter);
      }).toList();
    }

    return filteredList;
  }

  @override
  List<Object?> get props => [
        trips,
        isLoading,
        error,
        filterRouteId,
        filterBusId,
        filterDriverId,
        filterStatus,
        filterDate,
      ];
} 