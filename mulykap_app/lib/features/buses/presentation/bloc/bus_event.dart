import 'package:equatable/equatable.dart';
import 'package:mulykap_app/features/buses/domain/models/bus_model.dart';

abstract class BusEvent extends Equatable {
  const BusEvent();

  @override
  List<Object?> get props => [];
}

class BusLoadAll extends BusEvent {
  const BusLoadAll();
}

class BusLoadByAgency extends BusEvent {
  final String agencyId;

  const BusLoadByAgency(this.agencyId);

  @override
  List<Object?> get props => [agencyId];
}

class BusLoad extends BusEvent {
  final String id;

  const BusLoad(this.id);

  @override
  List<Object?> get props => [id];
}

class BusCreate extends BusEvent {
  final BusModel bus;

  const BusCreate(this.bus);

  @override
  List<Object?> get props => [bus];
}

class BusUpdate extends BusEvent {
  final BusModel bus;

  const BusUpdate(this.bus);

  @override
  List<Object?> get props => [bus];
}

class BusDelete extends BusEvent {
  final String id;

  const BusDelete(this.id);

  @override
  List<Object?> get props => [id];
} 