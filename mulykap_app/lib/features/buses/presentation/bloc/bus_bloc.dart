import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/buses/data/repositories/bus_repository.dart';
import 'package:mulykap_app/features/buses/domain/models/bus_model.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/bus_event.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/bus_state.dart';

class BusBloc extends Bloc<BusEvent, BusState> {
  final BusRepository _busRepository;

  BusBloc({required BusRepository busRepository})
      : _busRepository = busRepository,
        super(BusState.initial()) {
    on<BusLoadAll>(_onBusLoadAll);
    on<BusLoadByAgency>(_onBusLoadByAgency);
    on<BusLoad>(_onBusLoad);
    on<BusCreate>(_onBusCreate);
    on<BusUpdate>(_onBusUpdate);
    on<BusDelete>(_onBusDelete);
  }

  Future<void> _onBusLoadAll(BusLoadAll event, Emitter<BusState> emit) async {
    emit(BusState.loading());
    try {
      final buses = await _busRepository.getAllBuses();
      emit(BusState.loaded(buses));
    } catch (e) {
      emit(BusState.error(e.toString()));
    }
  }

  Future<void> _onBusLoadByAgency(
      BusLoadByAgency event, Emitter<BusState> emit) async {
    emit(BusState.loading());
    try {
      final buses = await _busRepository.getBusesByAgency(event.agencyId);
      emit(BusState.loaded(buses));
    } catch (e) {
      emit(BusState.error(e.toString()));
    }
  }

  Future<void> _onBusLoad(BusLoad event, Emitter<BusState> emit) async {
    emit(state.copyWith(status: BusStatus.loading));
    try {
      final bus = await _busRepository.getBusById(event.id);
      emit(state.copyWith(
        status: BusStatus.loaded,
        selectedBus: bus,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BusStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onBusCreate(BusCreate event, Emitter<BusState> emit) async {
    emit(state.copyWith(status: BusStatus.loading));
    try {
      final newBus = await _busRepository.createBus(event.bus);
      final updatedBuses = List<BusModel>.from(state.buses)..add(newBus);
      emit(state.copyWith(
        status: BusStatus.loaded,
        buses: updatedBuses,
        selectedBus: newBus,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BusStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onBusUpdate(BusUpdate event, Emitter<BusState> emit) async {
    emit(state.copyWith(status: BusStatus.loading));
    try {
      final updatedBus = await _busRepository.updateBus(event.bus);
      final updatedBuses = state.buses.map((bus) {
        return bus.id == updatedBus.id ? updatedBus : bus;
      }).toList();
      emit(state.copyWith(
        status: BusStatus.loaded,
        buses: updatedBuses,
        selectedBus: updatedBus,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BusStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onBusDelete(BusDelete event, Emitter<BusState> emit) async {
    emit(state.copyWith(status: BusStatus.loading));
    try {
      await _busRepository.deleteBus(event.id);
      final updatedBuses = state.buses.where((bus) => bus.id != event.id).toList();
      emit(state.copyWith(
        status: BusStatus.loaded,
        buses: updatedBuses,
        selectedBus: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BusStatus.error,
        error: e.toString(),
      ));
    }
  }
} 