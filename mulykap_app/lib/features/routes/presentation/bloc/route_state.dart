part of 'route_bloc.dart';

abstract class RouteState extends Equatable {
  const RouteState();

  @override
  List<Object?> get props => [];
}

class RouteInitial extends RouteState {}

class RouteLoading extends RouteState {}

class RouteLoaded extends RouteState {
  final List<RouteModel> routes;

  const RouteLoaded({required this.routes});

  @override
  List<Object?> get props => [routes];
}

class RouteCreated extends RouteState {
  final RouteModel route;

  const RouteCreated({required this.route});

  @override
  List<Object?> get props => [route];
}

class RouteUpdated extends RouteState {
  final RouteModel route;

  const RouteUpdated({required this.route});

  @override
  List<Object?> get props => [route];
}

class RouteDeleted extends RouteState {
  final String routeId;

  const RouteDeleted({required this.routeId});

  @override
  List<Object?> get props => [routeId];
}

class RouteError extends RouteState {
  final String message;

  const RouteError({required this.message});

  @override
  List<Object?> get props => [message];
} 