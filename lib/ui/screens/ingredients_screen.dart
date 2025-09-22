import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme/app_theme.dart';
import '../../providers/app_providers.dart';

class IngredientsScreen extends ConsumerStatefulWidget {
  const IngredientsScreen({super.key});

  @override
  ConsumerState<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends ConsumerState<IngredientsScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';

  final List<String> _categories = [
    'Tümü',
    'Sebze',
    'Et',
    'Süt',
    'Tahıl',
    'Baklagil',
    'Yağ',
    'Baharat',
    'Yeşillik',
    'Meyve',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selectedIngredients = ref.watch(selectedIngredientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ingredients),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            icon: const Icon(Icons.clear),
                          )
                        : null,
                  ),
                ),
              ),
              
              // Category Tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: _categories.map((category) => Tab(text: category)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Selected Ingredients Summary
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
                  Row(
                    children: [
                      Text(
                        'Seçilen Malzemeler (${selectedIngredients.length})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          ref.read(selectedIngredientsProvider.notifier).clearIngredients();
                        },
                        child: const Text('Temizle'),
                      ),
                    ],
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

          // Ingredients List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                return _buildIngredientsGrid(category);
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: selectedIngredients.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () {
                ref.read(recipeResultsProvider.notifier).searchRecipes();
                // Navigate to results tab
                DefaultTabController.of(context)?.animateTo(1);
              },
              icon: const Icon(Icons.search),
              label: Text(l10n.findRecipes),
            )
          : null,
    );
  }

  Widget _buildIngredientsGrid(String category) {
    return Consumer(
      builder: (context, ref, _) {
        return ref.watch(matchingServiceProvider).when(
          data: (matchingService) {
            final allIngredients = matchingService.ingredientById.values.toList();
            final filteredIngredients = _filterIngredients(allIngredients, category);
            
            if (filteredIngredients.isEmpty) {
              return _buildEmptyState(category);
            }

            return GridView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: AppTheme.spacingMedium,
                mainAxisSpacing: AppTheme.spacingMedium,
              ),
              itemCount: filteredIngredients.length,
              itemBuilder: (context, index) {
                final ingredient = filteredIngredients[index];
                return _buildIngredientCard(ingredient, ref);
              },
            );
          },
          loading: () => _buildLoadingGrid(),
          error: (error, stack) => _buildErrorState(error.toString()),
        );
      },
    );
  }

  Widget _buildIngredientCard(Ingredient ingredient, WidgetRef ref) {
    final selectedIngredients = ref.watch(selectedIngredientsProvider);
    final isSelected = selectedIngredients.contains(ingredient.id);

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected 
          ? AppTheme.primaryColor.withOpacity(0.1)
          : null,
      child: InkWell(
        onTap: () {
          ref.read(selectedIngredientsProvider.notifier).toggleIngredient(ingredient.id);
          
          // Haptic feedback
          HapticFeedback.selectionClick();
        },
        borderRadius: AppTheme.mediumRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with selection indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ingredient.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppTheme.primaryColor : AppTheme.darkGray,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedContainer(
                    duration: AppTheme.shortAnimation,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : AppTheme.lightGray,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.spacingSmall),
              
              // Category
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getCategoryColor(ingredient.category).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ingredient.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getCategoryColor(ingredient.category),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Aliases
              if (ingredient.aliases.isNotEmpty) ...[
                Text(
                  'Diğer adları: ${ingredient.aliases.take(2).join(", ")}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.mediumGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: AppTheme.spacingMedium,
        mainAxisSpacing: AppTheme.spacingMedium,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppTheme.lightGray.withOpacity(0.3),
          highlightColor: AppTheme.lightGray.withOpacity(0.1),
          child: Card(
            child: Container(
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

  Widget _buildEmptyState(String category) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.mediumGray,
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            category == 'Tümü' 
                ? 'Arama kriterinizle eşleşen malzeme bulunamadı'
                : '$category kategorisinde malzeme bulunamadı',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.mediumGray,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            child: const Text('Aramayı Temizle'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorColor,
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Text(
            'Malzemeler yüklenirken hata oluştu',
            style: TextStyle(
              color: AppTheme.errorColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.mediumGray,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          ElevatedButton(
            onPressed: () {
              // Retry loading
              ref.invalidate(matchingServiceProvider);
            },
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  List<Ingredient> _filterIngredients(List<Ingredient> ingredients, String category) {
    var filtered = ingredients;
    
    // Filter by category
    if (category != 'Tümü') {
      filtered = filtered.where((ingredient) => ingredient.category == category).toList();
    }
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((ingredient) {
        return ingredient.name.toLowerCase().contains(_searchQuery) ||
               ingredient.aliases.any((alias) => alias.toLowerCase().contains(_searchQuery)) ||
               ingredient.category.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    
    // Sort alphabetically
    filtered.sort((a, b) => a.name.compareTo(b.name));
    
    return filtered;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'sebze':
        return AppTheme.successColor;
      case 'et':
        return AppTheme.errorColor;
      case 'süt':
        return Colors.blue;
      case 'tahıl':
        return AppTheme.warningColor;
      case 'baklagil':
        return Colors.brown;
      case 'yağ':
        return AppTheme.accentColor;
      case 'baharat':
        return Colors.deepOrange;
      case 'yeşillik':
        return Colors.green;
      case 'meyve':
        return Colors.pink;
      default:
        return AppTheme.mediumGray;
    }
  }
}

