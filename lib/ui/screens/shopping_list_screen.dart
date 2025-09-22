import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/models.dart';
import '../../services/shopping_list_service.dart';
import '../../services/matching_service.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final ShoppingListService _shoppingListService = ShoppingListService();
  List<ShoppingListItem> _items = [];
  Map<String, Ingredient> _ingredientById = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    
    try {
      // Load ingredients
      final matchingService = await MatchingService.loadFromAssets();
      _ingredientById = matchingService.ingredientById;
      
      // Load shopping list
      _items = await _shoppingListService.getShoppingList();
    } catch (e) {
      print('Error loading shopping list: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleItemPurchased(ShoppingListItem item) async {
    await _shoppingListService.toggleItemPurchased(item);
    await _loadData();
  }

  Future<void> _removeItem(String ingredientId) async {
    await _shoppingListService.removeFromShoppingList(ingredientId);
    await _loadData();
  }

  Future<void> _clearPurchased() async {
    await _shoppingListService.clearPurchasedItems();
    await _loadData();
  }

  Future<void> _exportToPDF() async {
    try {
      final filePath = await _shoppingListService.exportToPDF(_items, _ingredientById);
      await Share.shareXFiles([XFile(filePath)], text: 'Alışveriş Listesi');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF oluşturulurken hata: $e')),
      );
    }
  }

  Future<void> _exportToCSV() async {
    try {
      final csvContent = _shoppingListService.exportToCSV(_items, _ingredientById);
      await Share.share(csvContent, subject: 'Alışveriş Listesi');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV oluşturulurken hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final unpurchased = _items.where((item) => !item.purchased).toList();
    final purchased = _items.where((item) => item.purchased).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışveriş Listesi'),
        actions: [
          if (_items.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'pdf':
                    _exportToPDF();
                    break;
                  case 'csv':
                    _exportToCSV();
                    break;
                  case 'clear':
                    _showClearDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf),
                      SizedBox(width: 8),
                      Text('PDF olarak paylaş'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'csv',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart),
                      SizedBox(width: 8),
                      Text('CSV olarak paylaş'),
                    ],
                  ),
                ),
                if (purchased.isNotEmpty)
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all),
                        SizedBox(width: 8),
                        Text('Alınanları temizle'),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: _items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Alışveriş listeniz boş',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tarif detaylarından eksik malzemeleri ekleyebilirsiniz',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                if (unpurchased.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Alınacaklar (${unpurchased.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...unpurchased.map((item) => _buildListItem(item, false)),
                ],
                if (purchased.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Alınanlar (${purchased.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  ...purchased.map((item) => _buildListItem(item, true)),
                ],
              ],
            ),
    );
  }

  Widget _buildListItem(ShoppingListItem item, bool isPurchased) {
    final ingredient = _ingredientById[item.ingredientId];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: item.purchased,
          onChanged: (_) => _toggleItemPurchased(item),
        ),
        title: Text(
          ingredient?.name ?? item.ingredientId,
          style: TextStyle(
            decoration: isPurchased ? TextDecoration.lineThrough : null,
            color: isPurchased ? Colors.grey[600] : null,
          ),
        ),
        subtitle: Text(
          '${item.quantity} ${item.unit}',
          style: TextStyle(
            color: isPurchased ? Colors.grey[500] : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _showDeleteDialog(item),
        ),
      ),
    );
  }

  void _showDeleteDialog(ShoppingListItem item) {
    final ingredient = _ingredientById[item.ingredientId];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Malzemeyi Sil'),
        content: Text('${ingredient?.name ?? item.ingredientId} malzemesini listeden silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeItem(item.ingredientId);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alınanları Temizle'),
        content: const Text('Alınan tüm malzemeleri listeden silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearPurchased();
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }
}