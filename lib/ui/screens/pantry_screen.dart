import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/pantry_provider.dart';
import '../../providers/auth_provider.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  String? _selectedIngredientId;
  bool _showAddForm = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              setState(() {
                _showAddForm = !_showAddForm;
              });
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, PantryProvider>(
        builder: (context, authProvider, pantryProvider, child) {
          if (!authProvider.isAuthenticated) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Kileri kullanmak için giriş yapın'),
                  SizedBox(height: 16),
                  Text('Verileriniz güvende saklanır'),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (_showAddForm) _buildAddForm(pantryProvider),
              Expanded(
                child: pantryProvider.pantryItems.isEmpty
                    ? _buildEmptyPantry()
                    : _buildPantryList(pantryProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddForm(PantryProvider pantryProvider) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yeni Malzeme Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Malzeme ara',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                // TODO: Implement ingredient search
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Miktar',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _unitController,
                    decoration: const InputDecoration(
                      labelText: 'Birim',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addPantryItem,
                    child: const Text('Ekle'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showAddForm = false;
                        _clearForm();
                      });
                    },
                    child: const Text('İptal'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPantry() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.kitchen, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Kileriniz boş', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Malzeme eklemek için + butonuna tıklayın'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showAddForm = true;
              });
            },
            child: const Text('Malzeme Ekle'),
          ),
        ],
      ),
    );
  }

  Widget _buildPantryList(PantryProvider pantryProvider) {
    return ListView.builder(
      itemCount: pantryProvider.pantryItems.length,
      itemBuilder: (context, index) {
        final item = pantryProvider.pantryItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            title: Text(item.ingredientName),
            subtitle: Text('${item.quantity} ${item.unit}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.expiryDate != null)
                  Text(
                    _formatExpiryDate(item.expiryDate!),
                    style: TextStyle(
                      color: _getExpiryColor(item.expiryDate!),
                      fontSize: 12,
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editPantryItem(item),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removePantryItem(item.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addPantryItem() async {
    if (_quantityController.text.isEmpty || _unitController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen miktar ve birim girin')),
      );
      return;
    }

    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir miktar girin')),
      );
      return;
    }

    final pantryItem = PantryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      ingredientId: _selectedIngredientId ?? 'unknown',
      ingredientName: _searchController.text.isEmpty ? 'Yeni Malzeme' : _searchController.text,
      quantity: quantity,
      unit: _unitController.text,
      addedAt: DateTime.now(),
    );

    try {
      await context.read<PantryProvider>().addPantryItem(pantryItem);
      _clearForm();
      setState(() {
        _showAddForm = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Malzeme eklenirken hata oluştu: $e')),
      );
    }
  }

  void _editPantryItem(PantryItem item) {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Düzenleme özelliği yakında gelecek')),
    );
  }

  void _removePantryItem(String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Malzemeyi Sil'),
        content: const Text('Bu malzemeyi kilerinizden silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await context.read<PantryProvider>().removePantryItem(itemId);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Malzeme silinirken hata oluştu: $e')),
        );
      }
    }
  }

  void _clearForm() {
    _searchController.clear();
    _quantityController.clear();
    _unitController.clear();
    _selectedIngredientId = null;
  }

  String _formatExpiryDate(DateTime expiryDate) {
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;

    if (daysUntilExpiry < 0) {
      return 'Süresi geçmiş';
    } else if (daysUntilExpiry == 0) {
      return 'Bugün son';
    } else if (daysUntilExpiry == 1) {
      return 'Yarın';
    } else {
      return '$daysUntilExpiry gün';
    }
  }

  Color _getExpiryColor(DateTime expiryDate) {
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;

    if (daysUntilExpiry < 0) {
      return Colors.red;
    } else if (daysUntilExpiry <= 3) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}