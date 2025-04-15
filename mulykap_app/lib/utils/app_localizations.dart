import 'package:flutter/material.dart';

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
} 