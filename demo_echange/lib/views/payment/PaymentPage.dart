// views/payment/PaymentPage.dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import '../../providers/stripe_provider.dart';
import '../../providers/auth-provider.dart';
import '../../models/Reservation.dart';
import 'PaymentSuccessPage.dart';

class PaymentPage extends StatefulWidget {
  final Reservation reservation;

  const PaymentPage({
    Key? key,
    required this.reservation,
  }) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardController = CardEditController();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _paymentData;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  Future<void> _initializePayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stripeProvider = Provider.of<StripeProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.appUser!;

      // Initialiser le paiement
      final paymentData = await stripeProvider.initiatePaymentForReservation(
        reservationId: widget.reservation.id,
        customerEmail: user.email,
        customerName: user.name, // Utilisez 'name' au lieu de 'fullName'
      );

      if (paymentData['success']) {
        setState(() {
          _paymentData = paymentData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = paymentData['error'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur d\'initialisation: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _processPayment() async {
    if (_paymentData == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stripeProvider = Provider.of<StripeProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.appUser!;

      final paymentResult = await stripeProvider.processPayment(
        clientSecret: _paymentData!['clientSecret'],
        customerEmail: user.email,
        customerName: user.name, // Utilisez 'name' au lieu de 'fullName'
      );

      if (paymentResult['success']) {
        // Paiement réussi
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessPage(
              reservation: widget.reservation,
              receiptUrl: paymentResult['receiptUrl'],
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = paymentResult['error'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du paiement: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paiement sécurisé'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading && _paymentData == null
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null && _paymentData == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 64),
            SizedBox(height: 16),
            Text(
              'Erreur',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Retour'),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé de la réservation
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Résumé du paiement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Article:'),
                        Text(widget.reservation.itemTitle),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Période:'),
                        Text('${widget.reservation.numberOfDays} jour(s)'),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Prix total:'),
                        Text(
                          '${widget.reservation.totalPrice.toStringAsFixed(2)} TND',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Informations de carte
            Text(
              'Informations de carte',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),

            CardField(
              controller: _cardController,
              style: CardFieldStyle(
                borderWidth: 1,
                borderRadius: BorderRadius.circular(8),
                textColor: Colors.black,
                backgroundColor: Colors.white,
                borderColor: Colors.grey[400]!,
                cursorColor: Colors.blue,
                textErrorColor: Colors.red,
                placeholderColor: Colors.grey,
              ),
            ),

            SizedBox(height: 16),

            // Sécurité
            Row(
              children: [
                Icon(Icons.lock, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Paiement sécurisé avec Stripe. Vos informations de carte sont chiffrées.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Message d'erreur
            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),

            // Bouton de paiement
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Payer ${widget.reservation.totalPrice.toStringAsFixed(2)} TND',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Annulation
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: Text('Annuler'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}