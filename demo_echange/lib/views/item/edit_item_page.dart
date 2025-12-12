import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/Item.dart';
import '../../providers/item_provider.dart';

class EditItemPage extends StatefulWidget {
  final Item item;

  const EditItemPage({Key? key, required this.item}) : super(key: key);

  @override
  _EditItemPageState createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  String _selectedCategory = 'Électronique';
  bool _isAvailable = true;
  final List<String> _imageUrls = [];

  final List<String> _categories = [
    'Électronique',
    'Maison',
    'Sport',
    'Véhicules',
    'Immobilier',
    'Loisirs',
    'Autre'
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill the form with existing item data
    _titleController.text = widget.item.title;
    _descriptionController.text = widget.item.description;
    _priceController.text = widget.item.dailyPrice.toString();
    _locationController.text = widget.item.location;
    _selectedCategory = widget.item.category;
    _isAvailable = widget.item.isAvailable;
    _imageUrls.addAll(widget.item.imageUrls);
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = Provider.of<ItemProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier l\'objet'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Titre*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un titre';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description*',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer une description';
                  }
                  if (value.length < 10) {
                    return 'La description doit contenir au moins 10 caractères';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Price Field
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Prix journalier (TND)*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un prix';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Veuillez entrer un prix valide';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Catégorie*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez sélectionner une catégorie';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Location Field
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Lieu*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un lieu';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Image URLs Section
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Images de l\'objet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: InputDecoration(
                          labelText: 'URL de l\'image',
                          hintText: 'https://example.com/image.jpg',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: _addImageUrl,
                          ),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      SizedBox(height: 8),
                      if (_imageUrls.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Text(
                          'Images (${_imageUrls.length})',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _imageUrls.map((url) {
                            return Chip(
                              label: Text(
                                'Image ${_imageUrls.indexOf(url) + 1}',
                                style: TextStyle(fontSize: 12),
                              ),
                              deleteIcon: Icon(Icons.close, size: 16),
                              onDeleted: () => _removeImageUrl(url),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 8),
                        // Preview of images
                        Container(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _imageUrls.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Container(
                                  width: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      _imageUrls[index],
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
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Availability Switch
              SwitchListTile(
                title: Text('Disponible à la location'),
                value: _isAvailable,
                onChanged: (bool value) {
                  setState(() {
                    _isAvailable = value;
                  });
                },
                secondary: Icon(_isAvailable ? Icons.check_circle : Icons.remove_circle),
              ),
              SizedBox(height: 30),

              // Update Button
              ElevatedButton(
                onPressed: itemProvider.isLoading
                    ? null
                    : _updateItem,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: itemProvider.isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Mettre à jour',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Delete Button
              OutlinedButton(
                onPressed: itemProvider.isLoading ? null : () => _showDeleteConfirmation(context),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.red),
                ),
                child: Text(
                  'Supprimer l\'objet',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addImageUrl() {
    final url = _imageUrlController.text.trim();
    if (url.isNotEmpty && Uri.tryParse(url)?.hasAbsolutePath == true) {
      setState(() {
        _imageUrls.add(url);
        _imageUrlController.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez entrer une URL valide'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImageUrl(String url) {
    setState(() {
      _imageUrls.remove(url);
    });
  }

  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez garder au moins une image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final updatedItem = widget.item.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrls: _imageUrls,
      dailyPrice: double.parse(_priceController.text),
      category: _selectedCategory,
      location: _locationController.text.trim(),
      isAvailable: _isAvailable,
    );

    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final success = await itemProvider.updateItem(updatedItem);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Objet mis à jour avec succès!')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la mise à jour')),
      );
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmer la suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer cet objet ? Cette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteItem();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem() async {
    final itemProvider = Provider.of<ItemProvider>(context, listen: false);
    final success = await itemProvider.deleteItem(widget.item.id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Objet supprimé avec succès!')),
      );
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }
}