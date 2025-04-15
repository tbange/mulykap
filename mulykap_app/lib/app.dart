class MulykapApp extends StatelessWidget {
  const MulykapApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: SupabaseAuthRepository(),
          ),
        ),
        // Autres providers de bloc si nécessaires
      ],
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
        routes: {
          '/': (context) => const SplashScreen(),
          '/signin': (context) => const SignInScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }
} 