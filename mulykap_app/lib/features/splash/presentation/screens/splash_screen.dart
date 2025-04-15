import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_event.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Vérifier l'état de l'authentification
    context.read<AuthBloc>().add(const AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.user != null) {
          Navigator.of(context).pushReplacementNamed('/dashboard');
        } else if (state.isAuthenticated == false) {
          Navigator.of(context).pushReplacementNamed('/signin');
        }
      },
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo ou image de l'application
              Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.directions_bus,
                    size: 80,
                    color: Color(0xFF3D5AF1),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'MulyKap',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D5AF1),
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
} 