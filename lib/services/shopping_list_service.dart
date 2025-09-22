import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/models.dart';
import 'firestore_service.dart';

class ShoppingListService {
  final FirestoreService _firestoreService = FirestoreService();

  Future<List<ShoppingListItem>> getShoppingList() async {
    return await _firestoreService.getShoppingListItems();
  }

  Future<void> addToShoppingList(String ingredientId, double quantity, String unit) async {
    final item = ShoppingListItem(
      ingredientId: ingredientId,
      quantity: quantity,
      unit: unit,
      addedAt: DateTime.now(),
    );
    await _firestoreService.addShoppingListItem(item);
  }

  Future<void> addMissingIngredientsToShoppingList(List<RecipeIngredient> missingIngredients) async {
    await _firestoreService.addMissingIngredientsToShoppingList(missingIngredients);
  }

  Future<void> toggleItemPurchased(ShoppingListItem item) async {
    final updatedItem = ShoppingListItem(
      ingredientId: item.ingredientId,
      quantity: item.quantity,
      unit: item.unit,
      purchased: !item.purchased,
      addedAt: item.addedAt,
    );
    await _firestoreService.updateShoppingListItem(updatedItem);
  }

  Future<void> removeFromShoppingList(String ingredientId) async {
    await _firestoreService.removeShoppingListItem(ingredientId);
  }

  Future<void> clearPurchasedItems() async {
    await _firestoreService.clearPurchasedItems();
  }

  Future<String> exportToPDF(List<ShoppingListItem> items, Map<String, Ingredient> ingredientById) async {
    final pdf = pw.Document();
    
    // Separate purchased and unpurchased items
    final unpurchased = items.where((item) => !item.purchased).toList();
    final purchased = items.where((item) => item.purchased).toList();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Alışveriş Listesi',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 20),
              
              if (unpurchased.isNotEmpty) ...[
                pw.Text(
                  'Alınacaklar:',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                ...unpurchased.map((item) {
                  final ingredient = ingredientById[item.ingredientId];
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 15,
                          height: 15,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 1),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: pw.Text('${ingredient?.name ?? item.ingredientId} - ${item.quantity} ${item.unit}'),
                        ),
                      ],
                    ),
                  );
                }),
                pw.SizedBox(height: 20),
              ],
              
              if (purchased.isNotEmpty) ...[
                pw.Text(
                  'Alınanlar:',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                ...purchased.map((item) {
                  final ingredient = ingredientById[item.ingredientId];
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      children: [
                        pw.Container(
                          width: 15,
                          height: 15,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(width: 1),
                            color: PdfColors.grey300,
                          ),
                          child: pw.Center(
                            child: pw.Text('✓', style: pw.TextStyle(fontSize: 10)),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: pw.Text(
                            '${ingredient?.name ?? item.ingredientId} - ${item.quantity} ${item.unit}',
                            style: pw.TextStyle(decoration: pw.TextDecoration.lineThrough),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              
              pw.Spacer(),
              pw.Text(
                'Oluşturulma tarihi: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/alisveris_listesi_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
  }

  String exportToCSV(List<ShoppingListItem> items, Map<String, Ingredient> ingredientById) {
    final buffer = StringBuffer();
    buffer.writeln('Malzeme,Miktar,Birim,Durum');
    
    for (final item in items) {
      final ingredient = ingredientById[item.ingredientId];
      final status = item.purchased ? 'Alındı' : 'Alınacak';
      buffer.writeln('${ingredient?.name ?? item.ingredientId},${item.quantity},${item.unit},$status');
    }
    
    return buffer.toString();
  }
}