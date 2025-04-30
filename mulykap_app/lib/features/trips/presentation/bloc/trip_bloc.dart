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
    on<TripFilterByDateRange>(_onTripFilterByDateRange);
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
        error: null,
        clearError: true,
      ));
      // Appliquer les filtres existants si nécessaire
      _applyFilters(emit);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
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
      final trip = state.trips.firstWhere((t) => t.id == event.id);
      
      // Créer un nouveau voyage avec le statut mis à jour
      final updatedTrip = trip.copyWith(status: event.status);
      
      // Mettre à jour le voyage
      await _tripRepository.updateTrip(updatedTrip);
      
      // Mettre à jour la liste des voyages
      final trips = await _tripRepository.getAllTrips();
      emit(state.copyWith(
        trips: trips,
        isLoading: false,
        error: null,
        clearError: true,
      ));
      
      // Réappliquer les filtres
      _applyFilters(emit);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Supprimer un voyage
  Future<void> _onTripDelete(TripDelete event, Emitter<TripState> emit) async {
    try {
      emit(state.copyWith(isLoading: true));
      await _tripRepository.deleteTrip(event.id);
      
      // Mettre à jour la liste des voyages après suppression
      final trips = await _tripRepository.getAllTrips();
      emit(state.copyWith(
        trips: trips,
        isLoading: false,
        error: null,
        clearError: true,
      ));
      
      // Réappliquer les filtres
      _applyFilters(emit);
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Filtrer les voyages par statut
  void _onTripFilterByStatus(TripFilterByStatus event, Emitter<TripState> emit) {
    // Conserver les filtres de date actuels tout en mettant à jour le filtre de statut
    final TripState newState = state.copyWith(
      filterStatus: event.status,
      // Ne pas effacer les filtres de date existants
      filterDate: state.filterDate,
      filterStartDate: state.filterStartDate,
      filterEndDate: state.filterEndDate,
    );
    
    emit(newState);
    _applyFilters(emit);
  }

  // Filtrer les voyages par date
  void _onTripFilterByDate(TripFilterByDate event, Emitter<TripState> emit) {
    // Conserver le filtre de statut tout en mettant à jour le filtre de date
    emit(state.copyWith(
      filterDate: event.date, 
      // Réinitialiser les filtres de plage de dates
      filterStartDate: null,
      filterEndDate: null,
      // Conserver le filtre de statut
      filterStatus: state.filterStatus,
    ));
    _applyFilters(emit);
  }
  
  // Filtrer par plage de dates
  Future<void> _onTripFilterByDateRange(TripFilterByDateRange event, Emitter<TripState> emit) async {
    try {
      emit(state.copyWith(isLoading: true));
      
      // Utiliser la nouvelle méthode du repository pour récupérer les voyages dans une plage de dates
      final trips = await _tripRepository.getTripsByDateRange(event.startDate, event.endDate);
      
      emit(state.copyWith(
        trips: trips,
        isLoading: false,
        error: null,
        clearError: true,
        // Mettre à jour les filtres de plage de dates
        filterStartDate: event.startDate,
        filterEndDate: event.endDate,
        // Réinitialiser le filtre de date unique
        filterDate: null,
        // Conserver le filtre de statut
        filterStatus: state.filterStatus,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  // Réinitialiser tous les filtres
  void _onTripResetFilters(TripResetFilters event, Emitter<TripState> emit) {
    // Réinitialiser tous les filtres mais conserver la liste des voyages chargés
    final newState = state.copyWith(
      filterRouteId: null,
      filterBusId: null,
      filterDriverId: null,
      filterStatus: null,
      filterDate: null,
      filterStartDate: null,
      filterEndDate: null,
    );
    emit(newState);
  }

  // Appliquer les filtres actuels
  void _applyFilters(Emitter<TripState> emit) {
    // La logique de filtrage est maintenant gérée dans le getter filteredTrips de l'état
    // Nous devons simplement émettre un nouveau state pour forcer la mise à jour de l'UI
    emit(state.copyWith());
  }
} 