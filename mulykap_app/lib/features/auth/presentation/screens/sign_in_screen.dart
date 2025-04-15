import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:mulykap_app/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:mulykap_app/features/dashboard/presentation/widgets/responsive_layout.dart';
import 'dart:math' as math;
import 'package:transparent_image/transparent_image.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isDarkMode = false;
  bool _rememberMe = false;
  late AnimationController _bubbleController;
  final List<Bubble> _bubbles = [];

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    // Créer des bulles aléatoires
    for (int i = 0; i < 15; i++) {
      _bubbles.add(Bubble(
        position: Offset(
          math.Random().nextDouble() * 400,
          math.Random().nextDouble() * 800,
        ),
        size: math.Random().nextDouble() * 30 + 10,
        speed: math.Random().nextDouble() * 2 + 1,
      ));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthSignInRequested(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    
    final theme = Theme.of(context).copyWith(
      colorScheme: _isDarkMode 
        ? const ColorScheme.dark(
            primary: Color(0xFF3D5AF1),
            secondary: Color(0xFFFF9800),
          )
        : const ColorScheme.light(
            primary: Color(0xFF3D5AF1),
            secondary: Color(0xFFFF9800),
          ),
      scaffoldBackgroundColor: _isDarkMode 
        ? const Color(0xFF121212) 
        : const Color(0xFFF5F7FA),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _isDarkMode ? Colors.grey.shade900 : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFF3D5AF1),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3D5AF1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: Theme.of(context).textTheme.apply(
        bodyColor: _isDarkMode ? Colors.white : Colors.black,
        displayColor: _isDarkMode ? Colors.white : Colors.black,
      ),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Connexion'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: _isDarkMode ? Colors.white : Colors.black,
          actions: [
            IconButton(
              onPressed: _toggleTheme,
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              tooltip: _isDarkMode ? 'Mode clair' : 'Mode sombre',
            ),
          ],
        ),
        body: Stack(
          children: [
            // Image de fond
            Positioned.fill(
              child: FadeInImage(
                placeholder: MemoryImage(kTransparentImage),
                image: const AssetImage('assets/bg.jpg'),
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 500),
                imageErrorBuilder: (context, error, stackTrace) {
                  print('Erreur chargement image: $error');
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blue.shade900,
                          Colors.blue.shade600,
                          Colors.blue.shade400,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Dégradé bleu
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.blue.withOpacity(0.7),
                      Colors.blue.withOpacity(0.9),
                    ],
                  ),
                ),
              ),
            ),
            
            // Animation de bulles
            AnimatedBuilder(
              animation: _bubbleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: BubblePainter(_bubbles, _bubbleController.value),
                  size: Size.infinite,
                );
              },
            ),
            
            // Contenu principal
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state.isUnauthenticated && state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${state.error}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                      action: SnackBarAction(
                        label: 'OK',
                        textColor: Colors.white,
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                      ),
                    ),
                  );
                } else if (state.isAuthenticated) {
                  Navigator.of(context).pushReplacementNamed('/dashboard');
                }
              },
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1200 : (isTablet ? 700 : 450),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo et titre
                        _buildHeader(),
                        const SizedBox(height: 40),
                        
                        // Formulaire principal
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 4,
                          color: Colors.white.withOpacity(0.9),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildEmailField(),
                                  const SizedBox(height: 20),
                                  _buildPasswordField(),
                                  const SizedBox(height: 16),
                                  
                                  // Options "Se souvenir de moi" et "Mot de passe oublié"
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: _rememberMe,
                                            onChanged: (value) {
                                              setState(() {
                                                _rememberMe = value ?? false;
                                              });
                                            },
                                            activeColor: const Color(0xFF3D5AF1),
                                          ),
                                          const Text('Se souvenir de moi'),
                                        ],
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pushNamed('/forgot-password');
                                        },
                                        child: const Text(
                                          'Mot de passe oublié ?',
                                          style: TextStyle(
                                            color: Color(0xFF3D5AF1),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 30),
                                  
                                  // Bouton de connexion
                                  BlocBuilder<AuthBloc, AuthState>(
                                    builder: (context, state) {
                                      final isSubmitting = state.status == AuthStatus.submitting;
                                      return ElevatedButton(
                                        onPressed: isSubmitting ? null : _submitForm,
                                        child: isSubmitting
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text(
                                                'Se connecter',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      );
                                    },
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // OU séparateur
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                          thickness: 1,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                        child: Text(
                                          'OU',
                                          style: TextStyle(
                                            color: _isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                                          thickness: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  
                                  // Boutons d'authentification sociale (visuels uniquement)
                                  if (isDesktop || isTablet)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildSocialButton(Icons.g_mobiledata, 'Google'),
                                        const SizedBox(width: 16),
                                        _buildSocialButton(Icons.facebook, 'Facebook'),
                                        const SizedBox(width: 16),
                                        _buildSocialButton(Icons.apple, 'Apple'),
                                      ],
                                    )
                                  else
                                    Column(
                                      children: [
                                        _buildSocialButton(Icons.g_mobiledata, 'Google', fullWidth: true),
                                        const SizedBox(height: 12),
                                        _buildSocialButton(Icons.facebook, 'Facebook', fullWidth: true),
                                        const SizedBox(height: 12),
                                        _buildSocialButton(Icons.apple, 'Apple', fullWidth: true),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Lien pour créer un compte
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Vous n\'avez pas de compte?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed('/signup');
                              },
                              child: const Text(
                                'S\'inscrire',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/logo.jpg',
          height: 70,
          width: 70,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFFFCA28),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Text(
                'M',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'MulyKap',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connectez-vous à votre compte',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'exemple@email.com',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer votre email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Veuillez entrer un email valide';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: const InputDecoration(
        labelText: 'Mot de passe',
        hintText: 'Entrez votre mot de passe',
        prefixIcon: Icon(Icons.lock_outline),
      ),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer votre mot de passe';
        }
        return null;
      },
    );
  }
  
  Widget _buildSocialButton(IconData icon, String label, {bool fullWidth = false}) {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO: Implémenter l'authentification sociale
      },
      icon: Icon(icon, size: 24),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isDarkMode ? Colors.grey.shade800 : Colors.white,
        foregroundColor: _isDarkMode ? Colors.white : Colors.black87,
        elevation: 1,
        padding: EdgeInsets.symmetric(
          vertical: 12,
          horizontal: fullWidth ? 16 : 24,
        ),
        minimumSize: fullWidth ? const Size(double.infinity, 48) : null,
        side: BorderSide(
          color: _isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
    );
  }
}

// Classe pour représenter une bulle
class Bubble {
  Offset position;
  double size;
  double speed;
  
  Bubble({
    required this.position,
    required this.size,
    required this.speed,
  });
}

// Peintre personnalisé pour dessiner les bulles
class BubblePainter extends CustomPainter {
  final List<Bubble> bubbles;
  final double animationValue;
  
  BubblePainter(this.bubbles, this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    for (var bubble in bubbles) {
      // Calculer la position de la bulle en fonction de l'animation
      final y = (bubble.position.dy - (bubble.speed * 100 * animationValue)) % size.height;
      
      // Dessiner la bulle
      canvas.drawCircle(
        Offset(bubble.position.dx, y),
        bubble.size,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(BubblePainter oldDelegate) => true;
} 