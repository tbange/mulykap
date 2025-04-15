part of 'route_bloc.dart';

abstract class RouteEvent extends Equatable {
  const RouteEvent();

  @override
  List<Object?> get props => [];
}

class LoadRoutes extends RouteEvent {
  const LoadRoutes();
}

class CreateRoute extends RouteEvent {
  final RouteModel route;

  const CreateRoute({required this.route});

  @override
  List<Object?> get props => [route];
}

class UpdateRoute extends RouteEvent {
  final RouteModel route;

  const UpdateRoute({required this.route});

  @override
  List<Object?> get props => [route];
}

class DeleteRoute extends RouteEvent {
  final String routeId;

  const DeleteRoute({required this.routeId});

  @override
  List<Object?> get props => [routeId];
}

class SearchRoutes extends RouteEvent {
  final String? departureCityId;
  final String? arrivalCityId;

  const SearchRoutes({
    this.departureCityId,
    this.arrivalCityId,
  });

  @override
  List<Object?> get props => [departureCityId, arrivalCityId];
} 