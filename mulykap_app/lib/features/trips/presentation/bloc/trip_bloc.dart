import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/trips/data/repositories/trip_repository.dart';
import 'package:mulykap_app/features/trips/domain/models/trip_model.dart';
import 'package:mulykap_app/features/trips/presentation/bloc/trip_event.dart';
import 'package:mulykap_app/features/trips/presentation/bloc/trip_state.dart';

class TripBloc extends Bloc<TripEvent, TripState> {
  final TripRepository _tripRepository;

  TripBloc({required TripRepository tripRepository})
      : _tripRepository = tripRepository,
        super(TripState.initial()) {
    on<TripLoadAll>(_onTripLoadAll);
    on<TripLoadByRoute>(_onTripLoadByRoute);
    on<TripLoadByBus>(_onTripLoadByBus);
    on<TripLoadByDriver>(_onTripLoadByDriver);
    on<TripCreate>(_onTripCreate);
    on<TripUpdate>(_onTripUpdate);
    on<TripUpdateStatus>(_onTripUpdateStatus);
    on<TripDelete>(_onTripDelete);
    on<TripFilterByStatus>(_onTripFilterByStatus);
    on<TripFilterByDate>(_onTripFilterByDate);
    on<TripResetFilters>(_onTripResetFilters);
  }

  // Charger tous les voyages
  Future<void> _onTripLoadAll(TripLoadAll event, Emitter<TripState> emit) async {
    try {
      emit(state.copyWith(isLoading: true));
      final trips = await _tripRepository.getAllTrips();
      emit(state.copyWith(
        trips: trips,
        isLoading: false,
        errorMessage: null,
      ));
      // Appliquer les filtres existants si nécessaire
      _applyFilters(emit);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  // Charger les voyages d'un itinéraire
  Future<void> _onTripLoadByRoute(TripLoadByRoute event, Emitter<TripState> emit) async {
    emit(state.copyWithLoading());
    try {
      final trips = await _tripRepository.getTripsByRoute(event.routeId);
      emit(state.copyWithData(trips).copyWithFilters(filterRouteId: event.routeId));
    } catch (e) {
      emit(state.copyWithError(e.toString()));
    }
  }

  // Charger les voyages d'un bus
  Future<void> _onTripLoadByBus(TripLoadByBus event, Emitter<TripState> emit) async {
    emit(state.copyWithLoading());
    try {
      final trips = await _tripRepository.getTripsByBus(event.busId);
      emit(state.copyWithData(trips).copyWithFilters(filterBusId: event.busId));
    } catch (e) {
      emit(state.copyWithError(e.toString()));
    }
  }

  // Charger les voyages d'un chauffeur
  Future<void> _onTripLoadByDriver(TripLoadByDriver event, Emitter<TripState> emit) async {
    emit(state.copyWithLoading());
    try {
      final trips = await _tripRepository.getTripsByDriver(event.driverId);
      emit(state.copyWithData(trips).copyWithFilters(filterDriverId: event.driverId));
    } catch (e) {
      emit(state.copyWithError(e.toString()));
    }
  }

  // Créer un voyage
  Future<void> _onTripCreate(TripCreate event, Emitter<TripState> emit) async {
    emit(state.copyWithLoading());
    try {
      await _tripRepository.createTrip(event.trip);
      final trips = await _tripRepository.getAllTrips();
      emit(state.copyWithData(trips));
    } catch (e) {
      emit(state.copyWithError(e.toString()));
    }
  }

  // Mettre à jour un voyage
  Future<void> _onTripUpdate(TripUpdate event, Emitter<TripState> emit) async {
    emit(state.copyWithLoading());
    try {
      await _tripRepository.updateTrip(event.trip);
      final trips = await _tripRepository.getAllTrips();
      emit(state.copyWithData(trips));
    } catch (e) {
      emit(state.copyWithError(e.toString()));
    }
  }

  // Mettre à jour le statut d'un voyage
  Future<void> _onTripUpdateStatus(TripUpdateStatus event, Emitter<TripState> emit) async {
    try {
      emit(state.copyWith(isLoading: true));
      
      // Récupérer le voyage à mettre à jour
      final trip = state.trips.firstWhere((t) => t.id == event.tripId);
      
      // Créer un nouveau voyage avec le statut mis à jour
      final updatedTrip = trip.copyWith(status: event.status);
      
      // Mettre à jour le voyage
      await _tripRepository.updateTrip(updatedTrip);
      
      // Mettre à jour la liste des voyages
      final trips = await _tripRepository.getAllTrips();
      emit(state.copyWith(
        trips: trips,
        isLoading: false,
        errorMessage: null,
      ));
      
      // Réappliquer les filtres
      _applyFilters(emit);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  // Supprimer un voyage
  Future<void> _onTripDelete(TripDelete event, Emitter<TripState> emit) async {
    try {
      emit(state.copyWith(isLoading: true));
      await _tripRepository.deleteTrip(event.tripId);
      
      // Mettre à jour la liste des voyages après suppression
      final trips = await _tripRepository.getAllTrips();
      emit(state.copyWith(
        trips: trips,
        isLoading: false,
        errorMessage: null,
      ));
      
      // Réappliquer les filtres
      _applyFilters(emit);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }

  // Filtrer les voyages par statut
  void _onTripFilterByStatus(TripFilterByStatus event, Emitter<TripState> emit) {
    emit(state.copyWith(statusFilter: event.status));
    _applyFilters(emit);
  }

  // Filtrer les voyages par date
  void _onTripFilterByDate(TripFilterByDate event, Emitter<TripState> emit) {
    emit(state.copyWith(dateFilter: event.date));
    _applyFilters(emit);
  }

  // Réinitialiser tous les filtres
  void _onTripResetFilters(TripResetFilters event, Emitter<TripState> emit) {
    emit(state.copyWith(
      statusFilter: null,
      dateFilter: null,
      filteredTrips: state.trips,
    ));
  }

  // Appliquer les filtres actuels
  void _applyFilters(Emitter<TripState> emit) {
    List<TripModel> filteredTrips = state.trips;

    // Filtrer par statut si défini
    if (state.statusFilter != null) {
      filteredTrips = filteredTrips
          .where((trip) => trip.status == state.statusFilter)
          .toList();
    }

    // Filtrer par date si définie
    if (state.dateFilter != null) {
      filteredTrips = filteredTrips.where((trip) {
        final tripDate = DateTime(
          trip.departureTime.year,
          trip.departureTime.month,
          trip.departureTime.day,
        );
        final filterDate = DateTime(
          state.dateFilter!.year,
          state.dateFilter!.month,
          state.dateFilter!.day,
        );
        return tripDate.isAtSameMomentAs(filterDate);
      }).toList();
    }

    emit(state.copyWith(filteredTrips: filteredTrips));
  }
} 