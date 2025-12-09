// pages/review/leave_review_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../models/Reservation.dart';
import '../../models/Review.dart';
import '../../providers/auth-provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/reservation_provider.dart';

class LeaveReviewPage extends StatefulWidget {
  final Reservation reservation;
  final bool isReviewingOwner; // true: renter reviewing owner, false: owner reviewing renter

  LeaveReviewPage({
    required this.reservation,
    required this.isReviewingOwner,
  });

  @override
  _LeaveReviewPageState createState() => _LeaveReviewPageState();
}

class _LeaveReviewPageState extends State<LeaveReviewPage> {
  final _formKey = GlobalKey<FormState>();
  double _rating = 5.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.appUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Leave Review')),
        body: Center(child: Text('Please sign in to leave a review')),
      );
    }

    final String reviewedUserId = widget.isReviewingOwner
        ? widget.reservation.ownerId
        : widget.reservation.renterId;

    final String reviewedUserName = widget.isReviewingOwner
        ? 'Owner'
        : widget.reservation.renterName;

    final String itemTitle = widget.reservation.itemTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text('Leave a Review'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review for $reviewedUserName',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Item: $itemTitle',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        'Reservation: ${widget.reservation.startDate.day}/${widget.reservation.startDate.month}/${widget.reservation.startDate.year} - ${widget.reservation.endDate.day}/${widget.reservation.endDate.month}/${widget.reservation.endDate.year}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Rating Section
              Text(
                'Your Rating',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // Star Rating
              Center(
                child: Column(
                  children: [
                    Text(
                      _rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    SizedBox(height: 16),
                    StarRating(
                      rating: _rating,
                      onRatingChanged: (rating) {
                        setState(() {
                          _rating = rating;
                        });
                      },
                    ),
                    SizedBox(height: 8),
                    Text(
                      _getRatingText(_rating),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Comment Section
              Text(
                'Your Review',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _commentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Tell us about your experience...',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please write a review';
                  }
                  if (value.trim().length < 10) {
                    return 'Review must be at least 10 characters long';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              Text(
                'Tip: Be specific about what you liked or disliked',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  child: _isSubmitting
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                    'Submit Review',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Guidelines
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Guidelines',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Be honest and fair\n'
                            '• Focus on the experience\n'
                            '• Avoid personal attacks\n'
                            '• Reviews are public\n'
                            '• You cannot edit after submitting',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.0) return 'Good';
    if (rating >= 2.0) return 'Fair';
    return 'Poor';
  }

  void _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    final currentUser = authProvider.appUser!;

    final review = Review(
      id: '',
      reservationId: widget.reservation.id,
      itemId: widget.reservation.itemId,
      itemTitle: widget.reservation.itemTitle,
      reviewerId: currentUser.id,
      reviewerName: currentUser.name,
      reviewedUserId: widget.isReviewingOwner
          ? widget.reservation.ownerId
          : widget.reservation.renterId,
      reviewedUserName: widget.isReviewingOwner
          ? 'Owner'
          : widget.reservation.renterName,
      rating: _rating,
      comment: _commentController.text.trim(),
      createdAt: DateTime.now(),
      isOwnerReview: !widget.isReviewingOwner, // Owner reviewing renter = true
    );

    final success = await reviewProvider.createReview(review);

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back after a delay
      Future.delayed(Duration(milliseconds: 1500), () {
        Navigator.pop(context, true);
      });
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

// Star Rating Widget
class StarRating extends StatelessWidget {
  final double rating;
  final Function(double) onRatingChanged;
  final double starSize;
  final Color color;

  StarRating({
    required this.rating,
    required this.onRatingChanged,
    this.starSize = 40,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            onRatingChanged(index + 1.0);
          },
          child: Icon(
            index < rating.floor() ? Icons.star : Icons.star_border,
            size: starSize,
            color: color,
          ),
        );
      }),
    );
  }
}