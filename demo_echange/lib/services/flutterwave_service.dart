// services/flutterwave_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class FlutterwaveService {
  // REMPLACEZ CES CLÉS PAR LES VÔTRES DEPUIS LE DASHBOARD FLUTTERWAVE
  static const String _publicKey = 'FLWPUBK_TEST-9c9ae15175422e223d54a525c801e7f7-X';
  static const String _secretKey = 'FLWSECK_TEST-9c6e80633fa34f95647462e0abd620cf-X';
  static const String _encryptionKey = 'FLWSECK_TESTf72ede50d014';
  static const String _baseUrl = 'https://api.flutterwave.com/v3';

  static String get publicKey => _publicKey;
  static String get secretKey => _secretKey;
  static String get encryptionKey => _encryptionKey;

  // Initialiser une transaction
  static Future<Map<String, dynamic>> initializeTransaction({
    required double amount,
    required String currency,
    required String customerEmail,
    required String customerName,
    required String customerPhone,
    required String itemName,
    required String reservationId,
    required String redirectUrl,
  }) async {
    final url = Uri.parse('$_baseUrl/payments');

    final txRef = 'DEVMOB_${DateTime.now().millisecondsSinceEpoch}_$reservationId';

    final payload = {
      'tx_ref': txRef,
      'amount': amount.toStringAsFixed(2),
      'currency': currency,
      'redirect_url': redirectUrl,
      'customer': {
        'email': customerEmail,
        'name': customerName,
        'phonenumber': customerPhone,
      },
      'customizations': {
        'title': 'DEVMOB - Plateforme d\'échange',
        'description': 'Paiement pour: $itemName',
        'logo': 'https://your-logo-url.com/logo.png', // Optionnel
      },
      'meta': {
        'reservation_id': reservationId,
        'item_name': itemName,
      },
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $_secretKey',
        'Content-Type': 'application/json',
      },
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        return {
          'success': true,
          'paymentLink': responseData['data']['link'],
          'txRef': txRef,
          'checkoutId': responseData['data']['id'],
        };
      } else {
        throw Exception('Échec de l\'initialisation: ${responseData['message']}');
      }
    } else {
      throw Exception('Erreur HTTP: ${response.statusCode}');
    }
  }

  // Vérifier le statut d'une transaction
  static Future<Map<String, dynamic>> verifyTransaction(String transactionId) async {
    final url = Uri.parse('$_baseUrl/transactions/$transactionId/verify');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_secretKey',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        return {
          'success': true,
          'data': responseData['data'],
          'status': responseData['data']['status'],
          'transactionId': responseData['data']['id'],
          'txRef': responseData['data']['tx_ref'],
          'amount': responseData['data']['amount'],
          'currency': responseData['data']['currency'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'],
        };
      }
    } else {
      throw Exception('Erreur HTTP: ${response.statusCode}');
    }
  }

  // Vérifier avec tx_ref
  static Future<Map<String, dynamic>> verifyTransactionByRef(String txRef) async {
    final url = Uri.parse('$_baseUrl/transactions/verify_by_reference?tx_ref=$txRef');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_secretKey',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['status'] == 'success') {
        return {
          'success': true,
          'data': responseData['data'],
          'status': responseData['data']['status'],
        };
      } else {
        return {
          'success': false,
          'error': responseData['message'],
        };
      }
    } else {
      throw Exception('Erreur HTTP: ${response.statusCode}');
    }
  }

  // Générer un lien de paiement simple
  static String generatePaymentLink({
    required String txRef,
    required double amount,
    required String publicKey,
    required String currency,
    required String customerEmail,
    required String customerName,
    required String customerPhone,
    required String itemName,
    String? redirectUrl,
  }) {
    final params = {
      'public_key': publicKey,
      'tx_ref': txRef,
      'amount': amount.toStringAsFixed(2),
      'currency': currency,
      'payment_options': 'card,mobilemoney,ussd,banktransfer',
      'customer': {
        'email': customerEmail,
        'name': customerName,
        'phonenumber': customerPhone,
      },
      'customizations': {
        'title': 'DEVMOB - Échange',
        'description': 'Paiement pour: $itemName',
      },
      'meta': {
        'reservation_id': txRef.split('_').last,
      },
    };

    if (redirectUrl != null) {
      params['redirect_url'] = redirectUrl;
    }

    return 'https://checkout.flutterwave.com/v3/hosted/pay?data=${json.encode(params)}';
  }
}