// services/reservation_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<List<Reservation>> confirmCart(String renterId) async {
    try {
      final cart = await getOrCreateCart(renterId, '');
      final List<Reservation> reservations = [];

      for (final item in cart.items) {
        // Check availability for each item
        final isAvailable = await isItemAvailable(item.itemId, item.startDate, item.endDate);

        if (!isAvailable) {
          throw Exception('${item.itemTitle} n\'est plus disponible pour les dates sélectionnées');
        }

        // Create reservation
        final reservation = Reservation(
          id: '',
          itemId: item.itemId,
          itemTitle: item.itemTitle,
          ownerId: item.ownerId,
          renterId: renterId,
          renterName: cart.renterName,
          startDate: item.startDate,
          endDate: item.endDate,
          totalPrice: item.totalPrice,
          message: item.message,
          status: 'pending',
          createdAt: DateTime.now(),
        );

        final reservationId = await createReservation(reservation);
        reservations.add(reservation.copyWith(id: reservationId));
      }

      // Clear cart after successful reservation
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
}