import 'package:flutter/material.dart';
import '../../models/Item.dart';
import 'edit_item_page.dart';

class ItemDetailPage extends StatelessWidget {
  final Item item;
  final bool isOwner;

  const ItemDetailPage({
    Key? key,
    required this.item,
    this.isOwner = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          // Item Image Placeholder
          Container(
            height: 250,
            width: double.infinity,
            color: Colors.grey[300],
            child: item.imageUrls.isNotEmpty
                ? Image.network(
              item.imageUrls.first,
              fit: BoxFit.cover,
            )
                : Icon(
              Icons.photo,
              size: 80,
              color: Colors.grey[600],
            ),
          ),

          Expanded(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: ListView(
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

                  // Action Buttons
                  if (!isOwner) ...[
                    ElevatedButton(
                      onPressed: item.isAvailable ? () => _contactOwner(context) : null,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      child: Text(
                        'Contacter le propriétaire',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: item.isAvailable ? () => _rentItem(context) : null,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Réserver maintenant',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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

  void _rentItem(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Réserver cet objet'),
          content: Text('Fonctionnalité de réservation à implémenter.'),
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
}