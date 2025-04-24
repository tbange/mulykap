import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/recurring_trips/data/repositories/recurring_trip_repository.dart';
import 'package:mulykap_app/features/recurring_trips/domain/models/recurring_trip_model.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_bloc.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_event.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/bloc/recurring_trip_state.dart';
import 'package:mulykap_app/features/recurring_trips/presentation/screens/recurring_trip_edit_screen.dart';
import 'package:mulykap_app/features/buses/data/repositories/bus_repository.dart';
import 'package:mulykap_app/features/routes/data/repositories/route_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecurringTripEditDialog extends StatelessWidget {
  const RecurringTripEditDialog({Key? key}) : super(key: key);

  /// Affiche la boîte de dialogue pour modifier un voyage récurrent
  static Future<bool> show(BuildContext context, RecurringTripModel trip) async {
    bool tripUpdated = false;
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
                  RepositoryProvider<RouteRepository>(
                    create: (context) => RouteRepository(
                      supabaseClient: supabaseClient,
                    ),
                  ),
                  RepositoryProvider<BusRepository>(
                    create: (context) => BusRepository(
                      supabaseClient: supabaseClient,
                    ),
                  ),
                  RepositoryProvider<RecurringTripRepository>(
                    create: (context) => RecurringTripRepository(
                      supabaseClient: supabaseClient,
                    ),
                  ),
                ],
                child: BlocProvider(
                  create: (context) => RecurringTripBloc(
                    repository: context.read<RecurringTripRepository>(),
                  ),
                  child: BlocListener<RecurringTripBloc, RecurringTripState>(
                    listenWhen: (previous, current) {
                      // Écouter seulement les états après une action réussie
                      return previous.isLoading && !current.isLoading && current.error == null;
                    },
                    listener: (context, state) {
                      // Marquer le voyage comme mis à jour et fermer le dialogue
                      tripUpdated = true;
                      Navigator.of(dialogContext).pop();
                    },
                    child: RecurringTripEditScreen(trip: trip),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    
    // Retourner un booléen indiquant si un voyage a été mis à jour
    return tripUpdated;
  }

  @override
  Widget build(BuildContext context) {
    // Ce widget ne sera jamais construit directement
    // Il est utilisé uniquement via sa méthode statique show()
    return const SizedBox();
  }
} 