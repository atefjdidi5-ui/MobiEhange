// providers/reservation_provider.dart
import 'package:flutter/foundation.dart';
import '../models/Reservation.dart';
import '../models/ReservationCart.dart';
import '../services/reservation_service.dart';

class ReservationProvider with ChangeNotifier {
  final ReservationService _reservationService = ReservationService();
  List<Reservation> _reservations = [];
  List<Reservation> _receivedReservations = [];
  ReservationCart? _cart;
  bool _isLoading = false;
  bool _isCartLoading = false;

  List<Reservation> get reservations => _reservations;
  List<Reservation> get receivedReservations => _receivedReservations;
  ReservationCart? get cart => _cart;
  bool get isLoading => _isLoading;
  bool get isCartLoading => _isCartLoading;

  // Load user cart
  void loadUserCart(String renterId, String renterName) {
    _reservationService.getCartStream(renterId).listen((cart) {
      _cart = cart;
      notifyListeners();
    });
  }

  // Add to cart
  Future<bool> addToCart(ReservationCartItem item, String renterId, String renterName) async {
    _isCartLoading = true;
    notifyListeners();

    try {
      // Check availability before adding to cart
      final isAvailable = await _reservationService.isItemAvailable(
        item.itemId,
        item.startDate,
        item.endDate,
      );

      if (!isAvailable) {
        _isCartLoading = false;
        notifyListeners();
        return false;
      }

      await _reservationService.addToCart(item, renterId, renterName);
      _isCartLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isCartLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Remove from cart
  Future<void> removeFromCart(String itemId, String renterId) async {
    await _reservationService.removeFromCart(itemId, renterId);
  }

  // Confirm cart (create all reservations)
  Future<bool> confirmCart(String renterId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _reservationService.confirmCart(renterId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear cart
  Future<void> clearCart(String renterId) async {
    await _reservationService.clearCart(renterId);
  }

  // Existing methods...
  void loadUserReservations(String userId) {
    _reservationService.getReservationsByRenter(userId).listen((reservations) {
      _reservations = reservations;
      notifyListeners();
    });
  }

  void loadOwnerReservations(String ownerId) {
    _reservationService.getReservationsByOwner(ownerId).listen((reservations) {
      _receivedReservations = reservations;
      notifyListeners();
    });
  }

  Future<bool> createReservation(Reservation reservation) async {
    _isLoading = true;
    notifyListeners();

    try {
      final isAvailable = await _reservationService.isItemAvailable(
        reservation.itemId,
        reservation.startDate,
        reservation.endDate,
      );

      if (!isAvailable) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await _reservationService.createReservation(reservation);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReservationStatus(String reservationId, String status) async {
    try {
      await _reservationService.updateReservationStatus(reservationId, status);
      return true;
    } catch (e) {
      return false;
    }
  }
}