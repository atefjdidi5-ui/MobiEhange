
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/Item.dart';
import 'firebase-service.dart';


class ItemService {
  final FirebaseFirestore _firestore = FirebaseService.firestore;

  // Create a new item
  Future<String> createItem(Item item) async {
    try {
      final docRef = _firestore.collection('items').doc();
      final newItem = item.copyWith();
      await docRef.set(newItem.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating item: $e');
      rethrow;
    }
  }

  // Get all items
  Stream<List<Item>> getItems() {
    return _firestore
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Item.fromMap(doc.data()))
        .toList());
  }

  // Get items by owner
  Stream<List<Item>> getItemsByOwner(String ownerId) {
    return _firestore
        .collection('items')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Item.fromMap(doc.data()))
        .toList());
  }

  // Get item by ID
  Future<Item?> getItemById(String itemId) async {
    try {
      final doc = await _firestore.collection('items').doc(itemId).get();
      if (doc.exists) {
        return Item.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting item: $e');
      return null;
    }
  }

  // Update item
  Future<void> updateItem(Item item) async {
    try {
      await _firestore
          .collection('items')
          .doc(item.id)
          .update(item.toMap());
    } catch (e) {
      print('Error updating item: $e');
      rethrow;
    }
  }

  // Delete item
  Future<void> deleteItem(String itemId) async {
    try {
      await _firestore.collection('items').doc(itemId).delete();
    } catch (e) {
      print('Error deleting item: $e');
      rethrow;
    }
  }

  // Search items
  Stream<List<Item>> searchItems(String query) {
    return _firestore
        .collection('items')
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThan: query + 'z')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Item.fromMap(doc.data()))
        .toList());
  }
}