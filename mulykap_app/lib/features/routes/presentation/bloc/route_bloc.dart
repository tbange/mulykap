import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:mulykap_app/features/routes/domain/models/route_model.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_repository.dart';

part 'route_event.dart';
part 'route_state.dart';

class RouteBloc extends Bloc<RouteEvent, RouteState> {
  final RouteRepository routeRepository;

  RouteBloc({required this.routeRepository}) : super(RouteInitial()) {
    on<LoadRoutes>(_onLoadRoutes);
    on<CreateRoute>(_onCreateRoute);
    on<UpdateRoute>(_onUpdateRoute);
    on<DeleteRoute>(_onDeleteRoute);
    on<SearchRoutes>(_onSearchRoutes);
    
    // Charger automatiquement les routes au démarrage
    add(const LoadRoutes());
  }

  Future<void> _onLoadRoutes(LoadRoutes event, Emitter<RouteState> emit) async {
    debugPrint('RouteBloc: Début du chargement des routes');
    emit(RouteLoading());
    try {
      final routes = await routeRepository.getAllRoutes();
      debugPrint('RouteBloc: ${routes.length} routes chargées avec succès');
      emit(RouteLoaded(routes: routes));
    } catch (e) {
      debugPrint('RouteBloc: Erreur lors du chargement des routes: $e');
      emit(RouteError(message: e.toString()));
    }
  }

  Future<void> _onCreateRoute(CreateRoute event, Emitter<RouteState> emit) async {
    emit(RouteLoading());
    try {
      final route = await routeRepository.createRoute(event.route);
      emit(RouteCreated(route: route));
      
      // Reload the routes list after creation
      add(LoadRoutes());
    } catch (e) {
      emit(RouteError(message: e.toString()));
    }
  }

  Future<void> _onUpdateRoute(UpdateRoute event, Emitter<RouteState> emit) async {
    emit(RouteLoading());
    try {
      final route = await routeRepository.updateRoute(event.route);
      emit(RouteUpdated(route: route));
      
      // Reload the routes list after update
      add(LoadRoutes());
    } catch (e) {
      emit(RouteError(message: e.toString()));
    }
  }

  Future<void> _onDeleteRoute(DeleteRoute event, Emitter<RouteState> emit) async {
    emit(RouteLoading());
    try {
      await routeRepository.deleteRoute(event.routeId);
      emit(RouteDeleted(routeId: event.routeId));
      
      // Reload the routes list after deletion
      add(LoadRoutes());
    } catch (e) {
      emit(RouteError(message: e.toString()));
    }
  }

  Future<void> _onSearchRoutes(SearchRoutes event, Emitter<RouteState> emit) async {
    emit(RouteLoading());
    try {
      final routes = await routeRepository.searchRoutes(
        departureCityId: event.departureCityId,
        arrivalCityId: event.arrivalCityId
      );
      emit(RouteLoaded(routes: routes));
    } catch (e) {
      emit(RouteError(message: e.toString()));
    }
  }
} 