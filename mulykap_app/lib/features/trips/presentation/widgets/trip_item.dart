import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mulykap_app/features/trips/domain/models/trip_model.dart';

class TripItem extends StatelessWidget {
  final TripModel trip;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onStatusChange;

  const TripItem({
    Key? key,
    required this.trip,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
  }) : super(key: key);

  // Couleur selon le statut du voyage
  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.planned:
        return Colors.blue;
      case TripStatus.in_progress:
        return Colors.green;
      case TripStatus.completed:
        return Colors.grey;
      case TripStatus.cancelled:
        return Colors.red;
    }
  }

  // Icône selon le statut du voyage
  IconData _getStatusIcon(TripStatus status) {
    switch (status) {
      case TripStatus.planned:
        return Icons.schedule;
      case TripStatus.in_progress:
        return Icons.directions_bus;
      case TripStatus.completed:
        return Icons.check_circle;
      case TripStatus.cancelled:
        return Icons.cancel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
    final DateFormat timeFormat = DateFormat('HH:mm');
    
    final departureDate = dateFormat.format(trip.departureTime);
    final departureTime = timeFormat.format(trip.departureTime);
    final arrivalTime = timeFormat.format(trip.arrivalTime);

    // Calculer la durée du voyage
    final duration = trip.arrivalTime.difference(trip.departureTime);
    final durationHours = duration.inHours;
    final durationMinutes = duration.inMinutes.remainder(60);
    final durationText = durationHours > 0 
        ? '$durationHours h ${durationMinutes > 0 ? '$durationMinutes min' : ''}'
        : '$durationMinutes min';

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
              // En-tête avec itinéraire et date
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
                      color: _getStatusColor(trip.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(trip.status),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(trip.status),
                          size: 16,
                          color: _getStatusColor(trip.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trip.status.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(trip.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Informations de départ et arrivée
              Row(
                children: [
                  // Heure de départ
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Départ',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              departureTime,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Durée
                  Column(
                    children: [
                      Text(
                        durationText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 1,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            const Icon(
                              Icons.arrow_right_alt,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Heure d'arrivée
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Arrivée',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(Icons.schedule, size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              arrivalTime,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informations sur le bus et le chauffeur
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          departureDate,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bus',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          trip.busPlate ?? 'Non assigné',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chauffeur',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          trip.driverName ?? 'Non assigné',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Ligne en bas avec prix et actions
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
                      if (onStatusChange != null)
                        IconButton(
                          icon: const Icon(Icons.update, size: 20),
                          tooltip: 'Changer le statut',
                          onPressed: onStatusChange,
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