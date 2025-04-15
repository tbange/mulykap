# MulyKap App

Application mobile développée avec Flutter et Supabase.

## Fonctionnalités

- Authentification (Inscription, Connexion, Déconnexion)
- Gestion d'état avec BLoC
- Interface utilisateur Material Design responsive

## Configuration

### Prérequis

- Flutter (version 3.7.0 ou supérieure)
- Compte Supabase

### Installation

1. Clonez ce dépôt :
```bash
git clone https://github.com/votre-nom/mulykap_app.git
cd mulykap_app
```

2. Installez les dépendances :
```bash
flutter pub get
```

3. Configurez Supabase :
   - Créez un projet sur [Supabase](https://supabase.com)
   - Récupérez l'URL et la clé anonyme de votre projet
   - Copiez le fichier `.env.example` en `.env` :
   ```bash
   cp .env.example .env
   ```
   - Modifiez le fichier `.env` avec vos informations :
   ```
   SUPABASE_URL=votre_url_supabase
   SUPABASE_ANON_KEY=votre_cle_anonyme_supabase
   ```

4. Lancez l'application :
```bash
flutter run
```

## Structure du projet

```
lib/
├── core/
│   └── constants.dart
├── features/
│   └── auth/
│       ├── data/
│       │   └── repositories/
│       │       └── auth_repository.dart
│       ├── domain/
│       │   └── models/
│       │       └── user_model.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── auth_bloc.dart
│           │   ├── auth_event.dart
│           │   └── auth_state.dart
│           └── screens/
│               ├── auth_wrapper.dart
│               ├── home_screen.dart
│               ├── sign_in_screen.dart
│               └── sign_up_screen.dart
└── main.dart
```

## Variables d'environnement

L'application utilise un fichier `.env` pour stocker les variables d'environnement sensibles. Ce fichier n'est pas suivi par git pour des raisons de sécurité.

Variables disponibles :
- `SUPABASE_URL` : URL de votre projet Supabase
- `SUPABASE_ANON_KEY` : Clé anonyme de votre projet Supabase

## Architecture

Ce projet suit les principes du Clean Architecture et utilise les patterns suivants :
- **BLoC** pour la gestion d'état
- **Repository** pour l'accès aux données
- **Dependency Injection** pour l'inversion de contrôle

## À propos

Cette application a été développée selon les meilleures pratiques de développement Flutter, avec un focus particulier sur :
- La maintenabilité du code
- La séparation des responsabilités
- L'expérience utilisateur
- La performance

## Licence

[MIT](LICENSE)
