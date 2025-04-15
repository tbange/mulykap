import 'package:flutter/material.dart';

class RecentTransactionsWidget extends StatelessWidget {
  final bool isDarkMode;
  
  const RecentTransactionsWidget({
    Key? key,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Les données factices des transactions avec types explicites
    final List<Map<String, dynamic>> transactions = [
      {
        'clientName': 'Amadou Diallo',
        'amount': '125 €',
        'date': '20 Juillet, 2023',
        'status': 'Complété',
        'statusColor': const Color(0xFF0DBF7D),
      },
      {
        'clientName': 'Fatima Touré',
        'amount': '78 €',
        'date': '18 Juillet, 2023',
        'status': 'En attente',
        'statusColor': const Color(0xFFFF9800),
      },
      {
        'clientName': 'Mamadou Bah',
        'amount': '210 €',
        'date': '15 Juillet, 2023',
        'status': 'Complété',
        'statusColor': const Color(0xFF0DBF7D),
      },
      {
        'clientName': 'Aissatou Balde',
        'amount': '45 €',
        'date': '12 Juillet, 2023',
        'status': 'Annulé',
        'statusColor': const Color(0xFFE53057),
      },
      {
        'clientName': 'Ibrahima Sow',
        'amount': '65 €',
        'date': '10 Juillet, 2023',
        'status': 'Complété',
        'statusColor': const Color(0xFF0DBF7D),
      },
    ];

    return Container(
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
        children: [
          // En-tête
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transactions Récentes',
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
          
          // Liste des transactions
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final String clientName = transaction['clientName'] as String;
              final String date = transaction['date'] as String;
              final String amount = transaction['amount'] as String;
              final String status = transaction['status'] as String;
              final Color statusColor = transaction['statusColor'] as Color;
              
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
                  child: Text(
                    clientName.substring(0, 1),
                    style: const TextStyle(
                      color: Color(0xFF3D5AF1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  clientName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      amount,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
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
              );
            },
          ),
          
          // Bouton pour afficher plus
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF3D5AF1),
                minimumSize: const Size.fromHeight(45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Télécharger le rapport',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 