import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import '../../services/matching_service.dart';

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<PantryItem> _pantryItems = [];
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
      
      // Load pantry items
      _pantryItems = await _firestoreService.getPantryItems();
    } catch (e) {
      print('Error loading pantry: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _addPantryItem() async {
    await showDialog(
      context: context,
      builder: (context) => _AddPantryItemDialog(
        ingredientById: _ingredientById,
        onAdd: (item) async {
          await _firestoreService.addPantryItem(item);
          await _loadData();
        },
      ),
    );
  }

  Future<void> _editPantryItem(PantryItem item) async {
    await showDialog(
      context: context,
      builder: (context) => _EditPantryItemDialog(
        item: item,
        ingredient: _ingredientById[item.ingredientId],
        onUpdate: (updatedItem) async {
          await _firestoreService.updatePantryItem(updatedItem);
          await _loadData();
        },
        onDelete: () async {
          await _firestoreService.removePantryItem(item.ingredientId);
          await _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Group items by expiry status
    final now = DateTime.now();
    final expired = _pantryItems.where((item) => 
        item.expiryDate != null && item.expiryDate!.isBefore(now)).toList();
    final expiringSoon = _pantryItems.where((item) => 
        item.expiryDate != null && 
        item.expiryDate!.isAfter(now) && 
        item.expiryDate!.isBefore(now.add(const Duration(days: 7)))).toList();
    final fresh = _pantryItems.where((item) => 
        item.expiryDate == null || 
        item.expiryDate!.isAfter(now.add(const Duration(days: 7)))).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addPantryItem,
          ),
        ],
      ),
      body: _pantryItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.kitchen, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Kileriniz boş',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Malzeme eklemek için + butonuna tıklayın',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView(
              children: [
                if (expired.isNotEmpty) ...[
                  _buildSectionHeader('Süresi Geçenler', Icons.warning, Colors.red),
                  ...expired.map((item) => _buildPantryItem(item, Colors.red[100]!)),
                ],
                if (expiringSoon.isNotEmpty) ...[
                  _buildSectionHeader('Yakında Bitecekler', Icons.schedule, Colors.orange),
                  ...expiringSoon.map((item) => _buildPantryItem(item, Colors.orange[100]!)),
                ],
                if (fresh.isNotEmpty) ...[
                  _buildSectionHeader('Taze Malzemeler', Icons.check_circle, Colors.green),
                  ...fresh.map((item) => _buildPantryItem(item, null)),
                ],
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPantryItem(PantryItem item, Color? backgroundColor) {
    final ingredient = _ingredientById[item.ingredientId];
    final now = DateTime.now();
    
    String expiryText = '';
    if (item.expiryDate != null) {
      final difference = item.expiryDate!.difference(now).inDays;
      if (difference < 0) {
        expiryText = '${difference.abs()} gün geçmiş';
      } else if (difference == 0) {
        expiryText = 'Bugün bitiyor';
      } else {
        expiryText = '$difference gün kaldı';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: backgroundColor,
      child: ListTile(
        title: Text(ingredient?.name ?? item.ingredientId),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.quantity} ${item.unit}'),
            if (expiryText.isNotEmpty) Text(expiryText),
          ],
        ),
        trailing: const Icon(Icons.edit),
        onTap: () => _editPantryItem(item),
      ),
    );
  }
}

class _AddPantryItemDialog extends StatefulWidget {
  final Map<String, Ingredient> ingredientById;
  final Function(PantryItem) onAdd;

  const _AddPantryItemDialog({
    required this.ingredientById,
    required this.onAdd,
  });

  @override
  State<_AddPantryItemDialog> createState() => _AddPantryItemDialogState();
}

class _AddPantryItemDialogState extends State<_AddPantryItemDialog> {
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController(text: 'adet');
  String? _selectedIngredientId;
  DateTime? _expiryDate;

  @override
  Widget build(BuildContext context) {
    final ingredients = widget.ingredientById.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return AlertDialog(
      title: const Text('Malzeme Ekle'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Malzeme'),
              value: _selectedIngredientId,
              items: ingredients.map((ingredient) => DropdownMenuItem(
                value: ingredient.id,
                child: Text(ingredient.name),
              )).toList(),
              onChanged: (value) => setState(() => _selectedIngredientId = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Miktar'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _unitController,
              decoration: const InputDecoration(labelText: 'Birim'),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Son Kullanma Tarihi'),
              subtitle: Text(_expiryDate != null 
                  ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                  : 'Seçilmedi'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _expiryDate = date);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _selectedIngredientId != null && _quantityController.text.isNotEmpty
              ? () {
                  final item = PantryItem(
                    ingredientId: _selectedIngredientId!,
                    quantity: double.tryParse(_quantityController.text) ?? 0,
                    unit: _unitController.text,
                    expiryDate: _expiryDate,
                    addedAt: DateTime.now(),
                  );
                  widget.onAdd(item);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}

class _EditPantryItemDialog extends StatefulWidget {
  final PantryItem item;
  final Ingredient? ingredient;
  final Function(PantryItem) onUpdate;
  final Function() onDelete;

  const _EditPantryItemDialog({
    required this.item,
    required this.ingredient,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<_EditPantryItemDialog> createState() => _EditPantryItemDialogState();
}

class _EditPantryItemDialogState extends State<_EditPantryItemDialog> {
  late final TextEditingController _quantityController;
  late final TextEditingController _unitController;
  late DateTime? _expiryDate;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    _unitController = TextEditingController(text: widget.item.unit);
    _expiryDate = widget.item.expiryDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ingredient?.name ?? widget.item.ingredientId),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _quantityController,
            decoration: const InputDecoration(labelText: 'Miktar'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _unitController,
            decoration: const InputDecoration(labelText: 'Birim'),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Son Kullanma Tarihi'),
            subtitle: Text(_expiryDate != null 
                ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                : 'Seçilmedi'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _expiryDate = null),
                ),
                const Icon(Icons.calendar_today),
              ],
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() => _expiryDate = date);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Malzemeyi Sil'),
                content: const Text('Bu malzemeyi kilden silmek istediğinizden emin misiniz?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('İptal'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close confirmation dialog
                      Navigator.of(context).pop(); // Close edit dialog
                      widget.onDelete();
                    },
                    child: const Text('Sil'),
                  ),
                ],
              ),
            );
          },
          child: const Text('Sil'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedItem = PantryItem(
              ingredientId: widget.item.ingredientId,
              quantity: double.tryParse(_quantityController.text) ?? widget.item.quantity,
              unit: _unitController.text,
              expiryDate: _expiryDate,
              addedAt: widget.item.addedAt,
            );
            widget.onUpdate(updatedItem);
            Navigator.of(context).pop();
          },
          child: const Text('Güncelle'),
        ),
      ],
    );
  }
}