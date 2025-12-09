// providers/review_provider.dart
import 'package:flutter/foundation.dart';
import '../models/Review.dart';
import '../services/review_service.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewService _reviewService = ReviewService();
  List<Review> _userReviews = []; // Reviews of the current user
  List<Review> _userGivenReviews = []; // Reviews given by current user
  Map<String, dynamic> _userStats = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<Review> get userReviews => _userReviews;
  List<Review> get userGivenReviews => _userGivenReviews;
  Map<String, dynamic> get userStats => _userStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load reviews for a user
  void loadUserReviews(String userId) {
    _reviewService.getReviewsForUser(userId).listen((reviews) {
      _userReviews = reviews;
      _loadUserStats(userId);
      notifyListeners();
    });
  }

  // Load reviews given by a user
  void loadUserGivenReviews(String userId) {
    _reviewService.getReviewsByUser(userId).listen((reviews) {
      _userGivenReviews = reviews;
      notifyListeners();
    });
  }

  // Load user statistics
  Future<void> _loadUserStats(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userStats = await _reviewService.getUserReviewStats(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load review statistics';
      print('Error loading stats: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Create a new review
  Future<bool> createReview(Review review) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reviewService.createReview(review);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to submit review';
      notifyListeners();
      return false;
    }
  }

  // Add response to a review
  Future<bool> addResponseToReview({
    required String reviewId,
    required String response,
    required String respondedBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reviewService.addResponseToReview(
        reviewId: reviewId,
        response: response,
        respondedBy: respondedBy,
      );

      // Refresh user reviews
      final review = _userReviews.firstWhere((r) => r.id == reviewId);
      loadUserReviews(review.reviewedUserId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to add response';
      notifyListeners();
      return false;
    }
  }

  // Delete a review
  Future<bool> deleteReview(String reviewId, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reviewService.deleteReview(reviewId, userId);

      // Refresh lists
      _userReviews.removeWhere((r) => r.id == reviewId);
      _userGivenReviews.removeWhere((r) => r.id == reviewId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to delete review';
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}