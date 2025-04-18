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
- [x] Gestion des voyages récurrents (partielle)
  - [x] Écran de liste des voyages récurrents
  - [x] Vue calendrier des voyages récurrents
  - [x] Création de voyages récurrents
  - [x] Marquage voyage actif/inactif
  - [x] Suppression de voyages 
  - [ ] Édition de voyages récurrents (à implémenter)
  - [ ] Génération de voyages réguliers à partir des modèles récurrents (à implémenter)
- [x] Gestion des chauffeurs
- [x] Gestion des agences
- [x] Gestion des villes
- [ ] Gestion des réservations
- [ ] Gestion des sièges et bagages
- [ ] Gestion des tickets
- [x] Gestion des paiements (structure de base)
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
   - Terminer l'implémentation de l'édition des voyages récurrents
   - Implémenter la génération de voyages réels à partir des modèles récurrents
   - Développer la vue détaillée des voyages récurrents

### Priorité moyenne (à moyen terme)
8. Implémenter les fonctionnalités de recherche de voyages
9. Développer les écrans de réservation de billets
10. Intégrer les services de paiement mobile
11. Implémenter la gestion des promotions
12. Développer le système de notifications

### Priorité basse (à long terme)
13. Implémentation du multilinguisme
14. Optimisation pour les zones à faible connectivité
15. Rapports et tableaux de bord avancés
16. Exportation des données et rapports

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
- En cours : Optimisation des performances pour les zones à faible connectivité 

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