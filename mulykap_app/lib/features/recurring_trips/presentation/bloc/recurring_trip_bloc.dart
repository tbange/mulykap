import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/recurring_trips/data/repositories/recurring_trip_repository.dart';
import 'package:mulykap_app/features/recurring_trips/domain/models/recurring_trip_model.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_event.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_state.dart';

class RecurringTripBloc extends Bloc<RecurringTripEvent, RecurringTripState> {
  final RecurringTripRepository _repository;

  RecurringTripBloc({required RecurringTripRepository repository})
      : _repository = repository,
        super(RecurringTripState.initial()) {
    on<RecurringTripLoadAll>(_onLoadAll);
    on<RecurringTripCreate>(_onCreate);
    on<RecurringTripUpdate>(_onUpdate);
    on<RecurringTripDelete>(_onDelete);
    on<RecurringTripToggleStatus>(_onToggleStatus);
    on<RecurringTripFilterByType>(_onFilterByType);
    on<RecurringTripResetFilters>(_onResetFilters);
  }

  Future<void> _onLoadAll(
    RecurringTripLoadAll event,
    Emitter<RecurringTripState> emit,
  ) async {
    try {
      emit(state.copyWithLoading());
      final trips = await _repository.getAllRecurringTrips();
      emit(state.copyWithData(trips));
    } catch (e) {
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onCreate(
    RecurringTripCreate event,
    Emitter<RecurringTripState> emit,
  ) async {
    try {
      emit(state.copyWithLoading());
      await _repository.createRecurringTrip(event.trip);
      final trips = await _repository.getAllRecurringTrips();
      emit(state.copyWithData(trips));
    } catch (e) {
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    RecurringTripUpdate event,
    Emitter<RecurringTripState> emit,
  ) async {
    try {
      emit(state.copyWithLoading());
      await _repository.updateRecurringTrip(event.trip);
      final trips = await _repository.getAllRecurringTrips();
      emit(state.copyWithData(trips));
    } catch (e) {
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onDelete(
    RecurringTripDelete event,
    Emitter<RecurringTripState> emit,
  ) async {
    try {
      emit(state.copyWithLoading());
      await _repository.deleteRecurringTrip(event.id);
      final trips = await _repository.getAllRecurringTrips();
      emit(state.copyWithData(trips));
    } catch (e) {
      emit(state.copyWithError(e.toString()));
    }
  }

  Future<void> _onToggleStatus(
    RecurringTripToggleStatus event,
    Emitter<RecurringTripState> emit,
  ) async {
    try {
      emit(state.copyWithLoading());
      await _repository.toggleRecurringTripStatus(event.id, event.isActive);
      final trips = await _repository.getAllRecurringTrips();
      emit(state.copyWithData(trips));
    } catch (e) {
      emit(state.copyWithError(e.toString()));
    }
  }

  void _onFilterByType(
    RecurringTripFilterByType event,
    Emitter<RecurringTripState> emit,
  ) {
    emit(state.copyWithFilter(event.type));
  }

  void _onResetFilters(
    RecurringTripResetFilters event,
    Emitter<RecurringTripState> emit,
  ) {
    emit(state.copyWithFilter(null));
  }
} 