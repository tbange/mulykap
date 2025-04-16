import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/core/presentation/router/app_router.dart';
import 'package:mulykap_app/features/auth/data/repositories/auth_repository.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mulykap_app/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:mulykap_app/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:mulykap_app/features/buses/data/repositories/city_repository.dart';
import 'package:mulykap_app/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_repository.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_stop_repository.dart';
import 'package:mulykap_app/features/recurring_trips/data/repositories/recurring_trip_repository.dart';
import 'package:mulykap_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MulykapApp extends StatelessWidget {
  const MulykapApp({super.key});

  @override
  Widget build(BuildContext context) {
    final SupabaseClient supabaseClient = Supabase.instance.client;
    final authRepository = AuthRepository();
    
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<RouteRepository>(
          create: (context) => RouteRepository(
            supabaseClient: supabaseClient,
          ),
        ),
        RepositoryProvider<RouteStopRepository>(
          create: (context) => RouteStopRepository(
            supabaseClient: supabaseClient,
          ),
        ),
        RepositoryProvider<CityRepository>(
          create: (context) => CityRepository(
            supabaseClient: supabaseClient,
          ),
        ),
        RepositoryProvider<RecurringTripRepository>(
          create: (context) => RecurringTripRepository(
            supabaseClient: supabaseClient,
          ),
        ),
      ],
      child: BlocProvider<AuthBloc>(
        create: (context) => AuthBloc(
          authRepository: authRepository,
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'MulyKap',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3D5AF1),
              secondary: const Color(0xFFFF9800),
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF3D5AF1),
              secondary: const Color(0xFFFF9800),
              surface: Colors.grey.shade900,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D5AF1),
              ),
            ),
          ),
          themeMode: ThemeMode.system,
          initialRoute: '/',
          onGenerateRoute: AppRouter.onGenerateRoute,
          routes: {
            '/': (context) => const SplashScreen(),
            '/signin': (context) => const SignInScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/dashboard': (context) => const DashboardScreen(),
          },
        ),
      ),
    );
  }
} 