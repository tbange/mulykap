# Suivi de Progression - Projet Mulykap

> Ce document suit l'avancement du projet selon le [plan d'exécution](execution_plan.md).

## État d'avancement global
- [x] Configuration initiale du projet
- [x] Intégration de Supabase
- [x] Mise en place de la structure BLoC
- [x] Configuration des variables d'environnement
- [x] Modélisation de la base de données
- [x] Développement de l'interface utilisateur de base
- [x] Implémentation de l'authentification de base
- [ ] Développement des fonctionnalités métier
- [ ] Tests et assurance qualité
- [ ] Déploiement en production

## Fonctionnalités implémentées

### Authentification
- [x] Interface de connexion utilisateur (Sign In)
- [x] Interface d'inscription utilisateur (Sign Up)
- [x] Fonctionnalité de base d'inscription utilisateur
- [x] Déconnexion
- [x] Réinitialisation du mot de passe
- [x] Changement de mot de passe
- [ ] Authentification par OTP (prévue uniquement pour les clients)
- [x] Gestion des profils utilisateurs (interface)

### Interface utilisateur
- [x] Structure de base de l'application
- [x] Navigation entre écrans d'authentification
- [x] Menu latéral avec toutes les fonctionnalités
- [x] Profil utilisateur et paramètres
- [x] Mode sombre/clair
- [x] Interface responsive
- [x] Menu utilisateur déroulant
- [ ] Écrans de recherche de voyages
- [ ] Écrans de réservation de billets
- [ ] Intégration des paiements
- [ ] Notifications
- [ ] Multilinguisme

### Fonctionnalités métier
- [ ] Gestion des utilisateurs
- [x] Gestion de la flotte de bus
- [x] Gestion des itinéraires
- [x] Gestion des arrêts
- [x] Gestion des voyages récurrents (complète)
  - [x] Écran de liste des voyages récurrents
  - [x] Vue calendrier des voyages récurrents
  - [x] Création de voyages récurrents
  - [x] Marquage voyage actif/inactif
  - [x] Suppression de voyages 
  - [x] Édition de voyages récurrents
  - [x] Rendu du bus facultatif dans les voyages récurrents
  - [x] Génération de voyages réguliers à partir des modèles récurrents (interface)
  - [ ] Résolution des problèmes de génération (enum incompatible entre code et BDD)
- [x] Gestion des chauffeurs
- [x] Gestion des agences
- [x] Gestion des villes
- [x] Gestion des voyages (partielle)
  - [x] Écran principal de liste des voyages générés
  - [x] Filtrage des voyages par date, statut
  - [x] Vue par onglets (Tous/Aujourd'hui/À venir)
  - [ ] Affectation des bus aux voyages
  - [ ] Affectation des chauffeurs aux voyages
  - [ ] Gestion du statut des voyages (planifié, en cours, terminé, annulé)
  - [ ] Vue détaillée d'un voyage
- [ ] Gestion des réservations
  - [ ] Création d'une réservation
  - [ ] Liste des réservations
  - [ ] Détails d'une réservation
  - [ ] Modification/Annulation d'une réservation
- [ ] Gestion des sièges et bagages
  - [ ] Sélection de siège lors de la réservation
  - [ ] Gestion des capacités de bagages
- [ ] Gestion des tickets
  - [ ] Génération de ticket
  - [ ] Envoi de ticket par email/SMS
  - [ ] Validation de ticket
- [x] Gestion des paiements (structure de base)
  - [ ] Intégration des API de paiement mobile
  - [ ] Suivi des transactions
- [ ] Gestion des promotions
- [ ] Gestion des notifications utilisateur
- [ ] Génération de rapports et statistiques

## Prochaines étapes

### Priorité élevée (à court terme)
1. ~~Finaliser l'authentification avec réinitialisation et changement de mot de passe~~ ✓
2. ~~Implémenter l'écran de gestion des bus (étape fondamentale pour d'autres fonctionnalités)~~ ✓
3. ~~Implémenter l'écran de gestion des agences~~ ✓
4. ~~Implémenter l'écran de gestion des villes~~ ✓
5. ~~Développer l'écran de gestion des itinéraires et des arrêts~~ ✓
6. ~~Implémenter l'écran de chauffeurs~~ ✓
7. ~~Développer l'écran de gestion des voyages récurrents~~ ✓ (partiel)
   - ~~Terminer l'implémentation de l'édition des voyages récurrents~~ ✓
   - ~~Rendre le bus facultatif dans les voyages récurrents~~ ✓
   - ~~Implémenter la génération de voyages réels à partir des modèles récurrents~~ ✓ (interface)
   - **À faire immédiatement :** Corriger les problèmes de génération de voyages (incompatibilité enum)
     - Le problème identifié : Dans le code, l'enum TripStatus utilise 'planned' comme valeur, mais dans la base de données l'enum 'voyage_status' utilise également 'planned'. Cependant, il y a une disparité quand les voyages sont générés.
     - Dans RecurringTripRepository, la méthode generateTripsFromRecurringTrip utilise "status: 'planned'" pour les nouveaux voyages, ce qui correspond à l'enum de la base de données.
     - Solutions possibles :
       1. Modifier l'enum dans la base de données pour inclure 'scheduled' si nécessaire
       2. Modifier l'enum du code TripStatus pour assurer la cohérence avec la base de données
       3. Vérifier le processus de génération pour s'assurer que le statut correct est utilisé
   - Développer la vue détaillée des voyages récurrents
