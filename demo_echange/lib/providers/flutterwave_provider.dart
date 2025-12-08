// providers/flutterwave_provider.dart
import 'package:flutter/material.dart';
import '../services/flutterwave_service.dart';
import '../services/reservation_service.dart';
import '../models/Reservation.dart';

class FlutterwaveProvider with ChangeNotifier {
  final ReservationService _reservationService = ReservationService();

  bool _isProcessing = false;
  bool _isVerifying = false;
  String? _paymentLink;
  String? _txRef;

  bool get isProcessing => _isProcessing;
  bool get isVerifying => _isVerifying;
  String? get paymentLink => _paymentLink;
  String? get txRef => _txRef;

  // Initialiser un paiement
  Future<Map<String, dynamic>> initiatePayment({
    required Reservation reservation,
    required String customerEmail,
    required String customerName,
    required String customerPhone,
    String redirectUrl = 'https://devmob-echange.com/payment-success', // Votre URL de callback
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      final paymentData = await FlutterwaveService.initializeTransaction(
        amount: reservation.totalPrice,
        currency: 'TND', // Tunisian Dinar
        customerEmail: customerEmail,
        customerName: customerName,
        customerPhone: customerPhone,
        itemName: reservation.itemTitle,
        reservationId: reservation.id,
        redirectUrl: redirectUrl,
      );

      if (paymentData['success']) {
        _paymentLink = paymentData['paymentLink'];
        _txRef = paymentData['txRef'];

        // Mettre à jour la réservation avec txRef
        await _reservationService.updateReservationPaymentStatus(
          reservationId: reservation.id,
          paymentStatus: 'pending',
          flutterwaveTxRef: _txRef,
          flutterwaveCheckoutId: paymentData['checkoutId'],
        );

        _isProcessing = false;
        notifyListeners();

        return {
          'success': true,
          'paymentLink': _paymentLink,
          'txRef': _txRef,
          'checkoutId': paymentData['checkoutId'],
        };
      } else {
        throw Exception('Échec de l\'initialisation du paiement');
      }
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Générer un lien de paiement simple (sans backend)
  String generateDirectPaymentLink({
    required Reservation reservation,
    required String customerEmail,
    required String customerName,
    required String customerPhone,
  }) {
    _txRef = 'DEVMOB_${DateTime.now().millisecondsSinceEpoch}_${reservation.id}';

    _paymentLink = FlutterwaveService.generatePaymentLink(
      txRef: _txRef!,
      amount: reservation.totalPrice,
      publicKey: FlutterwaveService.publicKey,
      currency: 'TND',
      customerEmail: customerEmail,
      customerName: customerName,
      customerPhone: customerPhone,
      itemName: reservation.itemTitle,
      redirectUrl: 'https://devmob-echange.com/payment-success',
    );

    return _paymentLink!;
  }

  // Vérifier le statut d'un paiement
  Future<Map<String, dynamic>> verifyPayment({
    String? transactionId,
    String? txRef,
  }) async {
    _isVerifying = true;
    notifyListeners();

    try {
      Map<String, dynamic> verificationResult;

      if (transactionId != null) {
        verificationResult = await FlutterwaveService.verifyTransaction(transactionId);
      } else if (txRef != null) {
        verificationResult = await FlutterwaveService.verifyTransactionByRef(txRef);
      } else {
        throw Exception('Transaction ID ou tx_ref requis');
      }

      _isVerifying = false;
      notifyListeners();

      return verificationResult;
    } catch (e) {
      _isVerifying = false;
      notifyListeners();
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Mettre à jour le statut après paiement réussi
  Future<void> confirmPaymentSuccess({
    required String reservationId,
    required String txRef,
    required String transactionId,
    required double amount,
    required String currency,
  }) async {
    try {
      await _reservationService.updateReservationPaymentStatus(
        reservationId: reservationId,
        paymentStatus: 'paid',
        flutterwaveTxRef: txRef,
        flutterwaveTransactionId: transactionId,
        paymentReceiptUrl: 'https://dashboard.flutterwave.com/transactions/$transactionId',
      );
    } catch (e) {
      print('Erreur de confirmation du paiement: $e');
      rethrow;
    }
  }

  Future<void> clearPaymentData() async {
    _paymentLink = null;
    _txRef = null;
    _isProcessing = false;
    _isVerifying = false;
    notifyListeners();
  }
}