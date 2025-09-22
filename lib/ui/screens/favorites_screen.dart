import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../widgets/recipe_card.dart';
import 'recipe_detail_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final favoriteIds = ref.watch(favoriteRecipesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favorites),
        actions: [
          if (favoriteIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () => _showClearAllDialog(context, ref),
            ),
        ],
      ),
      body: favoriteIds.isEmpty
          ? _buildEmptyState(context, l10n, theme)
          : Consumer(
              builder: (context, ref, _) {
                return ref.watch(matchingServiceProvider).when(
                  data: (matchingService) {
                    final favoriteRecipes = matchingService.recipes
                        .where((recipe) => favoriteIds.contains(recipe.id))
                        .toList();
                    
                    if (favoriteRecipes.isEmpty) {
                      return _buildEmptyState(context, l10n, theme);
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      itemCount: favoriteRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = favoriteRecipes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
                          child: RecipeCard(
                            recipe: recipe,
                            onTap: () => _navigateToRecipeDetail(context, recipe),
                            onFavoriteToggle: () => ref
                                .read(favoriteRecipesProvider.notifier)
                                .toggleFavorite(recipe.id),
                            isFavorite: true,
                            showFavoriteButton: true,
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _buildErrorState(context, l10n, theme, error.toString()),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite_border,
              size: 80,
              color: AppTheme.mediumGray,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            Text(
              'Henüz favori tarifiniz yok',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              'Beğendiğiniz tarifleri favorilerinize ekleyerek daha sonra kolayca bulabilirsiniz',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to ingredients tab
                DefaultTabController.of(context)?.animateTo(0);
              },
              icon: const Icon(Icons.search),
              label: const Text('Tarif Keşfet'),
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
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Favorileri Temizle'),
        content: const Text('Tüm favori tariflerinizi kaldırmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              // Clear all favorites
              final favoriteIds = ref.read(favoriteRecipesProvider);
              for (final id in favoriteIds) {
                ref.read(favoriteRecipesProvider.notifier).toggleFavorite(id);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
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