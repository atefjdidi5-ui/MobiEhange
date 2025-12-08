// providers/stripe_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../services/stripe_service.dart';
import '../services/reservation_service.dart';
import '../models/Reservation.dart';

class StripeProvider with ChangeNotifier {
  final ReservationService _reservationService = ReservationService();

  bool _isProcessing = false;
  bool _isInitialized = false;
  String? _clientSecret;

  bool get isProcessing => _isProcessing;
  bool get isInitialized => _isInitialized;

  Future<void> initializeStripe() async {
    if (_isInitialized) return;

    try {
      // Configurer Stripe
      Stripe.publishableKey = StripeService.publishableKey;
      Stripe.merchantIdentifier = 'merchant.flutter.stripe';

      await Stripe.instance.applySettings();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing Stripe: $e');
      rethrow;
    }
  }

  // Initialiser le paiement pour une réservation acceptée
  Future<Map<String, dynamic>> initiatePaymentForReservation({
    required String reservationId,
    required String customerEmail,
    required String customerName,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      await initializeStripe();

      // Obtenir et préparer la réservation pour le paiement
      final reservation = await _reservationService.initiatePaymentAfterAcceptance(
        reservationId: reservationId,
        customerEmail: customerEmail,
        customerName: customerName,
      );

      // Récupérer le PaymentIntent depuis Stripe
      if (reservation.stripePaymentIntentId != null) {
        final paymentIntent = await StripeService.retrievePaymentIntent(
          reservation.stripePaymentIntentId!,
        );

        _clientSecret = paymentIntent['client_secret'];

        _isProcessing = false;
        notifyListeners();

        return {
          'success': true,
          'reservation': reservation,
          'clientSecret': _clientSecret,
          'amount': reservation.totalPrice,
          'currency': 'eur',
        };
      } else {
        throw Exception('No payment intent found');
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

  // Traiter le paiement
  Future<Map<String, dynamic>> processPayment({
    required String clientSecret,
    required String customerEmail,
    required String customerName,
  }) async {
    _isProcessing = true;
    notifyListeners();

    try {
      // Récupérer l'ID du PaymentIntent depuis le clientSecret
      final parts = clientSecret.split('_secret_');
      if (parts.length != 2) {
        throw Exception('Invalid client secret');
      }
      final paymentIntentId = '${parts[0]}_secret';

      // Créer la méthode de paiement
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              email: customerEmail,
              name: customerName,
              // Les autres champs sont optionnels
            ),
          ),
        ),
      );

      // Confirmer le paiement
      final paymentResult = await Stripe.instance.confirmPaymentIntent(
        params: PaymentIntentConfirmParams(
          clientSecret: clientSecret,
          paymentMethodId: paymentMethod.id,
        ),
      );

      if (paymentResult.status == PaymentIntentsStatus.Succeeded) {
        // Mettre à jour le statut de paiement dans Firestore
        await _updatePaymentStatusAfterSuccess(paymentIntentId);

        _isProcessing = false;
        notifyListeners();

        return {
          'success': true,
          'paymentIntentId': paymentIntentId,
          'receiptUrl': paymentResult.receiptUrl,
          'message': 'Paiement réussi!',
        };
      } else {
        _isProcessing = false;
        notifyListeners();
        return {
          'success': false,
          'error': 'Le paiement a échoué. Statut: ${paymentResult.status}',
        };
      }
    } catch (e) {
      _isProcessing = false;
      notifyListeners();
      return {
        'success': false,
        'error': 'Erreur lors du traitement: $e',
      };
    }
  }

  Future<void> _updatePaymentStatusAfterSuccess(String paymentIntentId) async {
    try {
      // Trouver la réservation avec ce PaymentIntent ID
      final query = await FirebaseService.firestore
          .collection('reservations')
          .where('stripePaymentIntentId', isEqualTo: paymentIntentId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final reservationId = query.docs.first.id;
        await _reservationService.updateReservationPaymentStatus(
          reservationId: reservationId,
          paymentStatus: 'paid',
          paymentReceiptUrl: 'https://receipt.stripe.com/receipts/test', // À remplacer par l'URL réelle
        );
      }
    } catch (e) {
      print('Error updating payment status: $e');
    }
  }

  Future<void> clearPaymentData() async {
    _clientSecret = null;
    _isProcessing = false;
    notifyListeners();
  }
}