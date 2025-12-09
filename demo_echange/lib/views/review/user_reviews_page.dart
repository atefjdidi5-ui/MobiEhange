// pages/review/user_reviews_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/Review.dart';
import '../../providers/auth-provider.dart';
import '../../providers/review_provider.dart';

class UserReviewsPage extends StatefulWidget {
  final String? userId; // If null, shows current user's reviews

  UserReviewsPage({this.userId});

  @override
  _UserReviewsPageState createState() => _UserReviewsPageState();
}

class _UserReviewsPageState extends State<UserReviewsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);

      final targetUserId = widget.userId ?? authProvider.appUser?.id;
      if (targetUserId != null) {
        reviewProvider.loadUserReviews(targetUserId);
        reviewProvider.loadUserGivenReviews(targetUserId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final currentUser = authProvider.appUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Reviews')),
        body: Center(child: Text('Please sign in to view reviews')),
      );
    }

    final targetUserId = widget.userId ?? currentUser.id;
    final isOwnProfile = targetUserId == currentUser.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? 'My Reviews' : 'Reviews'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Received (${reviewProvider.userReviews.length})'),
            Tab(text: 'Given (${reviewProvider.userGivenReviews.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReceivedReviewsTab(reviewProvider, isOwnProfile),
          _buildGivenReviewsTab(reviewProvider, isOwnProfile),
        ],
      ),
    );
  }

  Widget _buildReceivedReviewsTab(ReviewProvider reviewProvider, bool isOwnProfile) {
    if (reviewProvider.isLoading && reviewProvider.userReviews.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    if (reviewProvider.userReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.reviews, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Reviews will appear here once you receive them',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: reviewProvider.userReviews.length,
      itemBuilder: (context, index) {
        final review = reviewProvider.userReviews[index];
        return _buildReviewCard(review, isOwnProfile);
      },
    );
  }

  Widget _buildGivenReviewsTab(ReviewProvider reviewProvider, bool isOwnProfile) {
    if (reviewProvider.isLoading && reviewProvider.userGivenReviews.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    if (reviewProvider.userGivenReviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No reviews given yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'You haven\'t reviewed anyone yet',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: reviewProvider.userGivenReviews.length,
      itemBuilder: (context, index) {
        final review = reviewProvider.userGivenReviews[index];
        return _buildReviewCard(review, isOwnProfile);
      },
    );
  }

  Widget _buildReviewCard(Review review, bool isOwnProfile) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  child: Text(review.reviewerName[0]),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.reviewerName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        review.isOwnerReview ? 'Reviewed Renter' : 'Reviewed Owner',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRatingStars(review.rating),
              ],
            ),

            SizedBox(height: 12),

            // Item info
            Text(
              review.itemTitle,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue[700],
              ),
            ),

            SizedBox(height: 12),

            // Comment
            Text(
              review.comment,
              style: TextStyle(fontSize: 14),
            ),

            SizedBox(height: 12),

            // Date
            Text(
              DateFormat('MMM dd, yyyy').format(review.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            // Response section (if any)
            if (review.hasResponse) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Response from ${review.isOwnerReview ? 'Renter' : 'Owner'}:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(review.response!),
                    if (review.respondedAt != null)
                      Text(
                        DateFormat('MMM dd, yyyy').format(review.respondedAt!),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // Actions (for own reviews)
            if (isOwnProfile && !review.hasResponse) ...[
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showResponseDialog(review),
                  child: Text('Respond'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.amber,
        );
      }),
    );
  }

  void _showResponseDialog(Review review) {
    final responseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Response'),
          content: TextFormField(
            controller: responseController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Write your response here...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (responseController.text.trim().isNotEmpty) {
                  final reviewProvider = Provider.of<ReviewProvider>(
                    context,
                    listen: false,
                  );
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );

                  await reviewProvider.addResponseToReview(
                    reviewId: review.id,
                    response: responseController.text.trim(),
                    respondedBy: authProvider.appUser!.id,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}