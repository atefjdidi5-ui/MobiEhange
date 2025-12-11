import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/Reservation.dart';
import '../../providers/auth-provider.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/review_provider.dart';
import '../payment/FlutterwavePaymentPage.dart';
import '../review/leave_review_page.dart';

class MyReservationsPage extends StatefulWidget {
  @override
  _MyReservationsPageState createState() => _MyReservationsPageState();
}

class _MyReservationsPageState extends State<MyReservationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
      reservationProvider.loadUserReservations(authProvider.appUser!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reservationProvider = Provider.of<ReservationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Réservations'),
        backgroundColor: Colors.blue,
      ),
      body: reservationProvider.isLoading && reservationProvider.reservations.isEmpty
          ? Center(child: CircularProgressIndicator())
          : _buildReservationsList(reservationProvider),
    );
  }

  Widget _buildReservationsList(ReservationProvider reservationProvider) {
    if (reservationProvider.reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Aucune réservation',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Vos réservations apparaîtront ici',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.appUser?.id;

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: reservationProvider.reservations.length,
      itemBuilder: (context, index) {
        final reservation = reservationProvider.reservations[index];
        return _buildReservationCard(reservation, currentUserId);
      },
    );
  }

  Widget _buildReservationCard(Reservation reservation, String? currentUserId) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (reservation.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        statusText = 'En attente';
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Acceptée';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Refusée';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        statusText = 'Terminée';
        break;
      case 'cancelled':
        statusColor = Colors.grey;
        statusIcon = Icons.cancel;
        statusText = 'Annulée';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Inconnu';
    }

    // Vérifier si le paiement est possible
    final bool canPay = reservation.status == 'accepted' &&
        reservation.paymentStatus == 'pending';
    final bool isPaid = reservation.paymentStatus == 'paid';

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
                        statusText,
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

            // Statut de paiement
            if (reservation.status == 'accepted')
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPaymentStatusColor(reservation.paymentStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getPaymentStatusColor(reservation.paymentStatus)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPaymentStatusIcon(reservation.paymentStatus),
                      size: 14,
                      color: _getPaymentStatusColor(reservation.paymentStatus),
                    ),
                    SizedBox(width: 4),
                    Text(
                      _getPaymentStatusText(reservation.paymentStatus),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getPaymentStatusColor(reservation.paymentStatus),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),


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

            // Boutons d'action
            Column(
              children: [
                // Bouton de paiement si la réservation est acceptée et non payée
                if (canPay)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _proceedToPayment(reservation),
                      icon: Icon(Icons.payment, size: 20),
                      label: Text(
                        'Payer ${reservation.totalPrice.toStringAsFixed(2)} TND',
                        style: TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF5A623), // Couleur Flutterwave
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                // Bouton d'annulation si en attente
                if (reservation.status == 'pending')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _cancelReservation(reservation.id),
                      child: Text('Annuler la réservation'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                // Bouton de détails si payée
                if (isPaid && reservation.paymentReceiptUrl != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showPaymentDetails(reservation),
                      icon: Icon(Icons.receipt, size: 20),
                      label: Text('Voir le reçu'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),

            // REVIEW SECTION - SIMPLIFIED TEST VERSION
            // First, let's test if the section appears at all
            if (reservation.isPaid)
              Container(
                margin: EdgeInsets.only(top: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50], // Changed to green to make it visible
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'TEST: REVIEW SECTION',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Debug info
                    Text(
                      'Reservation isPaid: ${reservation.isPaid}',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      'PaymentStatus: ${reservation.paymentStatus}',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      'currentUserId: $currentUserId',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      'renterId: ${reservation.renterId}',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      'ownerId: ${reservation.ownerId}',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      'isRenter: ${currentUserId == reservation.renterId}',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      'isOwner: ${currentUserId == reservation.ownerId}',
                      style: TextStyle(fontSize: 12),
                    ),

                    SizedBox(height: 12),

                    // Test button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          print('Test review button clicked!');
                          print('Reservation ID: ${reservation.id}');
                          print('User role: ${currentUserId == reservation.renterId ? 'Renter' : 'Owner'}');

                          // Test navigation
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LeaveReviewPage(
                                reservation: reservation,
                                isReviewingOwner: true, // Default to reviewing owner
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('TEST: Leave Review'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _reviewOwner(Reservation reservation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => ReviewProvider(),
          child: LeaveReviewPage(
            reservation: reservation,
            isReviewingOwner: true,
          ),
        ),
      ),
    );
  }

  void _reviewRenter(Reservation reservation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (context) => ReviewProvider(),
          child: LeaveReviewPage(
            reservation: reservation,
            isReviewingOwner: false,
          ),
        ),
      ),
    );
  }

  // Méthodes pour le statut de paiement
  Color _getPaymentStatusColor(String paymentStatus) {
    switch (paymentStatus) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentStatusIcon(String paymentStatus) {
    switch (paymentStatus) {
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getPaymentStatusText(String paymentStatus) {
    switch (paymentStatus) {
      case 'paid':
        return 'Payée';
      case 'pending':
        return 'Paiement en attente';
      case 'failed':
        return 'Paiement échoué';
      case 'cancelled':
        return 'Paiement annulé';
      default:
        return 'Statut inconnu';
    }
  }

  void _proceedToPayment(Reservation reservation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlutterwavePaymentPage(
          reservation: reservation,
        ),
      ),
    );
  }

  void _cancelReservation(String reservationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Annuler la réservation'),
          content: Text('Êtes-vous sûr de vouloir annuler cette réservation ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Non'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
                await reservationProvider.updateReservationStatus(reservationId, 'cancelled');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Réservation annulée')),
                );
              },
              child: Text('Oui'),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentDetails(Reservation reservation) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Détails du paiement'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.shopping_bag),
                  title: Text('Article'),
                  subtitle: Text(reservation.itemTitle),
                ),
                ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text('Période'),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy').format(reservation.startDate)} - ${DateFormat('dd/MM/yyyy').format(reservation.endDate)}',
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.attach_money),
                  title: Text('Montant payé'),
                  subtitle: Text(
                    '${reservation.totalPrice.toStringAsFixed(2)} TND',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                if (reservation.flutterwaveTxRef != null)
                  ListTile(
                    leading: Icon(Icons.receipt),
                    title: Text('Référence transaction'),
                    subtitle: Text(reservation.flutterwaveTxRef!),
                  ),
                if (reservation.paymentReceiptUrl != null)
                  ListTile(
                    leading: Icon(Icons.link),
                    title: Text('Lien du reçu'),
                    subtitle: Text(
                      'Cliquez pour ouvrir',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    onTap: () {
                      // Ici vous pouvez ajouter la logique pour ouvrir le lien
                      // _openReceiptUrl(reservation.paymentReceiptUrl!);
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}