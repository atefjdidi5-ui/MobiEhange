// cart_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/ReservationCart.dart';
import '../../providers/auth-provider.dart';
import '../../providers/reservation_provider.dart';

class CartPage extends StatelessWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final reservationProvider = Provider.of<ReservationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Panier de réservation'),
        actions: [
          if (reservationProvider.cart != null && reservationProvider.cart!.items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () {
                _showClearCartDialog(context, reservationProvider, authProvider.appUser!.id);
              },
            ),
        ],
      ),
      body: reservationProvider.cart == null || reservationProvider.cart!.items.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Votre panier est vide', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Ajoutez des réservations pour les voir ici'),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: reservationProvider.cart!.items.length,
              itemBuilder: (context, index) {
                final item = reservationProvider.cart!.items[index];
                return _buildCartItem(item, reservationProvider, authProvider.appUser!.id);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${reservationProvider.cart!.totalPrice.toStringAsFixed(2)}€',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 16),
                Consumer<ReservationProvider>(
                  builder: (context, reservationProvider, child) {
                    return reservationProvider.isLoading
                        ? Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      onPressed: () => _confirmCart(context, reservationProvider, authProvider.appUser!.id),
                      child: Text('Confirmer les réservations (${reservationProvider.cart!.itemCount})'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(ReservationCartItem item, ReservationProvider reservationProvider, String renterId) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        title: Text(item.itemTitle, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Text('${DateFormat('dd/MM/yyyy').format(item.startDate)} - ${DateFormat('dd/MM/yyyy').format(item.endDate)}'),
            Text('${item.numberOfDays} jour(s) - ${item.totalPrice.toStringAsFixed(2)} TND'),
            if (item.message != null && item.message!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Message: ${item.message!}', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            reservationProvider.removeFromCart(item.itemId, renterId);
          },
        ),
      ),
    );
  }

  void _showClearCartDialog(BuildContext context, ReservationProvider reservationProvider, String renterId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vider le panier'),
        content: Text('Êtes-vous sûr de vouloir vider tout votre panier ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              reservationProvider.clearCart(renterId);
              Navigator.pop(context);
            },
            child: Text('Vider', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmCart(BuildContext context, ReservationProvider reservationProvider, String renterId) async {
    final success = await reservationProvider.confirmCart(renterId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Réservations confirmées avec succès!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la confirmation des réservations')),
      );
    }
  }
}