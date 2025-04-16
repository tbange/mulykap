import 'package:flutter/material.dart';
import 'package:mulykap_app/common/presentation/widgets/empty_state.dart';
import 'package:mulykap_app/common/presentation/widgets/loading_indicator.dart';
import 'package:mulykap_app/features/drivers/domain/models/driver.dart';
import 'package:mulykap_app/features/drivers/domain/repositories/driver_repository.dart';
import 'package:mulykap_app/features/drivers/presentation/screens/driver_form_screen.dart';
import 'package:mulykap_app/features/drivers/presentation/widgets/driver_list_item.dart';
import 'package:mulykap_app/utils/app_localizations.dart';
import 'package:provider/provider.dart';

class DriverListScreen extends StatefulWidget {
  const DriverListScreen({Key? key}) : super(key: key);

  @override
  State<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends State<DriverListScreen> {
  late DriverRepository _driverRepository;
  List<Driver>? _drivers;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _driverRepository = context.read<DriverRepository>();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final drivers = await _driverRepository.getAllDrivers();
      setState(() {
        _drivers = drivers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorLoadingDrivers),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Driver> get _filteredDrivers {
    if (_drivers == null) return [];
    if (_searchQuery.isEmpty) return _drivers!;

    final query = _searchQuery.toLowerCase();
    return _drivers!.where((driver) {
      return driver.firstName.toLowerCase().contains(query) ||
          driver.lastName.toLowerCase().contains(query) ||
          driver.phoneNumber.toLowerCase().contains(query) ||
          driver.licenseNumber.toLowerCase().contains(query) ||
          (driver.agencyName?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  Future<void> _showDriverFormDialog([Driver? driver]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 800,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: DriverFormScreen(driver: driver),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == true) {
      _loadDrivers();
    }
  }

  Future<void> _navigateToDriverForm([Driver? driver]) async {
    return _showDriverFormDialog(driver);
  }

  Future<void> _confirmDeleteDriver(Driver driver) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteDriverTitle),
        content: Text(
          l10n.deleteDriverConfirmation(driver.fullName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      _deleteDriver(driver);
    }
  }

  Future<void> _deleteDriver(Driver driver) async {
    final l10n = AppLocalizations.of(context);
    try {
      await _driverRepository.deleteDriver(driver.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.driverDeletedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadDrivers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorDeletingDriver),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.drivers),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDrivers,
            tooltip: l10n.refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDriverFormDialog(),
        child: const Icon(Icons.add),
        tooltip: l10n.addDriver,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: l10n.search,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: LoadingIndicator())
                : _drivers == null || _drivers!.isEmpty
                    ? EmptyState(
                        icon: Icons.people,
                        title: l10n.noDriversYet,
                        subtitle: l10n.addFirstDriver,
                        buttonText: l10n.addDriver,
                        onButtonPressed: () => _showDriverFormDialog(),
                      )
                    : _filteredDrivers.isEmpty
                        ? EmptyState(
                            icon: Icons.search_off,
                            title: l10n.noSearchResults,
                            subtitle: l10n.tryDifferentSearch,
                          )
                        : ListView.builder(
                            itemCount: _filteredDrivers.length,
                            itemBuilder: (context, index) {
                              final driver = _filteredDrivers[index];
                              return DriverListItem(
                                driver: driver,
                                onEdit: () => _showDriverFormDialog(driver),
                                onDelete: () => _confirmDeleteDriver(driver),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
} 