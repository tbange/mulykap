import 'package:equatable/equatable.dart';
import 'package:mulykap_app/features/buses/domain/models/bus_model.dart';

enum BusStatus { initial, loading, loaded, error }

class BusState extends Equatable {
  final BusStatus status;
  final List<BusModel> buses;
  final BusModel? selectedBus;
  final String? error;

  const BusState({
    this.status = BusStatus.initial,
    this.buses = const [],
    this.selectedBus,
    this.error,
  });

  BusState copyWith({
    BusStatus? status,
    List<BusModel>? buses,
    BusModel? selectedBus,
    String? error,
  }) {
    return BusState(
      status: status ?? this.status,
      buses: buses ?? this.buses,
      selectedBus: selectedBus ?? this.selectedBus,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, buses, selectedBus, error];

  factory BusState.initial() {
    return const BusState();
  }

  factory BusState.loading() {
    return const BusState(status: BusStatus.loading);
  }

  factory BusState.loaded(List<BusModel> buses) {
    return BusState(
      status: BusStatus.loaded,
      buses: buses,
    );
  }

  factory BusState.error(String message) {
    return BusState(
      status: BusStatus.error,
      error: message,
    );
  }

  bool get isInitial => status == BusStatus.initial;
  bool get isLoading => status == BusStatus.loading;
  bool get isLoaded => status == BusStatus.loaded;
  bool get isError => status == BusStatus.error;
} 