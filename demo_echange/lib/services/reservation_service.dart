// services/reservation_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Reservation.dart';
import '../models/ReservationCart.dart';
import 'firebase-service.dart';
import 'stripe_service.dart';

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

  // Méthode pour initier le paiement après acceptation
  Future<Reservation> initiatePaymentAfterAcceptance({
    required String reservationId,
    required String customerEmail,
    required String customerName,
    required String customerPhone,
  }) async {
    try {
      final reservationDoc = await _firestore.collection('reservations').doc(reservationId).get();
      if (!reservationDoc.exists) {
        throw Exception('Réservation non trouvée');
      }

      final reservation = Reservation.fromMap(reservationDoc.data()!);

      // Vérifier que la réservation est acceptée
      if (reservation.status != 'accepted') {
        throw Exception('La réservation doit être acceptée avant le paiement');
      }

      // Vérifier que le paiement n'a pas déjà été fait
      if (reservation.isPaid || reservation.paymentStatus == 'paid') {
        throw Exception('Paiement déjà effectué');
      }

      // Générer un txRef unique
      final txRef = 'DEVMOB_${DateTime.now().millisecondsSinceEpoch}_${reservation.id}';

      // Mettre à jour la réservation avec txRef
      await updateReservationPaymentStatus(
        reservationId: reservationId,
        paymentStatus: 'pending',
        flutterwaveTxRef: txRef,
      );

      return reservation.copyWith(
        flutterwaveTxRef: txRef,
        paymentStatus: 'pending',
      );
    } catch (e) {
      print('Erreur d\'initiation du paiement: $e');
      rethrow;
    }
  }

  Future<void> updateReservationPaymentStatus({
    required String reservationId,
    required String paymentStatus,
    String? flutterwaveTxRef,
    String? flutterwaveTransactionId,
    String? flutterwaveCheckoutId,
    String? paymentReceiptUrl,
  }) async {
    try {
      final updateData = {
        'paymentStatus': paymentStatus,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (flutterwaveTxRef != null) {
        updateData['flutterwaveTxRef'] = flutterwaveTxRef;
      }

      if (flutterwaveTransactionId != null) {
        updateData['flutterwaveTransactionId'] = flutterwaveTransactionId;
      }

      if (flutterwaveCheckoutId != null) {
        updateData['flutterwaveCheckoutId'] = flutterwaveCheckoutId;
      }

      if (paymentReceiptUrl != null) {
        updateData['paymentReceiptUrl'] = paymentReceiptUrl;
      }

      await _firestore.collection('reservations').doc(reservationId).update(updateData);
    } catch (e) {
      print('Erreur de mise à jour du statut de paiement: $e');
      rethrow;
    }
  }


  // Méthode pour confirmer le paiement réussi
  Future<void> confirmPaymentSuccess({
    required String reservationId,
    required String flutterwaveTxRef,
    required String flutterwaveTransactionId,
    required String receiptUrl,
  }) async {
    try {
      // First update payment status
      await updateReservationPaymentStatus(
        reservationId: reservationId,
        paymentStatus: 'paid',
        flutterwaveTxRef: flutterwaveTxRef,
        flutterwaveTransactionId: flutterwaveTransactionId,
        paymentReceiptUrl: receiptUrl,
      );

      // Then check if we need to setup review system
      await _setupReviewSystemForReservation(reservationId);
    } catch (e) {
      print('Erreur de confirmation du paiement: $e');
      rethrow;
    }
  }


  Future<void> _setupReviewSystemForReservation(String reservationId) async {
    try {
      final reservationDoc = await _firestore.collection('reservations').doc(reservationId).get();
      if (!reservationDoc.exists) return;

      final reservation = Reservation.fromMap(reservationDoc.data()!);

      // Only setup reviews if reservation is accepted AND paid
      if (reservation.status == 'accepted' && reservation.paymentStatus == 'paid') {
        // Set review deadline to 14 days from end date (or from now if end date has passed)
        DateTime reviewDeadline;
        if (DateTime.now().isAfter(reservation.endDate)) {
          // End date already passed, start review period from now
          reviewDeadline = DateTime.now().add(Duration(days: 14));
        } else {
          // End date hasn't passed yet, start review period from end date
          reviewDeadline = reservation.endDate.add(Duration(days: 14));
        }

        await _firestore.collection('reservations').doc(reservationId).update({
          'canReviewOwner': true,
          'canReviewRenter': true,
          'reviewDeadline': reviewDeadline.millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      print('Error setting up review system: $e');
    }
  }



  // review feature
  Future<void> markReservationAsCompleted(String reservationId) async {
    try {
      final reservationDoc = await _firestore.collection('reservations').doc(reservationId).get();
      if (!reservationDoc.exists) return;

      final reservation = Reservation.fromMap(reservationDoc.data()!);

      // Only mark if accepted and paid
      if (reservation.status == 'accepted' && reservation.paymentStatus == 'paid') {
        // Set review deadline to 14 days from now (or from end date if not passed)
        DateTime reviewDeadline;
        if (DateTime.now().isAfter(reservation.endDate)) {
          reviewDeadline = DateTime.now().add(Duration(days: 14));
        } else {
          reviewDeadline = reservation.endDate.add(Duration(days: 14));
        }

        await _firestore.collection('reservations').doc(reservationId).update({
          'canReviewOwner': true,
          'canReviewRenter': true,
          'reviewDeadline': reviewDeadline.millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      print('Error marking reservation as completed: $e');
      rethrow;
    }
  }


  Future<void> updateReservationStatus(String reservationId, String status) async {
    try {
      final updateData = {
        'status': status,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // If status is completed, add review fields
      if (status == 'completed') {
        final reviewDeadline = DateTime.now().add(Duration(days: 14));
        updateData['canReviewOwner'] = true;
        updateData['canReviewRenter'] = true;
        updateData['reviewDeadline'] = reviewDeadline.millisecondsSinceEpoch;
      }

      await _firestore.collection('reservations').doc(reservationId).update(updateData);
    } catch (e) {
      print('Error updating reservation: $e');
      rethrow;
    }
  }
}