// services/review_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/Review.dart';
import '../models/Reservation.dart';
import '../models/User.dart';
import 'firebase-service.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Create a new review
  Future<String> createReview(Review review) async {
    try {
      final docRef = _firestore.collection('reviews').doc();
      final newReview = review.copyWith(id: docRef.id);
      await docRef.set(newReview.toMap());

      // Update user's average rating
      await _updateUserRating(review.reviewedUserId);

      // Update reservation review status
      await _updateReservationReviewStatus(
        review.reservationId,
        review.isOwnerReview,
      );

      return docRef.id;
    } catch (e) {
      print('Error creating review: $e');
      rethrow;
    }
  }

  // Update user's average rating
  Future<void> _updateUserRating(String userId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('reviewedUserId', isEqualTo: userId)
          .get();

      if (reviewsSnapshot.docs.isNotEmpty) {
        double totalRating = 0;
        for (final doc in reviewsSnapshot.docs) {
          totalRating += doc.data()['rating'] as double;
        }

        final averageRating = totalRating / reviewsSnapshot.docs.length;

        await _firestore.collection('users').doc(userId).update({
          'averageRating': averageRating,
          'totalReviews': reviewsSnapshot.docs.length,
        });
      }
    } catch (e) {
      print('Error updating user rating: $e');
      rethrow;
    }
  }

  // Update reservation review status
  Future<void> _updateReservationReviewStatus(
      String reservationId,
      bool isOwnerReview,
      ) async {
    try {
      final updateData = isOwnerReview
          ? {'renterReviewed': true}
          : {'ownerReviewed': true};

      await _firestore.collection('reservations').doc(reservationId).update(updateData);
    } catch (e) {
      print('Error updating reservation review status: $e');
      rethrow;
    }
  }

  // Get reviews for a user
  Stream<List<Review>> getReviewsForUser(String userId) {
    return _firestore
        .collection('reviews')
        .where('reviewedUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Review.fromMap(doc.data()))
        .toList());
  }

  // Get reviews by a user
  Stream<List<Review>> getReviewsByUser(String userId) {
    return _firestore
        .collection('reviews')
        .where('reviewerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Review.fromMap(doc.data()))
        .toList());
  }

  // Check if user has reviewed a reservation
  Future<bool> hasUserReviewedReservation({
    required String reservationId,
    required String userId,
    required bool isOwnerReview,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('reviews')
          .where('reservationId', isEqualTo: reservationId)
          .where('reviewerId', isEqualTo: userId)
          .where('isOwnerReview', isEqualTo: isOwnerReview)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking review: $e');
      return false;
    }
  }

  // Add response to a review
  Future<void> addResponseToReview({
    required String reviewId,
    required String response,
    required String respondedBy,
  }) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'response': response,
        'respondedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      print('Error adding response: $e');
      rethrow;
    }
  }

  // Get reviews for a reservation
  Future<List<Review>> getReservationReviews(String reservationId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('reservationId', isEqualTo: reservationId)
          .get();

      return snapshot.docs
          .map((doc) => Review.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting reservation reviews: $e');
      rethrow;
    }
  }

  // Calculate user statistics
  Future<Map<String, dynamic>> getUserReviewStats(String userId) async {
    try {
      final reviewsSnapshot = await _firestore
          .collection('reviews')
          .where('reviewedUserId', isEqualTo: userId)
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        return {
          'averageRating': 0.0,
          'totalReviews': 0,
          'ratingDistribution': [0, 0, 0, 0, 0],
        };
      }

      double totalRating = 0;
      List<int> distribution = [0, 0, 0, 0, 0]; // For ratings 1-5

      for (final doc in reviewsSnapshot.docs) {
        final rating = doc.data()['rating'] as double;
        totalRating += rating;
        distribution[rating.toInt() - 1]++;
      }

      return {
        'averageRating': totalRating / reviewsSnapshot.docs.length,
        'totalReviews': reviewsSnapshot.docs.length,
        'ratingDistribution': distribution,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      return {
        'averageRating': 0.0,
        'totalReviews': 0,
        'ratingDistribution': [0, 0, 0, 0, 0],
      };
    }
  }

  // Delete a review (admin or owner only)
  Future<void> deleteReview(String reviewId, String userId) async {
    try {
      final reviewDoc = await _firestore.collection('reviews').doc(reviewId).get();
      if (reviewDoc.exists) {
        final review = Review.fromMap(reviewDoc.data()!);

        // Check if user is the reviewer or admin
        if (review.reviewerId == userId) {
          await _firestore.collection('reviews').doc(reviewId).delete();

          // Update user's rating
          await _updateUserRating(review.reviewedUserId);
        } else {
          throw Exception('You are not authorized to delete this review');
        }
      }
    } catch (e) {
      print('Error deleting review: $e');
      rethrow;
    }
  }
}