import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/sqlite_service.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  late Future<List<ShoppingListItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _itemsFuture = SqliteService.instance.listShoppingItems();
  }

  Future<void> _toggle(ShoppingListItem item, bool checked) async {
    await SqliteService.instance.toggleShoppingItemChecked(id: item.id, checked: checked);
    setState(_reload);
  }

  Future<void> _remove(ShoppingListItem item) async {
    await SqliteService.instance.removeShoppingItem(item.id);
    setState(_reload);
  }

  Future<void> _clearChecked() async {
    await SqliteService.instance.clearCheckedShoppingItems();
    setState(_reload);
  }

  Future<void> _shareCsv(List<ShoppingListItem> items) async {
    final buffer = StringBuffer();
    buffer.writeln('Name,Quantity,Unit,Checked');
    for (final i in items) {
      final q = i.quantity?.toStringAsFixed(2) ?? '';
      final unit = i.unit ?? '';
      buffer.writeln('"${i.name}","$q","$unit","${i.checked ? 'yes' : 'no'}"');
    }
    await Share.share(buffer.toString(), subject: 'Alışveriş Listesi');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışveriş Listesi'),
        actions: [
          IconButton(
            onPressed: () async {
              final items = await SqliteService.instance.listShoppingItems();
              await _shareCsv(items);
            },
            icon: const Icon(Icons.ios_share),
            tooltip: 'Paylaş (CSV)',
          ),
          IconButton(
            onPressed: _clearChecked,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Tamamlananları temizle',
          )
        ],
      ),
      body: FutureBuilder<List<ShoppingListItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Liste boş. Tariflerden eksikler ekleyin.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return Dismissible(
                key: ValueKey(item.id),
                background: Container(color: Colors.red),
                onDismissed: (_) => _remove(item),
                child: CheckboxListTile(
                  value: item.checked,
                  onChanged: (v) => _toggle(item, v ?? false),
                  title: Text(item.name),
                  subtitle: Row(
                    children: [
                      if (item.quantity != null) Text('Miktar: ${item.quantity} '),
                      if (item.unit != null) Text(item.unit!),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => const _AddItemDialog(),
          );
          setState(_reload);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _AddItemDialog extends StatefulWidget {
  const _AddItemDialog();

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _qty = TextEditingController();
  final TextEditingController _unit = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Öğe ekle'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Ad')),
          TextField(controller: _qty, decoration: const InputDecoration(labelText: 'Miktar'), keyboardType: TextInputType.number),
          TextField(controller: _unit, decoration: const InputDecoration(labelText: 'Birim')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('İptal')),
        ElevatedButton(
          onPressed: () async {
            final name = _name.text.trim();
            if (name.isEmpty) return;
            final qty = double.tryParse(_qty.text.trim());
            final unit = _unit.text.trim().isEmpty ? null : _unit.text.trim();
            await SqliteService.instance.addShoppingItem(name: name, quantity: qty, unit: unit);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Ekle'),
        )
      ],
    );
  }
}

