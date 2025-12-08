import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/Reservation.dart';

class PaymentSuccessPage extends StatelessWidget {
  final List<Reservation> reservations;
  final String? receiptUrl;

  const PaymentSuccessPage({
    Key? key,
    required this.reservations,
    this.receiptUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 100,
              ),
              SizedBox(height: 24),
              Text(
                'Paiement réussi !',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Votre réservation a été confirmée',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 24),

              // Détails de la réservation
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Détails de la réservation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 12),
                      ...reservations.map((reservation) => ListTile(
                        title: Text(reservation.itemTitle),
                        subtitle: Text(
                          '${reservation.startDate.day}/${reservation.startDate.month}/${reservation.startDate.year} - ${reservation.endDate.day}/${reservation.endDate.month}/${reservation.endDate.year}',
                        ),
                        trailing: Text('${reservation.totalPrice} TND'),
                      )).toList(),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Boutons d'action
              if (receiptUrl != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: OutlinedButton.icon(
                    onPressed: () => _launchReceipt(receiptUrl!),
                    icon: Icon(Icons.receipt),
                    label: Text('Voir le reçu'),
                  ),
                ),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                        (route) => false,
                  );
                },
                child: Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchReceipt(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}