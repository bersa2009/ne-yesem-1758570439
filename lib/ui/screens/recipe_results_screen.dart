import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../models/models.dart';
import '../widgets/recipe_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'recipe_detail_screen.dart';

class RecipeResultsScreen extends ConsumerWidget {
  const RecipeResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final recipeResults = ref.watch(recipeResultsProvider);
    final selectedIngredients = ref.watch(selectedIngredientsProvider);
    final filters = ref.watch(searchFiltersProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recipeResults),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.tune),
                if (_hasActiveFilters(filters))
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showFilters(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Summary
          if (selectedIngredients.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              margin: const EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: AppTheme.smallRadius,
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seçilen Malzemeler (${selectedIngredients.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Consumer(
                    builder: (context, ref, _) {
                      return ref.watch(matchingServiceProvider).when(
                        data: (matchingService) {
                          final ingredientNames = selectedIngredients
                              .map((id) => matchingService.ingredientById[id]?.name ?? id)
                              .toList();
                          
                          return Wrap(
                            spacing: AppTheme.spacingSmall,
                            runSpacing: AppTheme.spacingSmall,
                            children: ingredientNames.map((name) => Chip(
                              label: Text(
                                name,
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              side: BorderSide(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                final id = selectedIngredients.firstWhere(
                                  (id) => matchingService.ingredientById[id]?.name == name,
                                  orElse: () => '',
                                );
                                if (id.isNotEmpty) {
                                  ref.read(selectedIngredientsProvider.notifier).removeIngredient(id);
                                  ref.read(recipeResultsProvider.notifier).searchRecipes();
                                }
                              },
                            )).toList(),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          
          // Results
          Expanded(
            child: recipeResults.when(
              data: (results) {
                if (selectedIngredients.isEmpty) {
                  return _buildEmptyState(context, l10n, theme, isNoIngredients: true);
                }
                
                if (results.isEmpty) {
                  return _buildEmptyState(context, l10n, theme);
                }
                
                return _buildResultsList(results, ref);
              },
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(context, l10n, theme, error.toString()),
            ),
          ),
        ],
      ),
      floatingActionButton: selectedIngredients.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => ref.read(recipeResultsProvider.notifier).searchRecipes(),
              icon: const Icon(Icons.search),
              label: Text(l10n.findRecipes),
            )
          : null,
    );
  }

  Widget _buildResultsList(List<MatchResult> results, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
          child: RecipeCard(
            recipe: result.recipe,
            matchResult: result,
            onTap: () => _navigateToRecipeDetail(context, result.recipe),
            onFavoriteToggle: () => ref
                .read(favoriteRecipesProvider.notifier)
                .toggleFavorite(result.recipe.id),
            isFavorite: ref.watch(favoriteRecipesProvider).contains(result.recipe.id),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
          child: Shimmer.fromColors(
            baseColor: AppTheme.lightGray.withOpacity(0.3),
            highlightColor: AppTheme.lightGray.withOpacity(0.1),
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.mediumRadius,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme, {
    bool isNoIngredients = false,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNoIngredients ? Icons.kitchen : Icons.search_off,
              size: 80,
              color: AppTheme.mediumGray,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            Text(
              isNoIngredients 
                  ? 'Malzeme seçin'
                  : l10n.noRecipesFound,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              isNoIngredients
                  ? 'Tarif bulmak için önce malzemelerinizi seçin'
                  : 'Farklı malzemeler deneyin veya filtreleri değiştirin',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            ElevatedButton.icon(
              onPressed: isNoIngredients 
                  ? null  // Will be handled by navigation
                  : () => _showFilters(context),
              icon: Icon(isNoIngredients ? Icons.kitchen : Icons.tune),
              label: Text(isNoIngredients ? 'Malzeme Seç' : 'Filtreleri Değiştir'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    String error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            Text(
              l10n.error,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            ElevatedButton.icon(
              onPressed: () {
                // Retry search
                Consumer(
                  builder: (context, ref, _) {
                    ref.read(recipeResultsProvider.notifier).searchRecipes();
                    return const SizedBox.shrink();
                  },
                );
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveFilters(MatchFilters filters) {
    return filters.maxTimeMinutes != null ||
           filters.diet != null ||
           filters.excludedEquipment.isNotEmpty;
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  void _navigateToRecipeDetail(BuildContext context, Recipe recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipe: recipe),
      ),
    );
  }
}