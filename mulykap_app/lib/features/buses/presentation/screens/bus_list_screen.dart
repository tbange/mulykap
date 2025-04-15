import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mulykap_app/features/buses/domain/models/bus_model.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/bus_bloc.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/bus_event.dart';
import 'package:mulykap_app/features/buses/presentation/bloc/bus_state.dart';
import 'package:mulykap_app/features/dashboard/presentation/widgets/responsive_layout.dart';
import 'package:mulykap_app/features/buses/presentation/widgets/bus_form_dialog.dart';
import 'package:mulykap_app/features/buses/presentation/widgets/bus_detail_drawer.dart';

class BusListScreen extends StatefulWidget {
  const BusListScreen({Key? key}) : super(key: key);

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> {
  // Contrôleur pour le drawer de détails
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  BusModel? _selectedBus;

  @override
  void initState() {
    super.initState();
    context.read<BusBloc>().add(const BusLoadAll());
  }

  // Méthode pour afficher les détails d'un bus dans un drawer
  void _showBusDetails(BusModel bus) {
    setState(() {
      _selectedBus = bus;
    });
    _scaffoldKey.currentState?.openEndDrawer();
  }

  // Méthode pour modifier un bus dans une boîte de dialogue
  void _editBus(BusModel bus) {
    BusFormDialog.show(
      context: context,
      bus: bus,
      isEditing: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Gestion des Bus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter un bus',
            onPressed: () {
              BusFormDialog.show(context: context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: () {
              context.read<BusBloc>().add(const BusLoadAll());
            },
          ),
        ],
      ),
      // Drawer de détails à droite
      endDrawer: _selectedBus != null 
          ? BusDetailDrawer(
              bus: _selectedBus!,
              onEdit: () {
                Navigator.of(context).pop(); // Fermer le drawer
                _editBus(_selectedBus!);
              },
            )
          : null,
      body: BlocBuilder<BusBloc, BusState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.isError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${state.error}',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<BusBloc>().add(const BusLoadAll());
                    },
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (state.buses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.directions_bus_outlined,
                    color: Colors.grey,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun bus trouvé',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      BusFormDialog.show(context: context);
                    },
                    child: const Text('Ajouter un bus'),
                  ),
                ],
              ),
            );
          }

          return ResponsiveLayout(
            mobile: _buildBusList(context, state.buses, isMobile: true),
            tablet: _buildBusList(context, state.buses),
            desktop: _buildBusTable(context, state.buses),
          );
        },
      ),
    );
  }

  Widget _buildBusList(BuildContext context, List<BusModel> buses, {bool isMobile = false}) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: buses.length,
      itemBuilder: (context, index) {
        final bus = buses[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                _getBusTypeIcon(bus.type),
                color: Colors.white,
              ),
            ),
            title: Text(
              bus.model,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${bus.type.displayName}'),
                Text('Immatriculation: ${bus.licensePlate}'),
                Text('Capacité: ${bus.capacity} sièges'),
              ],
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Modifier',
                  onPressed: () => _editBus(bus),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Supprimer',
                  onPressed: () {
                    _showDeleteConfirmation(context, bus);
                  },
                ),
              ],
            ),
            onTap: () => _showBusDetails(bus),
          ),
        );
      },
    );
  }

  Widget _buildBusTable(BuildContext context, List<BusModel> buses) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: PaginatedDataTable(
          header: const Text('Liste des Bus'),
          rowsPerPage: 10,
          columns: const [
            DataColumn(label: Text('Immatriculation')),
            DataColumn(label: Text('Modèle')),
            DataColumn(label: Text('Type')),
            DataColumn(label: Text('Capacité')),
            DataColumn(label: Text('Bagages (kg)')),
            DataColumn(label: Text('Volume (m³)')),
            DataColumn(label: Text('Actions')),
          ],
          source: _BusDataSource(buses, context, 
            onView: _showBusDetails,
            onEdit: _editBus,
            onDelete: (bus) => _showDeleteConfirmation(context, bus)
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, BusModel bus) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmation de suppression'),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer le bus ${bus.model} (${bus.licensePlate}) ?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                context.read<BusBloc>().add(BusDelete(bus.id));
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  IconData _getBusTypeIcon(BusType type) {
    switch (type) {
      case BusType.MINIBUS_20P:
        return Icons.airport_shuttle;
      case BusType.VIP_32P:
        return Icons.airline_seat_recline_extra;
      case BusType.LUXE_50P:
        return Icons.directions_bus;
      case BusType.BUS_40P:
        return Icons.directions_bus_filled;
      case BusType.COACH_50P:
        return Icons.airport_shuttle_outlined;
      case BusType.DOUBLE_DECKER_70P:
        return Icons.tram;
      default:
        return Icons.directions_bus;
    }
  }
}

// DataSource pour le tableau
class _BusDataSource extends DataTableSource {
  final List<BusModel> _buses;
  final BuildContext _context;
  final Function(BusModel) onView;
  final Function(BusModel) onEdit;
  final Function(BusModel) onDelete;

  _BusDataSource(this._buses, this._context, {
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  DataRow getRow(int index) {
    final bus = _buses[index];
    return DataRow(
      cells: [
        DataCell(Text(bus.licensePlate)),
        DataCell(Text(bus.model)),
        DataCell(Text(bus.type.displayName)),
        DataCell(Text('${bus.capacity}')),
        DataCell(Text('${bus.baggageCapacityKg}')),
        DataCell(Text('${bus.baggageVolumeM3}')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility),
                tooltip: 'Détails',
                onPressed: () => onView(bus),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Modifier',
                onPressed: () => onEdit(bus),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Supprimer',
                onPressed: () => onDelete(bus),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _buses.length;

  @override
  int get selectedRowCount => 0;
}
     