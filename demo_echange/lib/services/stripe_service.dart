// services/stripe_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class StripeService {
  static const String _stripeApiUrl = 'https://api.stripe.com/v1';

  // REMPLACEZ CES CLÉS PAR LES VÔTRES
  static const String _secretKey = 'sk_test_votre_clé_secrète_ici';
  static const String _publishableKey = 'pk_test_votre_clé_publique_ici';

  static String get publishableKey => _publishableKey;

  static Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    required String customerEmail,
    required String itemName,
    required String reservationId,
  }) async {
    final url = Uri.parse('$_stripeApiUrl/payment_intents');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': (amount * 100).toStringAsFixed(0), // Convertir en centimes
        'currency': currency.toLowerCase(),
        'customer_email': customerEmail,
        'description': 'Paiement pour: $itemName',
        'metadata[item_name]': itemName,
        'metadata[reservation_id]': reservationId,
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Échec de création du payment intent: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> retrievePaymentIntent(String paymentIntentId) async {
    final url = Uri.parse('$_stripeApiUrl/payment_intents/$paymentIntentId');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_secretKey',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Échec de récupération du payment intent: ${response.body}');
    }
  }

  static Future<bool> confirmPaymentSuccess(String paymentIntentId) async {
    try {
      final paymentIntent = await retrievePaymentIntent(paymentIntentId);
      return paymentIntent['status'] == 'succeeded';
    } catch (e) {
      return false;
    }
  }
}