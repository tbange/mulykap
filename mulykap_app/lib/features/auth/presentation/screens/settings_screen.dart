import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mulykap_app/features/auth/presentation/bloc/auth_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _language = 'Français';
  
  @override
  Widget build(BuildContext context) {
    final bool currentDarkMode = Theme.of(context).brightness == Brightness.dark;
    _darkModeEnabled = currentDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: currentDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: currentDarkMode ? Colors.white : Colors.black87,
        elevation: 1,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return ListView(
            children: [
              const SizedBox(height: 16),
              
              // Section Apparence
              _buildSectionHeader('Apparence', Icons.palette_outlined, currentDarkMode),
              SwitchListTile(
                title: const Text('Mode sombre'),
                subtitle: const Text('Activer le thème sombre pour l\'application'),
                value: _darkModeEnabled,
                onChanged: (value) {
                  setState(() {
                    _darkModeEnabled = value;
                  });
                  // TODO: Implémenter la modification du thème
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cette fonctionnalité sera bientôt disponible'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                secondary: Icon(
                  Icons.dark_mode,
                  color: currentDarkMode ? Colors.yellow.shade600 : Colors.blue.shade800,
                ),
              ),
              const Divider(),
              
              // Section Langue
              ListTile(
                title: const Text('Langue'),
                subtitle: Text(_language),
                leading: const Icon(Icons.language),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _showLanguageDialog();
                },
              ),
              const Divider(),
              
              // Section Notifications
              _buildSectionHeader('Notifications', Icons.notifications_none_outlined, currentDarkMode),
              SwitchListTile(
                title: const Text('Activer les notifications'),
                subtitle: const Text('Recevoir des alertes sur les nouvelles fonctionnalités et mises à jour'),
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
                secondary: Icon(
                  _notificationsEnabled 
                      ? Icons.notifications_active_outlined 
                      : Icons.notifications_off_outlined,
                  color: _notificationsEnabled 
                      ? Colors.green.shade700 
                      : Colors.red.shade400,
                ),
              ),
              const Divider(),
              
              // Section données personnelles
              _buildSectionHeader('Données personnelles', Icons.security_outlined, currentDarkMode),
              ListTile(
                title: const Text('Exporter mes données'),
                subtitle: const Text('Télécharger une copie de vos données'),
                leading: Icon(
                  Icons.download_outlined,
                  color: Colors.blue.shade700,
                ),
                onTap: () {
                  // TODO: Implémenter l'exportation des données
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cette fonctionnalité sera bientôt disponible'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Supprimer mon compte'),
                subtitle: const Text('Supprimer définitivement votre compte et vos données'),
                leading: Icon(
                  Icons.delete_outline,
                  color: Colors.red.shade700,
                ),
                onTap: () {
                  _showDeleteAccountDialog();
                },
              ),
              
              // Section À propos
              _buildSectionHeader('À propos', Icons.info_outline, currentDarkMode),
              ListTile(
                title: const Text('Version de l\'application'),
                subtitle: const Text('1.0.0'),
                leading: const Icon(Icons.android),
              ),
              const Divider(),
              ListTile(
                title: const Text('Conditions d\'utilisation'),
                leading: const Icon(Icons.description_outlined),
                onTap: () {
                  // TODO: Afficher les conditions d'utilisation
                },
              ),
              const Divider(),
              ListTile(
                title: const Text('Politique de confidentialité'),
                leading: const Icon(Icons.privacy_tip_outlined),
                onTap: () {
                  // TODO: Afficher la politique de confidentialité
                },
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade800,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Sélectionner la langue'),
          children: [
            _buildLanguageOption('Français'),
            _buildLanguageOption('English'),
            _buildLanguageOption('Español'),
          ],
        );
      },
    );
  }
  
  Widget _buildLanguageOption(String language) {
    final bool isSelected = _language == language;
    
    return SimpleDialogOption(
      onPressed: () {
        setState(() {
          _language = language;
        });
        Navigator.pop(context);
      },
      child: Row(
        children: [
          Text(
            language,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          if (isSelected)
            const Icon(Icons.check, color: Colors.green),
        ],
      ),
    );
  }
  
  void _showDeleteAccountDialog() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible et toutes vos données seront perdues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implémenter la suppression du compte
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cette fonctionnalité sera bientôt disponible'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
} 