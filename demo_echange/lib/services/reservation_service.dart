// services/reservation_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo_echange/services/stripe_service.dart';
import '../models/Reservation.dart';
import '../models/ReservationCart.dart';
import 'firebase-service.dart';

class ReservationService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  Future<String> createReservation(Reservation reservation) async {
    try {
      final docRef = _firestore.collection('reservations').doc();
      final newReservation = reservation.copyWith(id: docRef.id);
      await docRef.set(newReservation.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating reservation: $e');
      rethrow;
    }
  }

  // Cart methods
  Future<ReservationCart> getOrCreateCart(String renterId, String renterName) async {
    try {
      final docRef = _firestore.collection('reservationCarts').doc(renterId);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        return ReservationCart.fromMap(docSnapshot.data()!);
      } else {
        final newCart = ReservationCart(
          id: renterId,
          renterId: renterId,
          renterName: renterName,
          items: [],
          createdAt: DateTime.now(),
        );
        await docRef.set(newCart.toMap());
        return newCart;
      }
    } catch (e) {
      print('Error getting cart: $e');
      rethrow;
    }
  }

  Future<void> addToCart(ReservationCartItem item, String renterId, String renterName) async {
    try {
      final cart = await getOrCreateCart(renterId, renterName);

      // Check if item already exists in cart
      final existingItemIndex = cart.items.indexWhere((cartItem) => cartItem.itemId == item.itemId);

      final updatedItems = List<ReservationCartItem>.from(cart.items);

      if (existingItemIndex != -1) {
        // Update existing item
        updatedItems[existingItemIndex] = item;
      } else {
        updatedItems.add(item);
      }

      final updatedCart = cart.copyWith(
        items: updatedItems,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('reservationCarts').doc(renterId).set(updatedCart.toMap());
    } catch (e) {
      print('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String itemId, String renterId) async {
    try {
      final cartDoc = _firestore.collection('reservationCarts').doc(renterId);
      final cartSnapshot = await cartDoc.get();

      if (cartSnapshot.exists) {
        final cart = ReservationCart.fromMap(cartSnapshot.data()!);
        final updatedItems = cart.items.where((item) => item.itemId != itemId).toList();

        final updatedCart = cart.copyWith(
          items: updatedItems,
          updatedAt: DateTime.now(),
        );

        await cartDoc.set(updatedCart.toMap());
      }
    } catch (e) {
      print('Error removing from cart: $e');
      rethrow;
    }
  }

  Future<void> clearCart(String renterId) async {
    try {
      await _firestore.collection('reservationCarts').doc(renterId).delete();
    } catch (e) {
      print('Error clearing cart: $e');
      rethrow;
    }
  }


  Stream<ReservationCart?> getCartStream(String renterId) {
    return _firestore
        .collection('reservationCarts')
        .doc(renterId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return ReservationCart.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  // Existing methods...
  Stream<List<Reservation>> getReservationsByOwner(String ownerId) {
    return _firestore
        .collection('reservations')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Reservation.fromMap(doc.data()))
        .toList());
  }

  Stream<List<Reservation>> getReservationsByRenter(String renterId) {
    return _firestore
        .collection('reservations')
        .where('renterId', isEqualTo: renterId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Reservation.fromMap(doc.data()))
        .toList());
  }

  Future<void> updateReservationStatus(String reservationId, String status) async {
    try {
      await _firestore.collection('reservations').doc(reservationId).update({
        'status': status,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error updating reservation: $e');
      rethrow;
    }
  }

  Future<bool> isItemAvailable(String itemId, DateTime startDate, DateTime endDate) async {
    try {
      final reservations = await _firestore
          .collection('reservations')
          .where('itemId', isEqualTo: itemId)
          .where('status', whereIn: ['pending', 'accepted'])
          .get();

      for (final doc in reservations.docs) {
        final reservation = Reservation.fromMap(doc.data());
        if (startDate.isBefore(reservation.endDate) && endDate.isAfter(reservation.startDate)) {
          return false;
        }
      }
      return true;
    } catch (e) {
      print('Error checking availability: $e');
      return false;
    }
  }




  // payment
  Future<Reservation> createReservationWithPayment({
    required Reservation reservation,
    required String customerEmail,
    required String customerName,
  }) async {
    try {


      // Si paiement requis, créer le PaymentIntent
      final paymentIntent = await StripeService.createPaymentIntent(
        amount: reservation.totalPrice,
        currency: 'eur',
        customerEmail: customerEmail,
        itemName: reservation.itemTitle,
        reservationId: reservation.id,
      );

      // Créer la réservation avec PaymentIntent ID
      final docRef = _firestore.collection('reservations').doc();
      final newReservation = reservation.copyWith(
        id: docRef.id,
        stripePaymentIntentId: paymentIntent['id'],
        paymentStatus: 'pending',
      );

      await docRef.set(newReservation.toMap());
      return newReservation;
    } catch (e) {
      print('Error creating reservation with payment: $e');
      rethrow;
    }
  }

  Future<void> updateReservationPaymentStatus({
    required String reservationId,
    required String paymentStatus,
    String? stripePaymentIntentId,
    String? paymentReceiptUrl,
  }) async {
    try {
      final updateData = {
        'paymentStatus': paymentStatus,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (stripePaymentIntentId != null) {
        updateData['stripePaymentIntentId'] = stripePaymentIntentId;
      }

      if (paymentReceiptUrl != null) {
        updateData['paymentReceiptUrl'] = paymentReceiptUrl;
      }

      await _firestore.collection('reservations').doc(reservationId).update(updateData);
    } catch (e) {
      print('Error updating payment status: $e');
      rethrow;
    }
  }

  // Modifiez confirmCart pour ne pas créer de paiement immédiatement
  Future<List<Reservation>> confirmCart(String renterId, String renterEmail, String renterName) async {
    try {
      final cart = await getOrCreateCart(renterId, renterName);
      final List<Reservation> reservations = [];

      for (final item in cart.items) {
        // Check availability
        final isAvailable = await isItemAvailable(item.itemId, item.startDate, item.endDate);

        if (!isAvailable) {
          throw Exception('${item.itemTitle} n\'est plus disponible pour les dates sélectionnées');
        }

        // Create reservation (sans paiement pour l'instant)
        final reservation = Reservation(
          id: '',
          itemId: item.itemId,
          itemTitle: item.itemTitle,
          ownerId: item.ownerId,
          renterId: renterId,
          renterName: renterName,
          startDate: item.startDate,
          endDate: item.endDate,
          totalPrice: item.totalPrice,
          message: item.message,
          status: 'pending', // Attente d'acceptation du propriétaire
          createdAt: DateTime.now(),
          paymentRequired: item.totalPrice > 0, // Si prix > 0, paiement requis
          isFree: item.totalPrice == 0, // Si prix = 0, c'est gratuit
          paymentStatus: 'pending',
        );

        final reservationId = await createReservation(reservation);
        reservations.add(reservation.copyWith(id: reservationId));
      }

      // Clear cart
      await clearCart(renterId);
      return reservations;
    } catch (e) {
      print('Error confirming cart: $e');
      rethrow;
    }
  }

  // Méthode pour initier le paiement après acceptation
  Future<Reservation> initiatePaymentAfterAcceptance({
    required String reservationId,
    required String customerEmail,
    required String customerName,
  }) async {
    try {
      final reservationDoc = await _firestore.collection('reservations').doc(reservationId).get();
      if (!reservationDoc.exists) {
        throw Exception('Reservation not found');
      }

      final reservation = Reservation.fromMap(reservationDoc.data()!);

      // Vérifier que la réservation est acceptée
      if (reservation.status != 'accepted') {
        throw Exception('Reservation must be accepted before payment');
      }

      // Vérifier que le paiement n'a pas déjà été fait
      if (reservation.isPaid || reservation.paymentStatus == 'paid') {
        throw Exception('Payment already completed');
      }

      // Si c'est gratuit
      if (reservation.isFree || !reservation.paymentRequired) {
        await updateReservationPaymentStatus(
          reservationId: reservationId,
          paymentStatus: 'not_required',
        );
        return reservation.copyWith(paymentStatus: 'not_required');
      }

      // Créer PaymentIntent pour une réservation existante
      final paymentIntent = await StripeService.createPaymentIntent(
        amount: reservation.totalPrice,
        currency: 'eur',
        customerEmail: customerEmail,
        itemName: reservation.itemTitle,
        reservationId: reservationId,
      );

      // Mettre à jour la réservation avec PaymentIntent ID
      await updateReservationPaymentStatus(
        reservationId: reservationId,
        paymentStatus: 'pending',
        stripePaymentIntentId: paymentIntent['id'],
      );

      return reservation.copyWith(
        stripePaymentIntentId: paymentIntent['id'],
        paymentStatus: 'pending',
      );
    } catch (e) {
      print('Error initiating payment: $e');
      rethrow;
    }
  }
}