// views/payment/FlutterwavePaymentPage.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/flutterwave_provider.dart';
import '../../providers/auth-provider.dart';
import '../../models/Reservation.dart';
import '../../services/flutterwave_service.dart';
import 'PaymentSuccessPage.dart';

class FlutterwavePaymentPage extends StatefulWidget {
  final Reservation reservation;

  const FlutterwavePaymentPage({
    Key? key,
    required this.reservation,
  }) : super(key: key);

  @override
  _FlutterwavePaymentPageState createState() => _FlutterwavePaymentPageState();
}

class _FlutterwavePaymentPageState extends State<FlutterwavePaymentPage> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _paymentLink;

  @override
  void initState() {
    super.initState();
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final flutterwaveProvider = Provider.of<FlutterwaveProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.appUser!;

      // Option 1: Avec backend (recommandé)
      final paymentData = await flutterwaveProvider.initiatePayment(
        reservation: widget.reservation,
        customerEmail: user.email,
        customerName: user.name,
        customerPhone: user.phone ?? '+21600000000', // Numéro par défaut
        redirectUrl: 'https://devmob-echange.com/payment-success',
      );

      if (paymentData['success']) {
        setState(() {
          _paymentLink = paymentData['paymentLink'];
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

  // Méthode 1: Utiliser le widget Flutterwave Standard (CORRIGÉ)
  void _payWithFlutterwaveStandard() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.appUser!;

    final txRef = 'DEVMOB_${DateTime.now().millisecondsSinceEpoch}_${widget.reservation.id}';

    final Customer customer = Customer(
      name: user.name,
      phoneNumber: user.phone ?? '+21600000000',
      email: user.email,
    );

    // CORRECTION: Retirez le paramètre 'context' du constructeur
    final Flutterwave flutterwave = Flutterwave(
      publicKey: FlutterwaveService.publicKey,
      currency: "TND",
      redirectUrl: "https://devmob-echange.com/payment-success",
      txRef: txRef,
      amount: widget.reservation.totalPrice.toStringAsFixed(2),
      customer: customer,
      paymentOptions: "card, mobilemoney, ussd, banktransfer",
      customization: Customization(
        title: "DEVMOB - Échange",
        description: "Paiement pour: ${widget.reservation.itemTitle}",
        logo: "https://your-logo-url.com/logo.png",
      ),
      isTestMode: true, // Mettez à false en production
    );

    try {
      // CORRECTION: Passez le contexte à la méthode charge()
      final ChargeResponse response = await flutterwave.charge(context);

      if (response != null) {
        print("Réponse: ${response.toJson()}");

        if (response.status == "successful") {
          // Vérifier la transaction
          final flutterwaveProvider = Provider.of<FlutterwaveProvider>(context, listen: false);
          final verification = await flutterwaveProvider.verifyPayment(
            transactionId: response.transactionId,
          );

          if (verification['success'] && verification['status'] == 'successful') {
            // Confirmer le paiement
            await flutterwaveProvider.confirmPaymentSuccess(
              reservationId: widget.reservation.id,
              txRef: txRef,
              transactionId: response.transactionId!,
              amount: widget.reservation.totalPrice,
              currency: 'TND',
            );

            // Naviguer vers la page de succès
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentSuccessPage(
                  reservation: widget.reservation,
                ),
              ),
            );
          } else {
            setState(() {
              _errorMessage = 'Échec de la vérification du paiement';
            });
          }
        } else if (response.status == "cancelled") {
          setState(() {
            _errorMessage = 'Paiement annulé';
          });
        } else {
          setState(() {
            _errorMessage = 'Échec du paiement: ${response.status}';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Aucune réponse du processeur de paiement';
        });
      }
    } catch (error, stacktrace) {
      print("Erreur: $error, Stacktrace: $stacktrace");
      setState(() {
        _errorMessage = 'Erreur lors du paiement: $error';
      });
    }
  }

  // Méthode 2: Ouvrir le lien de paiement dans le navigateur (CORRIGÉ)
  Future<void> _openPaymentLink() async {
    if (_paymentLink == null) return;

    final uri = Uri.parse(_paymentLink!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      setState(() {
        _errorMessage = 'Impossible d\'ouvrir le lien de paiement';
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Résumé de la réservation
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
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

            // Méthodes de paiement
            Text(
              'Choisissez votre méthode de paiement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),

            // Option 1: Widget Flutterwave intégré (Recommandé)
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _payWithFlutterwaveStandard,
                icon: Container(
                  width: 24,
                  height: 24,
                  child: Image.asset(
                    'assets/images/flutterwave_logo.png',
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.payment),
                  ),
                ),
                label: Text('Payer avec Flutterwave'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFF5A623), // Couleur Flutterwave
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            SizedBox(height: 12),

            // Option 2: Lien de paiement
            if (_paymentLink != null)
              Container(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openPaymentLink,
                  icon: Icon(Icons.open_in_browser),
                  label: Text('Ouvrir dans le navigateur'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

            SizedBox(height: 24),

            // Options de paiement supportées
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Méthodes de paiement supportées:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text('Carte bancaire')),
                        Chip(label: Text('Mobile Money')),
                        Chip(label: Text('Virement bancaire')),
                        Chip(label: Text('USSD')),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Sécurité
            Row(
              children: [
                Icon(Icons.security, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Paiement sécurisé avec Flutterwave. Vos informations sont protégées.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Message d'erreur
            if (_errorMessage != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 24),

            // Annulation
            Container(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler et revenir'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}