import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:mulykap_app/features/buses/data/repositories/city_repository.dart';
import 'package:mulykap_app/features/buses/domain/models/city_model.dart';

// Events
abstract class CityEvent extends Equatable {
  const CityEvent();

  @override
  List<Object?> get props => [];
}

class CityLoadAll extends CityEvent {
  const CityLoadAll();
}

class CityLoadMain extends CityEvent {
  const CityLoadMain();
}

class CityLoadByProvince extends CityEvent {
  final String province;

  const CityLoadByProvince(this.province);

  @override
  List<Object?> get props => [province];
}

class CityLoad extends CityEvent {
  final String id;

  const CityLoad(this.id);

  @override
  List<Object?> get props => [id];
}

class CityCreate extends CityEvent {
  final CityModel city;

  const CityCreate(this.city);

  @override
  List<Object?> get props => [city];
}

class CityUpdate extends CityEvent {
  final CityModel city;

  const CityUpdate(this.city);

  @override
  List<Object?> get props => [city];
}

class CityDelete extends CityEvent {
  final String id;

  const CityDelete(this.id);

  @override
  List<Object?> get props => [id];
}

// States
enum CityStatus { initial, loading, loaded, error }

class CityState extends Equatable {
  final CityStatus status;
  final List<CityModel> cities;
  final CityModel? selectedCity;
  final String? error;

  const CityState({
    this.status = CityStatus.initial,
    this.cities = const [],
    this.selectedCity,
    this.error,
  });

  CityState copyWith({
    CityStatus? status,
    List<CityModel>? cities,
    CityModel? selectedCity,
    String? error,
  }) {
    return CityState(
      status: status ?? this.status,
      cities: cities ?? this.cities,
      selectedCity: selectedCity ?? this.selectedCity,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, cities, selectedCity, error];

  bool get isInitial => status == CityStatus.initial;
  bool get isLoading => status == CityStatus.loading;
  bool get isLoaded => status == CityStatus.loaded;
  bool get isError => status == CityStatus.error;
}

// Bloc
class CityBloc extends Bloc<CityEvent, CityState> {
  final CityRepository _cityRepository;

  CityBloc({required CityRepository cityRepository})
      : _cityRepository = cityRepository,
        super(const CityState()) {
    on<CityLoadAll>(_onCityLoadAll);
    on<CityLoadMain>(_onCityLoadMain);
    on<CityLoadByProvince>(_onCityLoadByProvince);
    on<CityLoad>(_onCityLoad);
    on<CityCreate>(_onCityCreate);
    on<CityUpdate>(_onCityUpdate);
    on<CityDelete>(_onCityDelete);
  }

  Future<void> _onCityLoadAll(CityLoadAll event, Emitter<CityState> emit) async {
    emit(state.copyWith(status: CityStatus.loading));
    try {
      final cities = await _cityRepository.getAllCities();
      emit(state.copyWith(
        status: CityStatus.loaded,
        cities: cities,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CityStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCityLoadMain(CityLoadMain event, Emitter<CityState> emit) async {
    emit(state.copyWith(status: CityStatus.loading));
    try {
      final cities = await _cityRepository.getMainCities();
      emit(state.copyWith(
        status: CityStatus.loaded,
        cities: cities,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CityStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCityLoadByProvince(CityLoadByProvince event, Emitter<CityState> emit) async {
    emit(state.copyWith(status: CityStatus.loading));
    try {
      final cities = await _cityRepository.getCitiesByProvince(event.province);
      emit(state.copyWith(
        status: CityStatus.loaded,
        cities: cities,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CityStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCityLoad(CityLoad event, Emitter<CityState> emit) async {
    emit(state.copyWith(status: CityStatus.loading));
    try {
      final city = await _cityRepository.getCityById(event.id);
      emit(state.copyWith(
        status: CityStatus.loaded,
        selectedCity: city,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CityStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCityCreate(CityCreate event, Emitter<CityState> emit) async {
    emit(state.copyWith(status: CityStatus.loading));
    try {
      final newCity = await _cityRepository.createCity(event.city);
      final updatedCities = List<CityModel>.from(state.cities)..add(newCity);
      emit(state.copyWith(
        status: CityStatus.loaded,
        cities: updatedCities,
        selectedCity: newCity,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CityStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCityUpdate(CityUpdate event, Emitter<CityState> emit) async {
    emit(state.copyWith(status: CityStatus.loading));
    try {
      final updatedCity = await _cityRepository.updateCity(event.city);
      final updatedCities = state.cities.map((city) {
        return city.id == updatedCity.id ? updatedCity : city;
      }).toList();
      emit(state.copyWith(
        status: CityStatus.loaded,
        cities: updatedCities,
        selectedCity: updatedCity,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CityStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCityDelete(CityDelete event, Emitter<CityState> emit) async {
    emit(state.copyWith(status: CityStatus.loading));
    try {
      await _cityRepository.deleteCity(event.id);
      final updatedCities = state.cities.where((city) => city.id != event.id).toList();
      emit(state.copyWith(
        status: CityStatus.loaded,
        cities: updatedCities,
        selectedCity: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CityStatus.error,
        error: e.toString(),
      ));
    }
  }
} 