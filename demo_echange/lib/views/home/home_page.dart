import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth-provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/item_card.dart';
import '../item/add_item_page.dart';
import '../item/item_detail_page.dart';
import '../reservations/cart_page.dart';
import '../reservations/my_reservations_page.dart';
import '../reservations/owner_reservations_page.dart';
import '../review/user_reviews_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Charger les items au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ItemProvider>(context, listen: false).loadItems();

      // Load user cart and reservations if user is authenticated
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);

      if (authProvider.appUser != null) {
        reservationProvider.loadUserCart(
            authProvider.appUser!.id,
            authProvider.appUser!.name
        );
        reservationProvider.loadUserReservations(authProvider.appUser!.id);
        reservationProvider.loadOwnerReservations(authProvider.appUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final itemProvider = Provider.of<ItemProvider>(context);
    final reservationProvider = Provider.of<ReservationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('DEVMOB Echange'),
        backgroundColor: Colors.blue,
        actions: [
          // Cart icon with badge in AppBar
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {
                  setState(() {
                    _currentIndex = 2; // Navigate to cart tab
                  });
                },
              ),
              if (reservationProvider.cart != null && reservationProvider.cart!.items.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      reservationProvider.cart!.itemCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Reservations icon with badge
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: () {
                  setState(() {
                    _currentIndex = 3; // Navigate to reservations tab
                  });
                },
              ),
              if (_hasPendingReservations(reservationProvider))
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      _getPendingReservationsCount(reservationProvider).toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Implémenter la recherche plus tard
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                authProvider.signOut();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Text('Déconnexion'),
                ),
              ];
            },
          ),
        ],
      ),
      body: _buildCurrentTab(_currentIndex, authProvider, itemProvider),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddItemPage()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      )
          : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.blue, // Set background color
          selectedItemColor: Colors.white, // Selected item color
          unselectedItemColor: Colors.white70, // Unselected item color
          type: BottomNavigationBarType.fixed, // Important for more than 3 items
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(Icons.shopping_cart),
                  if (reservationProvider.cart != null && reservationProvider.cart!.items.isNotEmpty)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(minWidth: 12, minHeight: 12),
                        child: Text(
                          reservationProvider.cart!.itemCount.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Panier',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(Icons.calendar_today),
                  if (_hasPendingReservations(reservationProvider))
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(minWidth: 12, minHeight: 12),
                        child: Text(
                          _getPendingReservationsCount(reservationProvider).toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Réservations',
            ),
          ],
        )

    );
  }

  bool _hasPendingReservations(ReservationProvider reservationProvider) {
    final pendingUserReservations = reservationProvider.reservations
        .where((r) => r.status == 'pending').length;
    final pendingOwnerReservations = reservationProvider.receivedReservations
        .where((r) => r.status == 'pending').length;

    return pendingUserReservations > 0 || pendingOwnerReservations > 0;
  }

  int _getPendingReservationsCount(ReservationProvider reservationProvider) {
    final pendingUserReservations = reservationProvider.reservations
        .where((r) => r.status == 'pending').length;
    final pendingOwnerReservations = reservationProvider.receivedReservations
        .where((r) => r.status == 'pending').length;

    return pendingUserReservations + pendingOwnerReservations;
  }

  Widget _buildCurrentTab(int index, AuthProvider authProvider, ItemProvider itemProvider) {
    switch (index) {
      case 0:
        return _buildHomeTab(itemProvider);
      case 1:
        return _buildProfileTab(authProvider, itemProvider);
      case 2:
        return CartPage();
      case 3:
        return _buildReservationsTab(authProvider);
      default:
        return _buildHomeTab(itemProvider);
    }
  }

  Widget _buildReservationsTab(AuthProvider authProvider) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Mes Réservations'),
          backgroundColor: Colors.blue,
          bottom: TabBar(
            tabs: [
              Tab(text: 'Mes Demandes'),
              Tab(text: 'Demandes Reçues'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MyReservationsPage(),
            OwnerReservationsPage(),
          ],
        ),
      ),
    );
  }

  // ... rest of your existing _buildHomeTab, _buildProfileTab methods remain the same
  Widget _buildHomeTab(ItemProvider itemProvider) {
    if (itemProvider.isLoading && itemProvider.items.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    if (itemProvider.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Aucun objet disponible',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Soyez le premier à ajouter un objet !',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child:
      GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: itemProvider.items.length,
        itemBuilder: (context, index) {
          final item = itemProvider.items[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetailPage(item: item),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Container
                  Container(
                    height: 120,
                    width: double.infinity,
                    child: item.imageUrls.isNotEmpty
                        ? Image.network(
                      item.imageUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    )
                        : Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.photo,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),

                  // Item Details
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${item.dailyPrice}TND/jour',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 12, color: Colors.grey),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.location,
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      )
    );
  }


  Widget _buildProfileTab(AuthProvider authProvider, ItemProvider itemProvider) {
    final user = authProvider.appUser;

    if (user == null) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40,
                    child: Icon(Icons.person, size: 40),
                  ),
                  SizedBox(height: 16),
                  Text(
                    user.name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(user.email),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text('${user.totalReviews.toStringAsFixed(1) ?? "0.0"} (${user.totalReviews ?? 0} avis)'),
                    ],
                  ),

                  // Reviews Button
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider(
                              create: (_) => ReviewProvider(),
                              child: UserReviewsPage(),
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.reviews),
                      label: Text('Voir mes avis'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Reviews Stats Section
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mes Avis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),

                  // We'll use Consumer to get live review data
                  Consumer<ReviewProvider>(
                    builder: (context, reviewProvider, child) {
                      final totalReceived = reviewProvider.userReviews.length;
                      final totalGiven = reviewProvider.userGivenReviews.length;
                      //final averageRating = user.rating ?? 0.0;

                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Received Reviews
                              Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.download, size: 20, color: Colors.blue),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    totalReceived.toString(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Text(
                                    'Reçus',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),

                              // Given Reviews
                              Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.upload, size: 20, color: Colors.green),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    totalGiven.toString(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Donnés',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),

                              // Average Rating
                              Column(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.star, size: 20, color: Colors.amber),
                                  ),
                                  SizedBox(height: 4),

                                  Text(
                                    'Note',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          SizedBox(height: 12),

                          // Quick Review Stats
                          if (reviewProvider.userStats.isNotEmpty)
                            Column(
                              children: [
                                Divider(),
                                SizedBox(height: 8),
                                Text(
                                  'Distribution des notes:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                _buildRatingDistribution(reviewProvider.userStats['ratingDistribution']),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          Text(
            'Mes objets',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          _buildMyItemsList(itemProvider),

          SizedBox(height: 20),

          _buildReservationQuickStats(authProvider),
        ],
      ),
    );
  }



  Widget _buildRatingDistribution(List<dynamic> distribution) {
    final total = distribution.fold(0, (sum, count) => sum + (count as int));

    return Column(
      children: List.generate(5, (index) {
        final rating = 5 - index; // Show 5 stars to 1 star
        final count = distribution[rating - 1] as int;
        final percentage = total > 0 ? (count / total * 100) : 0;

        return Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Text(
                '$rating ⭐',
                style: TextStyle(fontSize: 12),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: LinearProgressIndicator(
                    value: total > 0 ? count / total : 0,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildReservationQuickStats(AuthProvider authProvider) {
    final reservationProvider = Provider.of<ReservationProvider>(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mes Réservations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'En attente',
                  _getPendingReservationsCount(reservationProvider).toString(),
                  Colors.orange,
                ),
                _buildStatItem(
                  'Acceptées',
                  reservationProvider.reservations
                      .where((r) => r.status == 'accepted').length.toString(),
                  Colors.green,
                ),
                _buildStatItem(
                  'Reçues',
                  reservationProvider.receivedReservations.length.toString(),
                  Colors.blue,
                ),
              ],
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 3; // Navigate to reservations tab
                });
              },
              child: Text('Voir toutes mes réservations'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 40),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMyItemsList(ItemProvider itemProvider) {
    if (itemProvider.myItems.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.inventory_2, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                'Vous n\'avez pas encore d\'objets',
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentIndex = 0;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddItemPage()),
                  );
                },
                child: Text('Ajouter mon premier objet'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: itemProvider.myItems.map((item) {
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: item.imageUrls.isNotEmpty
                ? Image.network(item.imageUrls.first, width: 50, height: 50, fit: BoxFit.cover)
                : Icon(Icons.image, size: 50),
            title: Text(item.title),
            subtitle: Text('${item.dailyPrice}€/jour'),
            trailing: Icon(
              item.isAvailable ? Icons.check_circle : Icons.cancel,
              color: item.isAvailable ? Colors.green : Colors.red,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailPage(item: item, isOwner: true),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }
}