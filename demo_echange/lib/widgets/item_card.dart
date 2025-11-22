import 'package:flutter/material.dart';

import '../models/Item.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;

  const ItemCard({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: item.imageUrls.isNotEmpty
                  ? Image.network(
                item.imageUrls.first,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.image, size: 50, color: Colors.grey),
                  );
                },
              )
                  : Container(
                color: Colors.grey[200],
                child: Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${item.dailyPrice}tnd/jour',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
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
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber),
                      SizedBox(width: 2),
                      Text(
                        item.rating.toStringAsFixed(1),
                        style: TextStyle(fontSize: 10),
                      ),
                      SizedBox(width: 4),
                      Text(
                        '(${item.totalReviews})',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.isAvailable ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.isAvailable ? 'Disponible' : 'Indisponible',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
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
  }
}