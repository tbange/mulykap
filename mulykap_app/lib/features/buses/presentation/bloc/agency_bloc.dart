import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mulykap_app/features/buses/data/repositories/agency_repository.dart';
import 'package:mulykap_app/features/buses/domain/models/agency_model.dart';

// Events
abstract class AgencyEvent extends Equatable {
  const AgencyEvent();

  @override
  List<Object?> get props => [];
}

class AgencyLoadAll extends AgencyEvent {
  const AgencyLoadAll();
}

class AgencyLoadByCity extends AgencyEvent {
  final String cityId;

  const AgencyLoadByCity(this.cityId);

  @override
  List<Object?> get props => [cityId];
}

class AgencyLoad extends AgencyEvent {
  final String id;

  const AgencyLoad(this.id);

  @override
  List<Object?> get props => [id];
}

class AgencyCreate extends AgencyEvent {
  final AgencyModel agency;

  const AgencyCreate(this.agency);

  @override
  List<Object?> get props => [agency];
}

class AgencyUpdate extends AgencyEvent {
  final AgencyModel agency;

  const AgencyUpdate(this.agency);

  @override
  List<Object?> get props => [agency];
}

class AgencyDelete extends AgencyEvent {
  final String id;

  const AgencyDelete(this.id);

  @override
  List<Object?> get props => [id];
}

// States
enum AgencyStatus { initial, loading, loaded, error }

class AgencyState extends Equatable {
  final AgencyStatus status;
  final List<AgencyModel> agencies;
  final AgencyModel? selectedAgency;
  final String? error;

  const AgencyState({
    this.status = AgencyStatus.initial,
    this.agencies = const [],
    this.selectedAgency,
    this.error,
  });

  AgencyState copyWith({
    AgencyStatus? status,
    List<AgencyModel>? agencies,
    AgencyModel? selectedAgency,
    String? error,
  }) {
    return AgencyState(
      status: status ?? this.status,
      agencies: agencies ?? this.agencies,
      selectedAgency: selectedAgency ?? this.selectedAgency,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, agencies, selectedAgency, error];

  bool get isInitial => status == AgencyStatus.initial;
  bool get isLoading => status == AgencyStatus.loading;
  bool get isLoaded => status == AgencyStatus.loaded;
  bool get isError => status == AgencyStatus.error;
}

// Bloc
class AgencyBloc extends Bloc<AgencyEvent, AgencyState> {
  final AgencyRepository _agencyRepository;

  AgencyBloc({required AgencyRepository agencyRepository})
      : _agencyRepository = agencyRepository,
        super(const AgencyState()) {
    on<AgencyLoadAll>(_onAgencyLoadAll);
    on<AgencyLoadByCity>(_onAgencyLoadByCity);
    on<AgencyLoad>(_onAgencyLoad);
    on<AgencyCreate>(_onAgencyCreate);
    on<AgencyUpdate>(_onAgencyUpdate);
    on<AgencyDelete>(_onAgencyDelete);
  }

  Future<void> _onAgencyLoadAll(AgencyLoadAll event, Emitter<AgencyState> emit) async {
    emit(state.copyWith(status: AgencyStatus.loading));
    try {
      final agencies = await _agencyRepository.getAllAgencies();
      emit(state.copyWith(
        status: AgencyStatus.loaded,
        agencies: agencies,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AgencyStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onAgencyLoadByCity(
      AgencyLoadByCity event, Emitter<AgencyState> emit) async {
    emit(state.copyWith(status: AgencyStatus.loading));
    try {
      final agencies = await _agencyRepository.getAgenciesByCity(event.cityId);
      emit(state.copyWith(
        status: AgencyStatus.loaded,
        agencies: agencies,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AgencyStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onAgencyLoad(AgencyLoad event, Emitter<AgencyState> emit) async {
    emit(state.copyWith(status: AgencyStatus.loading));
    try {
      final agency = await _agencyRepository.getAgencyById(event.id);
      emit(state.copyWith(
        status: AgencyStatus.loaded,
        selectedAgency: agency,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AgencyStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onAgencyCreate(AgencyCreate event, Emitter<AgencyState> emit) async {
    emit(state.copyWith(status: AgencyStatus.loading));
    try {
      final newAgency = await _agencyRepository.createAgency(event.agency);
      final updatedAgencies = List<AgencyModel>.from(state.agencies)..add(newAgency);
      emit(state.copyWith(
        status: AgencyStatus.loaded,
        agencies: updatedAgencies,
        selectedAgency: newAgency,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AgencyStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onAgencyUpdate(AgencyUpdate event, Emitter<AgencyState> emit) async {
    emit(state.copyWith(status: AgencyStatus.loading));
    try {
      final updatedAgency = await _agencyRepository.updateAgency(event.agency);
      final updatedAgencies = state.agencies.map((agency) {
        return agency.id == updatedAgency.id ? updatedAgency : agency;
      }).toList();
      emit(state.copyWith(
        status: AgencyStatus.loaded,
        agencies: updatedAgencies,
        selectedAgency: updatedAgency,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AgencyStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onAgencyDelete(AgencyDelete event, Emitter<AgencyState> emit) async {
    emit(state.copyWith(status: AgencyStatus.loading));
    try {
      await _agencyRepository.deleteAgency(event.id);
      final updatedAgencies = state.agencies.where((agency) => agency.id != event.id).toList();
      emit(state.copyWith(
        status: AgencyStatus.loaded,
        agencies: updatedAgencies,
        selectedAgency: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AgencyStatus.error,
        error: e.toString(),
      ));
    }
  }
} 