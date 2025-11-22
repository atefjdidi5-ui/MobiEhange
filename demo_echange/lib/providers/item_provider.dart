import 'package:flutter/foundation.dart';

import '../models/Item.dart';
import '../services/item_service.dart';

class ItemProvider with ChangeNotifier {
  final ItemService _itemService = ItemService();
  List<Item> _items = [];
  List<Item> _myItems = [];
  bool _isLoading = false;

  List<Item> get items => _items;
  List<Item> get myItems => _myItems;
  bool get isLoading => _isLoading;

  // Load all items
  void loadItems() {
    _itemService.getItems().listen((items) {
      _items = items;
      print(items);

      notifyListeners();
    });
  }

  // Load my items
  void loadMyItems(String ownerId) {
    _itemService.getItemsByOwner(ownerId).listen((items) {
      _myItems = items;
      notifyListeners();
    });
  }

  // Create item
  Future<bool> createItem(Item item) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _itemService.createItem(item);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update item
  Future<bool> updateItem(Item item) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _itemService.updateItem(item);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete item
  Future<bool> deleteItem(String itemId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _itemService.deleteItem(itemId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}