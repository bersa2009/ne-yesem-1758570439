import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../services/speech_service.dart';
import '../../services/camera_service.dart';
import '../../services/error_handling_service.dart';
import '../widgets/speech_button.dart';
import '../widgets/camera_button.dart';
import 'results_screen.dart';

class IngredientsScreen extends ConsumerStatefulWidget {
  const IngredientsScreen({super.key});

  @override
  ConsumerState<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends ConsumerState<IngredientsScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isListening = false;
  bool _isProcessingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storageServiceProvider).init();
    });
  }

  void _toggleSpeechInput() async {
    final speechService = ref.read(speechServiceProvider);

    if (_isListening) {
      await speechService.stopListening();
      setState(() => _isListening = false);
      _processSpeechResult(speechService.lastWords);
    } else {
      setState(() => _isListening = true);
      await speechService.startListening((result) {
        _processSpeechResult(result);
      });
    }
  }

  void _processSpeechResult(String result) {
    final speechService = ref.read(speechServiceProvider);
    final ingredients = ref.watch(ingredientsProvider);

    ingredients.when(
      data: (allIngredients) {
        final parsed = speechService.parseIngredients(result);
        final selectedIds = ref.read(selectedIngredientsProvider);

        for (final ingredient in parsed) {
          final matches = allIngredients.where((i) =>
            i.name.toLowerCase().contains(ingredient.toLowerCase()) ||
            i.aliases.any((a) => a.toLowerCase().contains(ingredient.toLowerCase())));

          if (matches.isNotEmpty) {
            final match = matches.first;
            if (!selectedIds.contains(match.id)) {
              ref.read(selectedIngredientsProvider.notifier).update((state) => {...state, match.id});
              ErrorHandlingService.showSuccess(context, '${match.name} eklendi');
            }
          } else {
            ErrorHandlingService.showError(context, '$ingredient malzemesi bulunamadı');
          }
        }
      },
      loading: () {},
      error: (error, stack) => ErrorHandlingService.handleError(context, error, stack),
    );
  }

  void _handleCameraInput() async {
    if (_isProcessingImage) return;

    setState(() => _isProcessingImage = true);

    try {
      final cameraService = ref.read(cameraServiceProvider);
      final ingredients = ref.watch(ingredientsProvider);

      await ErrorHandlingService.withRetry(() async {
        await cameraService.initialize();
      }, context);

      final detectedIngredients = await cameraService.analyzeImage();

      ingredients.when(
        data: (allIngredients) {
          final selectedIds = ref.read(selectedIngredientsProvider);

          for (final detected in detectedIngredients) {
            final matches = allIngredients.where((i) =>
              i.name.toLowerCase().contains(detected.toLowerCase()) ||
              i.aliases.any((a) => a.toLowerCase().contains(detected.toLowerCase())));

            if (matches.isNotEmpty) {
              final match = matches.first;
              if (!selectedIds.contains(match.id)) {
                ref.read(selectedIngredientsProvider.notifier).update((state) => {...state, match.id});
                ErrorHandlingService.showSuccess(context, '${match.name} eklendi');
              }
            }
          }
        },
        loading: () {},
        error: (error, stack) => ErrorHandlingService.handleError(context, error, stack),
      );
    } catch (e) {
      ErrorHandlingService.handleError(context, e, null);
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }

  void _handleGalleryInput() async {
    if (_isProcessingImage) return;

    setState(() => _isProcessingImage = true);

    try {
      final cameraService = ref.read(cameraServiceProvider);
      final ingredients = ref.watch(ingredientsProvider);

      final detectedIngredients = await cameraService.pickImageFromGallery();

      ingredients.when(
        data: (allIngredients) {
          final selectedIds = ref.read(selectedIngredientsProvider);

          for (final detected in detectedIngredients) {
            final matches = allIngredients.where((i) =>
              i.name.toLowerCase().contains(detected.toLowerCase()) ||
              i.aliases.any((a) => a.toLowerCase().contains(detected.toLowerCase())));

            if (matches.isNotEmpty) {
              final match = matches.first;
              if (!selectedIds.contains(match.id)) {
                ref.read(selectedIngredientsProvider.notifier).update((state) => {...state, match.id});
                ErrorHandlingService.showSuccess(context, '${match.name} eklendi');
              }
            }
          }
        },
        loading: () {},
        error: (error, stack) => ErrorHandlingService.handleError(context, error, stack),
      );
    } catch (e) {
      ErrorHandlingService.handleError(context, e, null);
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIds = ref.watch(selectedIngredientsProvider);
    final ingredientsAsync = ref.watch(ingredientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Malzemeler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: _handleGalleryInput,
            tooltip: 'Galeriden seç',
          ),
        ],
      ),
      body: ingredientsAsync.when(
        data: (allIngredients) {
          final query = _controller.text.trim().toLowerCase();
          final filtered = query.isEmpty
              ? allIngredients
              : allIngredients.where((i) =>
                  i.name.toLowerCase().contains(query) ||
                  i.aliases.any((a) => a.toLowerCase().contains(query))).toList();

          return Column(
            children: [
              // Search and input controls
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Malzeme ara: örn. domates',
                          suffixIcon: SpeechButton(
                            isListening: _isListening,
                            onPressed: _toggleSpeechInput,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CameraButton(
                      isProcessing: _isProcessingImage,
                      onPressed: _handleCameraInput,
                    ),
                  ],
                ),
              ),

              // Selected ingredients summary
              if (selectedIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12.0),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Row(
                    children: [
                      Text('${selectedIds.length} malzeme seçildi'),
                      const Spacer(),
                      TextButton(
                        onPressed: () => ref.read(selectedIngredientsProvider.notifier).state = {},
                        child: const Text('Temizle'),
                      ),
                    ],
                  ),
                ),

              // Ingredients list
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final ing = filtered[index];
                    final selected = selectedIds.contains(ing.id);
                    return CheckboxListTile(
                      value: selected,
                      title: Text(ing.name),
                      subtitle: Text(ing.category),
                      onChanged: (val) {
                        if (val == true) {
                          ref.read(selectedIngredientsProvider.notifier).update((state) => {...state, ing.id});
                        } else {
                          ref.read(selectedIngredientsProvider.notifier).update((state) => state.where((id) => id != ing.id).toSet());
                        }
                      },
                    );
                  },
                ),
              ),

              // Search button
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: selectedIds.isEmpty ? null : () async {
                      final service = await ref.read(matchingServiceProvider.future);
                      final results = service.match(
                        userIngredientIds: selectedIds,
                        filters: const MatchFilters(maxTimeMinutes: 30),
                      );
                      if (!mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ResultsScreen(
                            results: results,
                            ingredientById: service.ingredientById,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Tarif Ara'),
                  ),
                ),
              )
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Malzemeler yüklenemedi'),
              ElevatedButton(
                onPressed: () => ref.invalidate(ingredientsProvider),
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