8. Développer l'écran de gestion des voyages (réguliers) à partir des modèles récurrents (partiellement implémenté)
   - ~~Créer la structure de base pour l'affichage des voyages générés~~ ✓
   - ~~Implémenter les filtres (date, statut)~~ ✓
   - ~~Implémenter la vue par onglets (Tous/Aujourd'hui/À venir)~~ ✓
   - Ajouter les fonctionnalités de CRUD complètes pour les voyages
   - Implémenter l'affectation des bus aux voyages
   - Implémenter l'affectation des chauffeurs aux voyages
   - Développer l'interface de gestion des statuts des voyages
   - Ajouter une vue détaillée pour chaque voyage

### Priorité moyenne (à moyen terme)
9. Implémenter les fonctionnalités de recherche de voyages
   - Développer l'interface de recherche avec filtres avancés
   - Implémenter l'affichage des résultats de recherche
10. Développer les écrans de réservation de billets
    - Créer le flux complet de réservation
    - Implémenter la sélection de sièges
    - Développer le système de gestion des bagages
11. Intégrer les services de paiement mobile
    - Intégrer ArtelMoney
    - Intégrer M-Pesa
    - Intégrer Orange Money
12. Implémenter la gestion des promotions
13. Développer le système de notifications

### Priorité basse (à long terme)
14. Implémentation du multilinguisme
15. Optimisation pour les zones à faible connectivité
16. Rapports et tableaux de bord avancés
17. Exportation des données et rapports

## Problèmes rencontrés
- Résolu : Problème de conflit de type AuthState avec Supabase
- Résolu : Problème de type avec createdAt dans le repository d'authentification
- Résolu : Problème de navigation entre l'écran de connexion et d'inscription
- Résolu : Problème avec la fonctionnalité d'inscription (création des profils utilisateurs dans Supabase)
- Résolu : Amélioration du menu latéral pour inclure toutes les fonctionnalités métier
- Résolu : Problème avec la colonne 'country' manquante dans la table 'cities'
- Résolu : Problème de contrainte unique pour les arrêts d'itinéraires
- Résolu : Problème de contexte lors de l'édition des arrêts dans un dialogue
- Résolu : Problème de localisation pour l'affichage du calendrier des voyages récurrents
- Résolu : Problème de contexte dans les boîtes de dialogue pour les voyages récurrents (suppression et changement de statut)
- **En cours** : Problème avec la génération de voyages - incompatibilité enum 'voyage_status' (scheduled vs planned)
  - Analyse détaillée: L'enum TripStatus dans le code utilise 'planned' comme la base de données
  - Le problème semble se produire lors des opérations de lecture/écriture entre le code et la base de données
  - Nécessite une vérification approfondie du processus de conversion des valeurs d'enum lors de la génération des voyages
- En cours : Optimisation des performances pour les zones à faible connectivité 
- **En cours** : Implémentation de l'affectation des bus et chauffeurs aux voyages

## Dernières mises à jour
- Implémentation complète des fonctionnalités de réinitialisation et changement de mot de passe
- Réorganisation complète du menu latéral avec catégorisation des fonctionnalités
- Ajout de nouveaux éléments de menu pour couvrir toutes les tables de la base de données
- Ajout d'un écran de profil utilisateur avec possibilité d'édition
- Ajout d'un écran de paramètres avec options diverses 
- Ajout des colonnes téléphone et email dans la table agences
- Implémentation du drawer pour les détails des bus et agences
- Implémentation de listes extensibles pour voir les bus associés à chaque agence
- Amélioration des formulaires d'édition pour les agences et les bus 
- Implémentation complète de la gestion des itinéraires avec configuration des arrêts
- Implémentation d'un système dynamique pour ajouter des arrêts intermédiaires entre deux villes
- Développement d'un écran complet de gestion des arrêts avec filtrage avancé
- Correction des problèmes de contrainte unique dans la base de données pour les arrêts 
- Implémentation complète de la gestion des chauffeurs avec formulaires d'ajout/édition
- Ajout de la possibilité d'assigner des chauffeurs à des agences
- Développement d'une interface pour la gestion des voyages récurrents
- Implémentation d'une vue double (liste + calendrier) pour les voyages récurrents
- Ajout d'un système de création de voyages récurrents avec sélection des jours de la semaine
- Correction des problèmes de localisation pour l'affichage du calendrier en français
- Implémentation de l'activation/désactivation des voyages récurrents
- Amélioration de l'interface utilisateur du calendrier pour distinguer visuellement les voyages
- Implémentation de l'édition des voyages récurrents avec préservation des valeurs existantes
- Correction du problème de contexte dans les boîtes de dialogue pour la suppression et le changement de statut
- Modification de la base de données et de l'interface pour rendre le champ bus facultatif dans les voyages récurrents
- Implémentation complète de la génération de voyages réels à partir des modèles récurrents
- Ajout d'une interface dédiée pour la génération de voyages avec sélection de période et paramètres
- Intégration de boutons dans l'interface pour faciliter l'accès à la fonctionnalité de génération
- Transformation de l'écran de génération de voyages en dialogue pour une meilleure UX
- Tentative de correction du problème d'enum incompatible entre le code (TripStatus) et la base de données (voyage_status)
- Planification de l'implémentation de l'affectation des bus et chauffeurs aux voyages générés
- **Nouveau** : Implémentation de l'écran de liste des voyages avec filtrage par date et statut
- **Nouveau** : Ajout d'une vue par onglets pour faciliter la navigation entre différentes catégories de voyages
- **Nouveau** : Analyse détaillée du problème d'incompatibilité d'enum pour orienter la correction