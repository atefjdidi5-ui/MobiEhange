import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth-provider.dart';
import '../../providers/item_provider.dart';
import '../../widgets/item_card.dart';
import '../item/add_item_page.dart';
import '../item/item_detail_page.dart';


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
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final itemProvider = Provider.of<ItemProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('DEVMOB Echange'),
        backgroundColor: Colors.blue,
        actions: [
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
      body: _currentIndex == 0
          ? _buildHomeTab(itemProvider)
          : _buildProfileTab(authProvider, itemProvider),
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
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

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
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8,
        ),
        itemCount: itemProvider.items.length,
        itemBuilder: (context, index) {
          final item = itemProvider.items[index];
          return ItemCard(
            item: item,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailPage(item: item),
                ),
              );
            },
          );
        },
      ),
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
                      //Text('${user.rating.toStringAsFixed(1)} (${user.totalReviews} avis)'),
                    ],
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
        ],
      ),
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