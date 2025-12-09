// views/payment/PaymentSuccessPage.dart
import 'package:flutter/material.dart';
import '../../models/Reservation.dart';
import '../home/home_page.dart';

class PaymentSuccessPage extends StatelessWidget {
  final Reservation reservation;

  const PaymentSuccessPage({
    Key? key,
    required this.reservation,
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
                'Votre réservation a été confirmée et payée',
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
                      ListTile(
                        title: Text('Article:'),
                        subtitle: Text(reservation.itemTitle),
                      ),
                      ListTile(
                        title: Text('Période:'),
                        subtitle: Text(
                          '${reservation.startDate.day}/${reservation.startDate.month}/${reservation.startDate.year} - ${reservation.endDate.day}/${reservation.endDate.month}/${reservation.endDate.year}',
                        ),
                      ),
                      ListTile(
                        title: Text('Prix total:'),
                        subtitle: Text(
                          '${reservation.totalPrice.toStringAsFixed(2)} TND',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Bouton pour retourner à l'accueil
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
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
}