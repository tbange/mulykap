import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/recurring_trips/data/repositories/recurring_trip_repository.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_bloc.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_event.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_state.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/screens/trip_generation_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mulykap_app/features/drivers/data/repositories/driver_repository.dart';

class TripGenerationDialog extends StatelessWidget {
  final String? recurringTripId;

  const TripGenerationDialog({Key? key, this.recurringTripId}) : super(key: key);

  /// Affiche la boîte de dialogue pour générer des voyages
  static Future<bool> show(BuildContext context, {String? recurringTripId}) async {
    bool tripsGenerated = false;
    // Obtenir l'instance Supabase
    final supabaseClient = Supabase.instance.client;
    
    await showDialog(
      context: context,
      barrierDismissible: false, // Empêcher la fermeture en cliquant à l'extérieur
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          // Empêcher le retour arrière jusqu'à ce que la boîte de dialogue se ferme explicitement
          onWillPop: () async => true,
          child: Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 600),
              child: MultiRepositoryProvider(
                providers: [
                  // Créer de nouvelles instances des repositories nécessaires
                  RepositoryProvider<RecurringTripRepository>(
                    create: (context) => RecurringTripRepository(
                      supabaseClient: supabaseClient,
                    ),
                  ),
                  RepositoryProvider<DriverRepository>(
                    create: (context) => DriverRepository(
                      supabaseClient: supabaseClient,
                    ),
                  ),
                ],
                child: BlocProvider<RecurringTripBloc>(
                  create: (context) => RecurringTripBloc(
                    repository: context.read<RecurringTripRepository>(),
                  ),
                  child: BlocListener<RecurringTripBloc, RecurringTripState>(
                    listenWhen: (previous, current) {
                      // Écouter seulement les états après une génération réussie
                      return previous.isGenerating && current.isGenerationSuccess;
                    },
                    listener: (context, state) {
                      // Marquer la génération comme effectuée et fermer le dialogue
                      tripsGenerated = true;
                      Navigator.of(dialogContext).pop();
                    },
                    child: TripGenerationScreen(recurringTripId: recurringTripId),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    
    // Retourner un booléen indiquant si des voyages ont été générés
    return tripsGenerated;
  }

  @override
  Widget build(BuildContext context) {
    // Ce widget ne sera jamais construit directement
    // Il est utilisé uniquement via sa méthode statique show()
    return const SizedBox();
  }
} 