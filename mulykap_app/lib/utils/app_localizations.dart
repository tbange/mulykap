import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  static AppLocalizations of(BuildContext context) => AppLocalizations();
  
  // Routes & Navigation
  String get routes => "Itinéraires";
  String get loading => "Chargement...";
  String get noRoutesFound => "Aucun itinéraire trouvé";
  String get noRoutesMatchSearch => "Aucun itinéraire ne correspond à votre recherche";
  String get addRoute => "Ajouter un itinéraire";
  String get search => "Rechercher";
  String get searchRoutesHint => "Rechercher par ville de départ ou d'arrivée...";
  String get filterByDepartureCity => "Filtrer par ville de départ";
  String get filterByArrivalCity => "Filtrer par ville d'arrivée";
  String get viewDetails => "Voir les détails";
  String get unknown => "Inconnu";
  String get edit => "Modifier";
  String get delete => "Supprimer";
  String get deleteRoute => "Supprimer l'itinéraire";
  String get confirmDeleteRoute => "Êtes-vous sûr de vouloir supprimer cet itinéraire?";
  String get cancel => "Annuler";
  String get newRoute => "Nouvel itinéraire";
  String get editRoute => "Modifier l'itinéraire";
  String get createRoute => "Créer l'itinéraire";
  String get saveChanges => "Enregistrer les modifications";
  String get routeNotFound => "Itinéraire non trouvé";
  
  // Form fields
  String get departureCity => "Ville de départ";
  String get arrivalCity => "Ville d'arrivée";
  String get distanceKm => "Distance (km)";
  String get requiredField => "Ce champ est obligatoire";
  String get sameCityError => "Les villes de départ et d'arrivée doivent être différentes";
  String get invalidNumber => "Veuillez entrer un nombre valide";
  String get positiveNumberRequired => "Veuillez entrer un nombre positif";
  String get hours => "Heures";
  String get minutes => "Minutes";
  String get durationRequired => "La durée est obligatoire";
  String get invalidMinutes => "Les minutes doivent être entre 0 et 59";
  
  // Route details
  String get routeDetails => "Détails de l'itinéraire";
  String get routeInformation => "Informations sur l'itinéraire";
  String get distance => "Distance";
  String get estimatedDuration => "Durée estimée";
  
  // Stops
  String get stops => "Arrêts";
  String get addStop => "Ajouter un arrêt";
  String get noStopsFound => "Aucun arrêt trouvé";
  String get deleteStop => "Supprimer l'arrêt";
  String get confirmDeleteStop => "Êtes-vous sûr de vouloir supprimer cet arrêt?";
  String get newStop => "Nouvel arrêt";
  String get editStop => "Modifier l'arrêt";
  String get createStop => "Créer l'arrêt";
  String get city => "Ville";
  String stopType(String type) => "Type d'arrêt: $type";
  String get stopOrder => "Ordre d'arrêt";
  String get distanceFromPrevious => "Distance depuis l'arrêt précédent";
  String get durationFromPrevious => "Durée depuis l'arrêt précédent";
  String get waitingTime => "Temps d'attente à l'arrêt";
  String get optionalField => "Optionnel";

  // Drivers
  String get drivers => Intl.message(
        'Chauffeurs',
        name: 'drivers',
        desc: 'Title for drivers list screen',
      );

  String get driver => Intl.message(
        'Chauffeur',
        name: 'driver',
        desc: 'Driver label',
      );

  String get addDriver => Intl.message(
        'Ajouter un chauffeur',
        name: 'addDriver',
        desc: 'Button to add a new driver',
      );

  String get editDriver => Intl.message(
        'Modifier un chauffeur',
        name: 'editDriver',
        desc: 'Title for edit driver screen',
      );

  String get noDriversYet => Intl.message(
        'Aucun chauffeur enregistré',
        name: 'noDriversYet',
        desc: 'Message shown when no drivers are available',
      );

  String get addFirstDriver => Intl.message(
        'Commencez par ajouter un chauffeur',
        name: 'addFirstDriver',
        desc: 'Suggestion to add first driver',
      );

  String get errorLoadingDrivers => Intl.message(
        'Erreur lors du chargement des chauffeurs',
        name: 'errorLoadingDrivers',
        desc: 'Error message when drivers loading fails',
      );

  String get driverDeletedSuccessfully => Intl.message(
        'Chauffeur supprimé avec succès',
        name: 'driverDeletedSuccessfully',
        desc: 'Success message after driver deletion',
      );

  String get errorDeletingDriver => Intl.message(
        'Erreur lors de la suppression du chauffeur',
        name: 'errorDeletingDriver',
        desc: 'Error message when driver deletion fails',
      );

  String get deleteDriverTitle => Intl.message(
        'Supprimer le chauffeur',
        name: 'deleteDriverTitle',
        desc: 'Title for driver deletion confirmation dialog',
      );

  String deleteDriverConfirmation(String name) => Intl.message(
        'Êtes-vous sûr de vouloir supprimer le chauffeur $name ?',
        name: 'deleteDriverConfirmation',
        args: [name],
        desc: 'Confirmation message for driver deletion',
      );

  String get licenseNumber => Intl.message(
        'Numéro de permis',
        name: 'licenseNumber',
        desc: 'Label for driver license number',
      );

  String get licenseNumberHint => Intl.message(
        'ex: ABC123456',
        name: 'licenseNumberHint',
        desc: 'Hint for license number field',
      );

  String get licenseNumberRequired => Intl.message(
        'Le numéro de permis est obligatoire',
        name: 'licenseNumberRequired',
        desc: 'Validation message when license number is empty',
      );

  String get licenseExpiryDate => Intl.message(
        'Date d\'expiration du permis',
        name: 'licenseExpiryDate',
        desc: 'Label for license expiry date',
      );

  String get firstName => Intl.message(
        'Prénom',
        name: 'firstName',
        desc: 'Label for first name field',
      );

  String get firstNameHint => Intl.message(
        'Prénom du chauffeur',
        name: 'firstNameHint',
        desc: 'Hint for first name field',
      );

  String get firstNameRequired => Intl.message(
        'Le prénom est obligatoire',
        name: 'firstNameRequired',
        desc: 'Validation message when first name is empty',
      );

  String get lastName => Intl.message(
        'Nom',
        name: 'lastName',
        desc: 'Label for last name field',
      );

  String get lastNameHint => Intl.message(
        'Nom du chauffeur',
        name: 'lastNameHint',
        desc: 'Hint for last name field',
      );

  String get lastNameRequired => Intl.message(
        'Le nom est obligatoire',
        name: 'lastNameRequired',
        desc: 'Validation message when last name is empty',
      );

  String get phoneNumber => Intl.message(
        'Téléphone',
        name: 'phoneNumber',
        desc: 'Label for phone number field',
      );

  String get phoneNumberHint => Intl.message(
        'ex: +243 123 456 789',
        name: 'phoneNumberHint',
        desc: 'Hint for phone number field',
      );

  String get phoneNumberRequired => Intl.message(
        'Le numéro de téléphone est obligatoire',
        name: 'phoneNumberRequired',
        desc: 'Validation message when phone number is empty',
      );

  String get personalInformation => Intl.message(
        'Informations personnelles',
        name: 'personalInformation',
        desc: 'Section title for personal information',
      );

  String get agency => Intl.message(
        'Agence',
        name: 'agency',
        desc: 'Label for agency',
      );

  String get selectAgency => Intl.message(
        'Sélectionnez une agence',
        name: 'selectAgency',
        desc: 'Prompt to select an agency',
      );

  String get noAgency => Intl.message(
        'Aucune agence',
        name: 'noAgency',
        desc: 'Option for no agency',
      );

  String get isActive => Intl.message(
        'Chauffeur actif',
        name: 'isActive',
        desc: 'Label for active status',
      );

  String get expired => Intl.message(
        'Expiré',
        name: 'expired',
        desc: 'Label for expired license',
      );

  String get expiringsSoon => Intl.message(
        'Expire bientôt',
        name: 'expiringsSoon',
        desc: 'Label for license expiring soon',
      );
  
  // Ajout des getters manquants
  String get refresh => Intl.message(
        'Actualiser',
        name: 'refresh',
        desc: 'Label for refresh button',
      );
  
  String get noSearchResults => Intl.message(
        'Aucun résultat trouvé',
        name: 'noSearchResults',
        desc: 'Message shown when search yields no results',
      );
  
  String get tryDifferentSearch => Intl.message(
        'Essayez une recherche différente',
        name: 'tryDifferentSearch',
        desc: 'Suggestion when search yields no results',
      );
  
  String get retry => Intl.message(
        'Réessayer',
        name: 'retry',
        desc: 'Label for retry button',
      );
  
  String get save => Intl.message(
        'Enregistrer',
        name: 'save',
        desc: 'Label for save button',
      );
} 