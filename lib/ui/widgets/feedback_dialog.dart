import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/ai_service.dart';

class FeedbackDialog extends StatefulWidget {
  final Recipe recipe;
  final List<String> missingIngredients;
  final Map<String, Ingredient> ingredientById;
  final Function(UserFeedback) onFeedbackSubmitted;

  const FeedbackDialog({
    super.key,
    required this.recipe,
    required this.missingIngredients,
    required this.ingredientById,
    required this.onFeedbackSubmitted,
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  double _rating = 3.0;
  final Map<String, String> _substitutions = {};
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.rate_review, color: Colors.blue),
          SizedBox(width: 8),
          Text('Tarif Değerlendirmesi'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.recipe.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Rating Section
            const Text(
              'Bu tarifi nasıl buldunuz?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
            Text(
              _getRatingText(_rating),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Substitutions Section
            if (widget.missingIngredients.isNotEmpty) ...[
              const Text(
                'Eksik malzemelerin yerine ne kullandınız?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...widget.missingIngredients.map((missingId) {
                final ingredient = widget.ingredientById[missingId];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          ingredient?.name ?? missingId,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Yerine ne kullandınız?',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              _substitutions[missingId] = value;
                            } else {
                              _substitutions.remove(missingId);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            
            // Notes Section
            const Text(
              'Ek notlarınız (opsiyonel)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tarif hakkında düşüncelerinizi paylaşın...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitFeedback,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Gönder'),
        ),
      ],
    );
  }

  String _getRatingText(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'Çok kötü';
      case 2:
        return 'Kötü';
      case 3:
        return 'Orta';
      case 4:
        return 'İyi';
      case 5:
        return 'Mükemmel';
      default:
        return '';
    }
  }

  void _submitFeedback() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final feedback = UserFeedback(
        recipeId: widget.recipe.id,
        rating: _rating,
        substitutions: _substitutions,
        timestamp: DateTime.now(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await widget.onFeedbackSubmitted(feedback);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}