import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:mulykap_app/features/dashboard/presentation/widgets/responsive_layout.dart';
import 'dart:math' as math;
import 'package:transparent_image/transparent_image.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedUserRole = 'client'; // Valeur par défaut
  bool _isDarkMode = false;
  late AnimationController _bubbleController;
  final List<Bubble> _bubbles = [];

  final List<Map<String, dynamic>> _userRoles = [
    {
      'value': 'client',
      'label': 'Client',
      'icon': Icons.person,
      'description': 'Réserver des billets et gérer vos voyages'
    },
    {
      'value': 'operateur',
      'label': 'Opérateur',
      'icon': Icons.business_center,
      'description': 'Gérer une agence de transport'
    },
    {
      'value': 'admin',
      'label': 'Administrateur',
      'icon': Icons.admin_panel_settings,
      'description': 'Gérer la plateforme (réservé)'
    },
  ];

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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthSignUpRequested(
          email: _emailController.text,
          password: _passwordController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          phone: _phoneController.text,
          userRole: _selectedUserRole,
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
          title: const Text('Inscription'),
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
                  // Afficher un message d'erreur plus détaillé
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
                  // Redirection vers le dashboard
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
                                  // Sélection du rôle utilisateur
                                  _buildRoleSelection(),
                                  const SizedBox(height: 32),
                                  
                                  // Informations personnelles
                                  Text(
                                    'Informations personnelles',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Nom et prénom sur la même ligne pour les écrans larges
                                  if (isDesktop || isTablet)
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildFirstNameField(),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildLastNameField(),
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      children: [
                                        _buildFirstNameField(),
                                        const SizedBox(height: 16),
                                        _buildLastNameField(),
                                      ],
                                    ),
                                    
                                  const SizedBox(height: 16),
                                  _buildPhoneField(),
                                  const SizedBox(height: 32),
                                  
                                  // Informations de connexion
                                  Text(
                                    'Informations de connexion',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 20),
                                  _buildEmailField(),
                                  const SizedBox(height: 16),
                                  
                                  // Mot de passe et confirmation sur la même ligne pour les écrans larges
                                  if (isDesktop || isTablet)
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: _buildPasswordField(),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _buildConfirmPasswordField(),
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      children: [
                                        _buildPasswordField(),
                                        const SizedBox(height: 16),
                                        _buildConfirmPasswordField(),
                                      ],
                                    ),
                                    
                                  const SizedBox(height: 32),
                                  
                                  // Bouton d'inscription
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
                                                'S\'inscrire',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Lien pour se connecter
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Vous avez déjà un compte?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pushReplacementNamed('/signin');
                              },
                              child: const Text(
                                'Se connecter',
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
          'Créez votre compte',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
        ),
      ],
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de compte',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            return isWide
                ? Row(
                    children: _userRoles
                        .map((role) => Expanded(
                              child: _buildRoleCard(role),
                            ))
                        .toList(),
                  )
                : Column(
                    children: _userRoles
                        .map((role) => _buildRoleCard(role))
                        .toList(),
                  );
          },
        ),
      ],
    );
  }

  Widget _buildRoleCard(Map<String, dynamic> role) {
    final isSelected = _selectedUserRole == role['value'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedUserRole = role['value'];
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF3D5AF1).withOpacity(_isDarkMode ? 0.3 : 0.1)
                : _isDarkMode ? Colors.grey.shade900 : Colors.white,
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF3D5AF1)
                  : _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                role['icon'],
                size: 32,
                color: isSelected
                    ? const Color(0xFF3D5AF1)
                    : _isDarkMode ? Colors.white70 : Colors.grey.shade700,
              ),
              const SizedBox(height: 12),
              Text(
                role['label'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? const Color(0xFF3D5AF1)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                role['description'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: _isDarkMode ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirstNameField() {
    return TextFormField(
      controller: _firstNameController,
      decoration: const InputDecoration(
        labelText: 'Prénom',
        hintText: 'Entrez votre prénom',
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer votre prénom';
        }
        return null;
      },
    );
  }

  Widget _buildLastNameField() {
    return TextFormField(
      controller: _lastNameController,
      decoration: const InputDecoration(
        labelText: 'Nom',
        hintText: 'Entrez votre nom',
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer votre nom';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      decoration: const InputDecoration(
        labelText: 'Téléphone',
        hintText: 'Entrez votre numéro de téléphone',
        prefixIcon: Icon(Icons.phone_outlined),
      ),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer votre numéro de téléphone';
        }
        return null;
      },
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
        hintText: 'Minimum 6 caractères',
        prefixIcon: Icon(Icons.lock_outline),
      ),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez entrer un mot de passe';
        }
        if (value.length < 6) {
          return 'Le mot de passe doit contenir au moins 6 caractères';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      decoration: const InputDecoration(
        labelText: 'Confirmer le mot de passe',
        hintText: 'Répétez votre mot de passe',
        prefixIcon: Icon(Icons.lock_outline),
      ),
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Veuillez confirmer votre mot de passe';
        }
        if (value != _passwordController.text) {
          return 'Les mots de passe ne correspondent pas';
        }
        return null;
      },
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