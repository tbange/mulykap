import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:mulykap_app/core/constants.dart';
import 'package:mulykap_app/features/auth/data/repositories/auth_repository.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:mulykap_app/features/auth/presentation/screens/auth_wrapper.dart';
import 'package:mulykap_app/features/auth/presentation/screens/change_password_screen.dart';
import 'package:mulykap_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:mulykap_app/features/auth/presentation/screens/profile_screen.dart';
import 'package:mulykap_app/features/auth/presentation/screens/settings_screen.dart';
import 'package:mulykap_app/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:mulykap_app/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:mulykap_app/features/buses/data/repositories/bus_repository.dart';
import 'package:mulykap_app/features/buses/data/repositories/agency_repository.dart';
import 'package:mulykap_app/features/buses/data/repositories/city_repository.dart';
import 'package:mulykap_app/features/buses/domain/models/bus_model.dart';
import 'package:mulykap_app/features/buses/domain/models/agency_model.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/bus_bloc.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/agency_bloc.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/city_bloc.dart';
import 'package:mulykap_app/features/buses/presentation/screens/bus_list_screen.dart';
import 'package:mulykap_app/features/buses/presentation/screens/bus_detail_screen.dart';
import 'package:mulykap_app/features/buses/presentation/screens/bus_form_screen.dart';
import 'package:mulykap_app/features/buses/presentation/screens/agency_list_screen.dart';
import 'package:mulykap_app/features/buses/presentation/screens/agency_detail_screen.dart';
import 'package:mulykap_app/features/buses/presentation/screens/agency_form_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:mulykap_app/theme/app_theme.dart';
import 'package:mulykap_app/features/drivers/domain/repositories/driver_repository.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Charger les variables d'environnement
  await dotenv.load();
  
  // Initialiser Supabase
  await supabase.Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );
  
  // Initialiser les données de localisation
  await initializeDateFormatting('fr_FR');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseClient = supabase.Supabase.instance.client;
    
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepository(),
        ),
        RepositoryProvider<BusRepository>(
          create: (context) => BusRepository(supabaseClient: supabaseClient),
        ),
        RepositoryProvider<AgencyRepository>(
          create: (context) => AgencyRepository(supabaseClient: supabaseClient),
        ),
        RepositoryProvider<CityRepository>(
          create: (context) => CityRepository(supabaseClient: supabaseClient),
        ),
        RepositoryProvider<DriverRepository>(
          create: (context) => DriverRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) {
              final authBloc = AuthBloc(
                authRepository: RepositoryProvider.of<AuthRepository>(context),
              );
              // Vérifier l'état d'authentification au démarrage
              authBloc.add(const AuthCheckRequested());
              return authBloc;
            },
          ),
          BlocProvider<BusBloc>(
            create: (context) => BusBloc(
              busRepository: RepositoryProvider.of<BusRepository>(context),
            ),
          ),
          BlocProvider<AgencyBloc>(
            create: (context) => AgencyBloc(
              agencyRepository: RepositoryProvider.of<AgencyRepository>(context),
            ),
          ),
          BlocProvider<CityBloc>(
            create: (context) => CityBloc(
              cityRepository: RepositoryProvider.of<CityRepository>(context),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'MulyKap',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          // Support de la localisation
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', 'FR'), // Français (prioritaire)
            Locale('en', 'US'), // Anglais
          ],
          locale: const Locale('fr', 'FR'), // Définir la localisation par défaut
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthWrapper(),
            '/signin': (context) => const SignInScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/dashboard': (context) => const DashboardScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/change-password': (context) => const ChangePasswordScreen(),
            
            // Routes pour les bus
            '/buses': (context) => const BusListScreen(),
            '/buses/add': (context) => BusFormScreen(isEditing: false),
            '/buses/edit': (context) {
              final bus = ModalRoute.of(context)!.settings.arguments as BusModel;
              return BusFormScreen(isEditing: true, bus: bus);
            },
            '/buses/details': (context) {
              final busId = ModalRoute.of(context)!.settings.arguments as String;
              return BusDetailScreen(busId: busId);
            },
            
            // Routes pour les agences
            '/agencies': (context) => const AgencyListScreen(),
            '/agencies/add': (context) => const AgencyFormScreen(isEditing: false),
            '/agencies/edit': (context) {
              final agency = ModalRoute.of(context)!.settings.arguments as AgencyModel;
              return AgencyFormScreen(isEditing: true, agency: agency);
            },
            '/agencies/details': (context) {
              final agencyId = ModalRoute.of(context)!.settings.arguments as String;
              return AgencyDetailScreen(agencyId: agencyId);
            },
          },
        ),
      ),
    );
  }
}
