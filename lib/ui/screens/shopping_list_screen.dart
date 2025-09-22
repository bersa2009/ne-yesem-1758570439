import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shopping_list_provider.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışveriş Listesi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddItemDialog(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'clear_completed':
                  context.read<ShoppingListProvider>().clearCompletedItems();
                  break;
                case 'export_pdf':
                  _exportAsPDF(context);
                  break;
                case 'export_csv':
                  _exportAsCSV(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_completed',
                child: Text('Tamamlananları Temizle'),
              ),
              const PopupMenuItem(
                value: 'export_pdf',
                child: Text('PDF Olarak Dışa Aktar'),
              ),
              const PopupMenuItem(
                value: 'export_csv',
                child: Text('CSV Olarak Dışa Aktar'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer2<AuthProvider, ShoppingListProvider>(
        builder: (context, authProvider, shoppingProvider, child) {
          if (!authProvider.isAuthenticated) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Alışveriş listesi için giriş yapın'),
                  SizedBox(height: 16),
                  Text('Listeleriniz senkronize edilir'),
                ],
              ),
            );
          }

          if (shoppingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (shoppingProvider.shoppingList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Alışveriş listeniz boş', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Malzeme eklemek için + butonuna tıklayın'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: shoppingProvider.shoppingList.length,
            itemBuilder: (context, index) {
              final item = shoppingProvider.shoppingList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  leading: Checkbox(
                    value: item.checked,
                    onChanged: (value) {
                      shoppingProvider.toggleItemChecked(item.id, value ?? false);
                    },
                  ),
                  title: Text(
                    item.name,
                    style: TextStyle(
                      decoration: item.checked ? TextDecoration.lineThrough : null,
                      color: item.checked ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text(item.category),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => shoppingProvider.removeShoppingItem(item.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final categoryController = TextEditingController();
    String selectedCategory = 'Sebze';

    final categories = ['Sebze', 'Meyve', 'Et', 'Süt', 'Tahıl', 'Diğer'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Malzeme Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Malzeme adı'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  context.read<ShoppingListProvider>().addShoppingItem(
                    nameController.text,
                    selectedCategory,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportAsPDF(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF dışa aktarma yakında gelecek')),
    );
  }

  void _exportAsCSV(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV dışa aktarma yakında gelecek')),
    );
  }
}