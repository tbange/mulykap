import 'package:flutter/material.dart';
import 'package:mulykap_app/features/drivers/domain/models/driver.dart';
import 'package:mulykap_app/utils/app_localizations.dart';

class DriverListItem extends StatelessWidget {
  final Driver driver;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DriverListItem({
    Key? key,
    required this.driver,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    driver.fullName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildActiveStatusIndicator(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                  tooltip: t.edit,
                  iconSize: 20,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: onDelete,
                  tooltip: t.delete,
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Informations organisées en lignes
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('${t.phoneNumber}: ${driver.phoneNumber.isEmpty ? '-' : driver.phoneNumber}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.badge, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('${t.licenseNumber}: ${driver.licenseNumber}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('${t.licenseExpiryDate}: ${driver.formattedLicenseExpiryDate}'),
                const SizedBox(width: 8),
                _buildLicenseStatus(context),
              ],
            ),
            if (driver.agencyName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('${t.agency}: ${driver.agencyName}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseStatus(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    if (driver.isLicenseExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          t.expired,
          style: TextStyle(color: Colors.red.shade800, fontSize: 12),
        ),
      );
    } else if (driver.isLicenseSoonExpiring) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          t.expiringsSoon,
          style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildActiveStatusIndicator() {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: driver.isActive ? Colors.green : Colors.grey,
      ),
    );
  }
} 