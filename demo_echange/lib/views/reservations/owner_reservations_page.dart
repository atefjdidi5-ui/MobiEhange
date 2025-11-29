import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/Reservation.dart';
import '../../providers/auth-provider.dart';
import '../../providers/reservation_provider.dart';

class OwnerReservationsPage extends StatefulWidget {
  @override
  _OwnerReservationsPageState createState() => _OwnerReservationsPageState();
}

class _OwnerReservationsPageState extends State<OwnerReservationsPage> {
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
      reservationProvider.loadOwnerReservations(authProvider.appUser!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reservationProvider = Provider.of<ReservationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Demandes de Réservation'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: reservationProvider.isLoading && reservationProvider.receivedReservations.isEmpty
                ? Center(child: CircularProgressIndicator())
                : _buildReservationsList(reservationProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Text('Filtrer: '),
          SizedBox(width: 8),
          DropdownButton<String>(
            value: _filterStatus,
            onChanged: (String? newValue) {
              setState(() {
                _filterStatus = newValue!;
              });
            },
            items: [
              DropdownMenuItem(value: 'all', child: Text('Toutes')),
              DropdownMenuItem(value: 'pending', child: Text('En attente')),
              DropdownMenuItem(value: 'accepted', child: Text('Acceptées')),
              DropdownMenuItem(value: 'rejected', child: Text('Refusées')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsList(ReservationProvider reservationProvider) {
    final filteredReservations = reservationProvider.receivedReservations.where((reservation) {
      if (_filterStatus == 'all') return true;
      return reservation.status == _filterStatus;
    }).toList();

    if (filteredReservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.request_quote, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Aucune demande de réservation',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Les demandes pour vos objets apparaîtront ici',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredReservations.length,
      itemBuilder: (context, index) {
        final reservation = filteredReservations[index];
        return _buildReservationCard(reservation);
      },
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    Color statusColor;
    IconData statusIcon;

    switch (reservation.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reservation.itemTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      SizedBox(width: 4),
                      Text(
                        _getStatusText(reservation.status),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text('Locataire: ${reservation.renterName}'),
            SizedBox(height: 8),
            Text('Prix total: ${reservation.totalPrice.toStringAsFixed(2)} TND'),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '${DateFormat('dd/MM/yyyy').format(reservation.startDate)} - ${DateFormat('dd/MM/yyyy').format(reservation.endDate)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              '${reservation.numberOfDays} jour(s)',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (reservation.message != null && reservation.message!.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                'Message: ${reservation.message}',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            SizedBox(height: 12),
            if (reservation.status == 'pending')
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateReservationStatus(reservation.id, 'accepted'),
                      child: Text('Accepter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateReservationStatus(reservation.id, 'rejected'),
                      child: Text('Refuser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'En attente';
      case 'accepted': return 'Acceptée';
      case 'rejected': return 'Refusée';
      case 'completed': return 'Terminée';
      case 'cancelled': return 'Annulée';
      default: return status;
    }
  }

  void _updateReservationStatus(String reservationId, String status) {
    String action = status == 'accepted' ? 'accepter' : 'refuser';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer l\'action'),
          content: Text('Êtes-vous sûr de vouloir $action cette réservation ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
                await reservationProvider.updateReservationStatus(reservationId, status);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Réservation ${action == 'accepter' ? 'acceptée' : 'refusée'}')),
                );
              },
              child: Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }
}