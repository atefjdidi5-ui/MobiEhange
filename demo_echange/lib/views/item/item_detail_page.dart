import 'package:flutter/material.dart';

import '../../models/Item.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de l\'objet'),
      ),
      body: Center(
        child: Text('Page de détail - À implémenter'),
      ),
    );
  }
}