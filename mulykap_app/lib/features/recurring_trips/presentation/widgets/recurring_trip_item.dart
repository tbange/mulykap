import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mulykap_app/features/recurring_trips/domain/models/recurring_trip_model.dart';

class RecurringTripItem extends StatelessWidget {
  final RecurringTripModel trip;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;
  final VoidCallback? onGenerate;

  const RecurringTripItem({
    Key? key,
    required this.trip,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
    this.onGenerate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final validFrom = dateFormat.format(trip.validFrom);
    final validUntil = trip.validUntil != null ? dateFormat.format(trip.validUntil!) : 'Indéfini';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec itinéraire et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      trip.routeName ?? 'Itinéraire inconnu',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trip.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: trip.isActive ? Colors.green : Colors.grey,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trip.isActive ? Icons.check_circle : Icons.cancel,
                          size: 16,
                          color: trip.isActive ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trip.isActive ? 'Actif' : 'Inactif',
                          style: TextStyle(
                            fontSize: 12,
                            color: trip.isActive ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Jours de la semaine
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    trip.getWeekdaysText(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Horaires
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Départ',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          trip.departureTime,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Arrivée',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          trip.arrivalTime,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Période de validité
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Valide du',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          validFrom,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jusqu\'au',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          validUntil,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bus
              Row(
                children: [
                  const Icon(Icons.directions_bus, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      trip.busPlate != null 
                          ? trip.busPlate! 
                          : 'Bus non assigné (sera défini lors de la création du voyage)',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: trip.busPlate == null ? FontStyle.italic : FontStyle.normal,
                        color: trip.busPlate == null ? Colors.grey : Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Prix et actions
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Prix du billet
                  RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: [
                        const TextSpan(
                          text: 'Prix: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        TextSpan(
                          text: '${trip.basePrice.toStringAsFixed(2)} FC',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions
                  Row(
                    children: [
                      if (onGenerate != null && trip.isActive)
                        IconButton(
                          icon: const Icon(Icons.calendar_month, size: 20),
                          tooltip: 'Générer voyages',
                          onPressed: onGenerate,
                          color: Colors.orange,
                        ),
                      if (onToggleStatus != null)
                        IconButton(
                          icon: Icon(
                            trip.isActive ? Icons.pause_circle : Icons.play_circle,
                            size: 20,
                          ),
                          tooltip: trip.isActive ? 'Désactiver' : 'Activer',
                          onPressed: onToggleStatus,
                        ),
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: 'Modifier',
                          onPressed: onEdit,
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          tooltip: 'Supprimer',
                          onPressed: onDelete,
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 