import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/Item.dart';
import '../../models/ReservationCart.dart';
import '../../providers/auth-provider.dart';
import '../../providers/reservation_provider.dart';
import '../../widgets/availability_calendar.dart';
import '../reservations/reservation_form_page.dart';
import 'edit_item_page.dart';

class ItemDetailPage extends StatelessWidget {
  final Item item;
  final bool isOwner;

  const ItemDetailPage({
    Key? key,
    required this.item,
    this.isOwner = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final reservationProvider = Provider.of<ReservationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de l\'objet'),
        actions: [
          if (isOwner)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditItemPage(item: item),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Item Image Placeholder - Fixed height
          Container(
            height: 250,
            width: double.infinity,
            child: item.imageUrls.isNotEmpty
                ? PageView.builder(
              itemCount: item.imageUrls.length,
              itemBuilder: (context, index) {
                return Image.network(
                  item.imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                );
              },
            )
                : Container(
              color: Colors.grey[300],
              child: Icon(
                Icons.photo,
                size: 80,
                color: Colors.grey[600],
              ),
            ),
          ),

// Add image indicators if there are multiple images
          if (item.imageUrls.length > 1)
            Container(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(item.imageUrls.length, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  );
                }),
              ),
            ),

          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${item.dailyPrice}TND/jour',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Category and Availability
                  Row(
                    children: [
                      Icon(Icons.category, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        item.category,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),

                  // Availability Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.isAvailable ? Colors.green[50] : Colors.red[50],
                      border: Border.all(
                        color: item.isAvailable ? Colors.green : Colors.red,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isAvailable ? Icons.check_circle : Icons.remove_circle,
                          size: 16,
                          color: item.isAvailable ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 4),
                        Text(
                          item.isAvailable ? 'Disponible' : 'Non disponible',
                          style: TextStyle(
                            color: item.isAvailable ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Description Section
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),
                  SizedBox(height: 20),

                  // Owner Information
                  Text(
                    'Informations du propriétaire',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        item.ownerId.substring(0, 2).toUpperCase(),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text('Propriétaire'),
                    subtitle: Text('Membre depuis ${_formatDate(item.createdAt)}'),
                  ),
                  SizedBox(height: 20),

                  // Rating Information
                  if (item.totalReviews > 0) ...[
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber),
                        SizedBox(width: 4),
                        Text(
                          item.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '(${item.totalReviews} avis)',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                  ],



                  SizedBox(height: 20),
                  AvailabilityCalendar(itemId: item.id),
                  // Action Buttons
                  if (!isOwner) ...[
                    if (item.isAvailable) ...[
                      // Reserve Now Button
                      ElevatedButton(
                        onPressed: () => _reserveNow(context),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: Text(
                          'Réserver maintenant',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),

                      // Add to Cart Button
                      Consumer<ReservationProvider>(
                        builder: (context, reservationProvider, child) {
                          final isInCart = reservationProvider.cart?.items
                              .any((cartItem) => cartItem.itemId == item.id) ?? false;

                          return OutlinedButton(
                            onPressed: reservationProvider.isCartLoading
                                ? null
                                : () => _addToCart(context, reservationProvider, authProvider),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: isInCart ? Colors.green : Theme.of(context).primaryColor,
                              ),
                              minimumSize: Size(double.infinity, 50),
                            ),
                            child: reservationProvider.isCartLoading
                                ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isInCart ? Icons.check : Icons.add_shopping_cart,
                                  color: isInCart ? Colors.green : Theme.of(context).primaryColor,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  isInCart ? 'Ajouté au panier' : 'Ajouter au panier',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isInCart ? Colors.green : Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 10),
                    ],

                    // Contact Owner Button
                    OutlinedButton(
                      onPressed: item.isAvailable ? () => _contactOwner(context) : null,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey),
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text(
                        'Contacter le propriétaire',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ] else if (isOwner) ...[
                    // Owner view - show management options
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gestion de votre objet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Vous êtes le propriétaire de cet objet. Utilisez le bouton modifier pour apporter des changements.',
                              style: TextStyle(color: Colors.blue[700]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],


                  // Add some extra space at the bottom for better scrolling
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _contactOwner(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Contacter le propriétaire'),
          content: Text('Fonctionnalité de contact à implémenter.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _reserveNow(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationFormPage(
          itemId: item.id,
          itemTitle: item.title,
          dailyPrice: item.dailyPrice,
          ownerId: item.ownerId,
        ),
      ),
    );
  }

  void _addToCart(BuildContext context, ReservationProvider reservationProvider, AuthProvider authProvider) async {
    if (authProvider.appUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez vous connecter pour ajouter au panier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final isInCart = reservationProvider.cart?.items
        .any((cartItem) => cartItem.itemId == item.id) ?? false;

    if (isInCart) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cet objet est déjà dans votre panier'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedDates = await _showDateSelectionDialog(context);
    if (selectedDates == null) return;

    final (startDate, endDate) = selectedDates;

    final cartItem = ReservationCartItem(
      itemId: item.id,
      itemTitle: item.title,
      ownerId: item.ownerId,
      dailyPrice: item.dailyPrice,
      startDate: startDate,
      endDate: endDate,
      message: '',
    );

    final success = await reservationProvider.addToCart(
      cartItem,
      authProvider.appUser!.id,
      authProvider.appUser!.name,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Objet ajouté au panier avec succès!'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Voir le panier',
            textColor: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/cart');
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: L\'objet n\'est pas disponible pour ces dates'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<(DateTime, DateTime)?> _showDateSelectionDialog(BuildContext context) async {
    DateTime? startDate;
    DateTime? endDate;

    return showDialog<(DateTime, DateTime)?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Sélectionner les dates'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('Date de début'),
                  subtitle: Text(startDate == null
                      ? 'Sélectionner'
                      : '${startDate!.day}/${startDate!.month}/${startDate!.year}'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        startDate = picked;
                        if (endDate != null && endDate!.isBefore(startDate!)) {
                          endDate = null;
                        }
                      });
                    }
                  },
                ),
                ListTile(
                  title: Text('Date de fin'),
                  subtitle: Text(endDate == null
                      ? 'Sélectionner'
                      : '${endDate!.day}/${endDate!.month}/${endDate!.year}'),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => endDate = picked);
                    }
                  },
                ),
                if (startDate != null && endDate != null) ...[
                  SizedBox(height: 16),
                  Text(
                    'Durée: ${endDate!.difference(startDate!).inDays} jour(s)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Prix total: ${(endDate!.difference(startDate!).inDays * item.dailyPrice).toStringAsFixed(2)} TND',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: startDate != null && endDate != null
                    ? () => Navigator.of(context).pop((startDate!, endDate!))
                    : null,
                child: Text('Ajouter au panier'),
              ),
            ],
          );
        },
      ),
    );
  }
}