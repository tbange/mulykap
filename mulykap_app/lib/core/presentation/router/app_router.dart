import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/recurring_trips/data/repositories/recurring_trip_repository.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_bloc.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/screens/recurring_trip_create_screen.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/screens/recurring_trip_list_screen.dart';

class AppRouter {
  static const String recurringTrips = '/recurring-trips';
  static const String createRecurringTrip = '/recurring-trips/create';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case recurringTrips:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => RecurringTripBloc(
              repository: context.read<RecurringTripRepository>(),
            ),
            child: const RecurringTripListScreen(),
          ),
        );

      case createRecurringTrip:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => RecurringTripBloc(
              repository: context.read<RecurringTripRepository>(),
            ),
            child: const RecurringTripCreateScreen(),
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route non trouvée: ${settings.name}'),
            ),
          ),
        );
    }
  }
} 