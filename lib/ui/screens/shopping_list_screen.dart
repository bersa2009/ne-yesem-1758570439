import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_repository.dart';

class ShoppingListScreen extends StatefulWidget {
  final Map<String, Ingredient> ingredientById;
  const ShoppingListScreen({super.key, required this.ingredientById});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  Map<String, List<String>> _byRecipe = <String, List<String>>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = AuthService().currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    final map = await FirestoreRepository().getShoppingList(userId: user.uid);
    setState(() {
      _byRecipe = map;
      _loading = false;
    });
  }

  Future<void> _exportCsv() async {
    final lines = <String>['recipe_id,ingredient_name'];
    _byRecipe.forEach((recipeId, ids) {
      for (final id in ids) {
        final name = widget.ingredientById[id]?.name ?? id;
        lines.add('$recipeId,$name');
      }
    });
    final csv = lines.join('\n');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/shopping_list.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Alışveriş Listesi');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışveriş Listesi'),
        actions: [
          IconButton(onPressed: _exportCsv, icon: const Icon(Icons.ios_share)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _byRecipe.isEmpty
              ? const Center(child: Text('Henüz öğe yok'))
              : ListView(
                  children: _byRecipe.entries.map((entry) {
                    final recipeId = entry.key;
                    final ids = entry.value;
                    return ExpansionTile(
                      title: Text('Tarif: $recipeId'),
                      children: ids
                          .map((id) => ListTile(
                                title: Text(widget.ingredientById[id]?.name ?? id),
                              ))
                          .toList(),
                    );
                  }).toList(),
                ),
    );
  }
}

