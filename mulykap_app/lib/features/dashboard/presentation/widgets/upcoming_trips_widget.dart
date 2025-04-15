import 'package:flutter/material.dart';
import 'responsive_layout.dart';

class UpcomingTripsWidget extends StatelessWidget {
  final bool isDarkMode;
  
  const UpcomingTripsWidget({
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Données factices des prochains voyages avec types explicites
    final List<Map<String, dynamic>> trips = [
      {
        'id': 'TX1234',
        'origin': 'Conakry',
        'destination': 'Kankan',
        'departure': '08:00',
        'arrival': '16:30',
        'date': '25 Juillet, 2023',
        'bus': 'MulyExpress 001',
        'available': 28,
        'total': 45,
        'status': 'En attente',
        'statusColor': const Color(0xFFFF9800),
      },
      {
        'id': 'TX1235',
        'origin': 'Conakry',
        'destination': 'Labé',
        'departure': '09:30',
        'arrival': '15:45',
        'date': '26 Juillet, 2023',
        'bus': 'MulyExpress 003',
        'available': 12,
        'total': 45,
        'status': 'Confirmé',
        'statusColor': const Color(0xFF0DBF7D),
      },
      {
        'id': 'TX1236',
        'origin': 'Nzérékoré',
        'destination': 'Conakry',
        'departure': '06:15',
        'arrival': '18:30',
        'date': '27 Juillet, 2023',
        'bus': 'MulyExpress 007',
        'available': 32,
        'total': 45,
        'status': 'Confirmé',
        'statusColor': const Color(0xFF0DBF7D),
      },
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prochains Voyages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECF0FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(
                      color: Color(0xFF3D5AF1),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // En-têtes de colonnes (seulement sur desktop et tablette)
          if (!ResponsiveLayout.isMobile(context))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const SizedBox(width: 50), // Pour l'ID
                  Expanded(
                    flex: 2,
                    child: Text(
                      'TRAJET',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'DATE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'BUS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'PLACES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 100), // Pour le statut
                ],
              ),
            ),
          
          const SizedBox(height: 10),
          
          // Liste des voyages
          ResponsiveLayout.isMobile(context)
              ? _buildMobileList(trips)
              : _buildDesktopList(trips),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMobileList(List<Map<String, dynamic>> trips) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: trips.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
      ),
      itemBuilder: (context, index) {
        final trip = trips[index];
        final String id = trip['id'] as String;
        final String origin = trip['origin'] as String;
        final String destination = trip['destination'] as String;
        final String departure = trip['departure'] as String;
        final String arrival = trip['arrival'] as String;
        final String date = trip['date'] as String;
        final String bus = trip['bus'] as String;
        final int available = trip['available'] as int;
        final int total = trip['total'] as int;
        final String status = trip['status'] as String;
        final Color statusColor = trip['statusColor'] as Color;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ID et Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: $id',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Origine - Destination
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'De',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          origin,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          departure,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Icon(
                      Icons.arrow_forward,
                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'À',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          destination,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          arrival,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Informations sur le bus et les places
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bus,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Places',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$available/$total',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopList(List<Map<String, dynamic>> trips) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(50), // ID
        1: FlexColumnWidth(2),   // Trajet
        2: FlexColumnWidth(1),   // Date
        3: FlexColumnWidth(1),   // Bus
        4: FlexColumnWidth(1),   // Places
        5: FixedColumnWidth(120), // Status
      },
      children: trips.asMap().entries.map((entry) {
        final index = entry.key;
        final trip = entry.value;
        final String id = trip['id'] as String;
        final String origin = trip['origin'] as String;
        final String destination = trip['destination'] as String;
        final String date = trip['date'] as String;
        final String bus = trip['bus'] as String;
        final int available = trip['available'] as int;
        final int total = trip['total'] as int;
        final String status = trip['status'] as String;
        final Color statusColor = trip['statusColor'] as Color;
        
        return TableRow(
          decoration: BoxDecoration(
            color: index.isOdd 
                ? (isDarkMode ? const Color(0xFF252525) : const Color(0xFFF9FAFC)) 
                : null,
          ),
          children: [
            // ID
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                child: Text(
                  id,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            
            // Trajet
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        origin,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        size: 16,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        destination,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Date
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                child: Text(
                  date,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            
            // Bus
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                child: Text(
                  bus,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            
            // Places
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                child: Text(
                  '$available/$total',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            
            // Status
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
} 