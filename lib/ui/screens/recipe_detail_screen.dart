import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme/app_theme.dart';
import '../../providers/app_providers.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
  });

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentStep = 0;
  bool _isCookingMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isFavorite = ref.watch(favoriteRecipesProvider).contains(widget.recipe.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.recipe.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: _buildRecipeImage(),
            ),
            actions: [
              IconButton(
                onPressed: () => ref
                    .read(favoriteRecipesProvider.notifier)
                    .toggleFavorite(widget.recipe.id),
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? AppTheme.errorColor : Colors.white,
                ),
              ),
              IconButton(
                onPressed: _shareRecipe,
                icon: const Icon(Icons.share, color: Colors.white),
              ),
            ],
          ),

          // Recipe Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Info Row
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.access_time,
                        '${widget.recipe.timeMin} ${l10n.minutes}',
                        AppTheme.primaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      _buildInfoChip(
                        Icons.people,
                        '${widget.recipe.servings} ${widget.recipe.servings == 1 ? l10n.person : l10n.people}',
                        AppTheme.secondaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      _buildDifficultyChip(widget.recipe.difficulty, l10n),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingLarge),

                  // Description
                  if (widget.recipe.description.isNotEmpty) ...[
                    Text(
                      widget.recipe.description,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                  ],

                  // Diet Tags
                  if (widget.recipe.dietTags.isNotEmpty) ...[
                    Wrap(
                      spacing: AppTheme.spacingSmall,
                      runSpacing: AppTheme.spacingSmall,
                      children: widget.recipe.dietTags.map(
                        (tag) => Chip(
                          label: Text(_getDietTagText(tag, l10n)),
                          backgroundColor: AppTheme.successColor.withOpacity(0.1),
                          side: BorderSide(
                            color: AppTheme.successColor.withOpacity(0.3),
                          ),
                        ),
                      ).toList(),
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                  ],

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleCookingMode,
                          icon: Icon(_isCookingMode ? Icons.pause : Icons.play_arrow),
                          label: Text(_isCookingMode ? 'Duraklat' : l10n.startCooking),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCookingMode 
                                ? AppTheme.warningColor 
                                : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMedium),
                      OutlinedButton.icon(
                        onPressed: _addToShoppingList,
                        icon: const Icon(Icons.shopping_cart),
                        label: const Text('Alışveriş'),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppTheme.spacingLarge),
                ],
              ),
            ),
          ),

          // Tab Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: l10n.ingredients_needed),
                  Tab(text: l10n.instructions),
                  Tab(text: l10n.equipment),
                ],
              ),
            ),
          ),

          // Tab Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildIngredientsTab(l10n),
                _buildInstructionsTab(l10n),
                _buildEquipmentTab(l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: widget.recipe.imageUrl.isNotEmpty
          ? Image.network(
              widget.recipe.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return _buildPlaceholderImage();
              },
            )
          : _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return const Center(
      child: Icon(
        Icons.restaurant,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty, AppLocalizations l10n) {
    Color color;
    String displayText;
    
    switch (difficulty.toLowerCase()) {
      case 'kolay':
      case 'easy':
        color = AppTheme.successColor;
        displayText = l10n.easy;
        break;
      case 'orta':
      case 'medium':
        color = AppTheme.warningColor;
        displayText = l10n.medium;
        break;
      case 'zor':
      case 'hard':
        color = AppTheme.errorColor;
        displayText = l10n.hard;
        break;
      default:
        color = AppTheme.mediumGray;
        displayText = difficulty;
    }
    
    return _buildInfoChip(Icons.bar_chart, displayText, color);
  }

  Widget _buildIngredientsTab(AppLocalizations l10n) {
    return Consumer(
      builder: (context, ref, _) {
        return ref.watch(matchingServiceProvider).when(
          data: (matchingService) {
            final selectedIngredients = ref.watch(selectedIngredientsProvider);
            
            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              itemCount: widget.recipe.ingredients.length,
              itemBuilder: (context, index) {
                final ingredient = widget.recipe.ingredients[index];
                final ingredientData = matchingService.ingredientById[ingredient.ingredientId];
                final hasIngredient = selectedIngredients.contains(ingredient.ingredientId);
                
                return Card(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: hasIngredient 
                          ? AppTheme.successColor.withOpacity(0.2)
                          : AppTheme.errorColor.withOpacity(0.2),
                      child: Icon(
                        hasIngredient ? Icons.check : Icons.close,
                        color: hasIngredient ? AppTheme.successColor : AppTheme.errorColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      ingredientData?.name ?? ingredient.ingredientId,
                      style: TextStyle(
                        decoration: hasIngredient ? TextDecoration.lineThrough : null,
                        color: hasIngredient ? AppTheme.mediumGray : null,
                      ),
                    ),
                    subtitle: Text(
                      '${ingredient.quantity} ${ingredient.unit}${ingredient.optional ? ' (opsiyonel)' : ''}',
                      style: TextStyle(
                        color: hasIngredient ? AppTheme.mediumGray : AppTheme.darkGray,
                      ),
                    ),
                    trailing: ingredient.optional 
                        ? Chip(
                            label: const Text('Opsiyonel', style: TextStyle(fontSize: 10)),
                            backgroundColor: AppTheme.warningColor.withOpacity(0.1),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          )
                        : null,
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Hata: $error')),
        );
      },
    );
  }

  Widget _buildInstructionsTab(AppLocalizations l10n) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      itemCount: widget.recipe.steps.length,
      itemBuilder: (context, index) {
        final step = widget.recipe.steps[index];
        final isCurrentStep = _isCookingMode && index == _currentStep;
        final isCompleted = _isCookingMode && index < _currentStep;
        
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
          elevation: isCurrentStep ? 4 : 1,
          color: isCurrentStep 
              ? AppTheme.primaryColor.withOpacity(0.1)
              : isCompleted 
                  ? AppTheme.successColor.withOpacity(0.1)
                  : null,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step Number
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted 
                        ? AppTheme.successColor
                        : isCurrentStep 
                            ? AppTheme.primaryColor
                            : AppTheme.lightGray,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isCurrentStep ? Colors.white : AppTheme.darkGray,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(width: AppTheme.spacingMedium),
                
                // Step Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isCurrentStep ? FontWeight.w600 : FontWeight.normal,
                          color: isCompleted ? AppTheme.mediumGray : AppTheme.darkGray,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      
                      if (_isCookingMode && isCurrentStep) ...[
                        const SizedBox(height: AppTheme.spacingMedium),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _nextStep,
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Tamamlandı'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingSmall),
                            IconButton(
                              onPressed: _speakStep,
                              icon: const Icon(Icons.volume_up),
                              tooltip: 'Adımı oku',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEquipmentTab(AppLocalizations l10n) {
    if (widget.recipe.equipment.isEmpty) {
      return const Center(
        child: Text('Bu tarif için özel ekipman gerekmiyor'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      itemCount: widget.recipe.equipment.length,
      itemBuilder: (context, index) {
        final equipment = widget.recipe.equipment[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                _getEquipmentIcon(equipment),
                color: AppTheme.primaryColor,
              ),
            ),
            title: Text(_getEquipmentDisplayName(equipment)),
            subtitle: Text(_getEquipmentDescription(equipment)),
          ),
        );
      },
    );
  }

  IconData _getEquipmentIcon(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'tencere':
        return Icons.soup_kitchen;
      case 'tava':
        return Icons.skillet;
      case 'fırın':
        return Icons.local_fire_department;
      case 'blender':
        return Icons.blender;
      case 'ızgara':
        return Icons.outdoor_grill;
      case 'oklava':
        return Icons.architecture;
      default:
        return Icons.kitchen;
    }
  }

  String _getEquipmentDisplayName(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'tencere':
        return 'Tencere';
      case 'tava':
        return 'Tava';
      case 'fırın':
        return 'Fırın';
      case 'blender':
        return 'Blender';
      case 'ızgara':
        return 'Izgara';
      case 'oklava':
        return 'Oklava';
      default:
        return equipment;
    }
  }

  String _getEquipmentDescription(String equipment) {
    switch (equipment.toLowerCase()) {
      case 'tencere':
        return 'Orta boy tencere yeterli';
      case 'tava':
        return 'Yapışmaz tava önerilir';
      case 'fırın':
        return '180°C önceden ısıtın';
      case 'blender':
        return 'El blenderi de kullanılabilir';
      case 'ızgara':
        return 'Tava da alternatif olabilir';
      case 'oklava':
        return 'Hamur açmak için';
      default:
        return 'Mutfak ekipmanı';
    }
  }

  String _getDietTagText(String tag, AppLocalizations l10n) {
    switch (tag.toLowerCase()) {
      case 'vejetaryen':
      case 'vegetarian':
        return l10n.vegetarian;
      case 'vegan':
        return l10n.vegan;
      case 'glutensiz':
      case 'gluten_free':
        return l10n.glutenFree;
      case 'sütsüz':
      case 'dairy_free':
        return l10n.dairyFree;
      case 'düşük_karbonhidrat':
      case 'low_carb':
        return l10n.lowCarb;
      case 'sağlıklı':
      case 'healthy':
        return l10n.healthy;
      default:
        return tag;
    }
  }

  void _toggleCookingMode() {
    setState(() {
      _isCookingMode = !_isCookingMode;
      if (_isCookingMode) {
        _currentStep = 0;
        _tabController.animateTo(1); // Switch to instructions tab
      }
    });
  }

  void _nextStep() {
    if (_currentStep < widget.recipe.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Recipe completed
      _completeRecipe();
    }
  }

  void _completeRecipe() {
    setState(() {
      _isCookingMode = false;
      _currentStep = 0;
    });

    // Mark recipe as cooked
    ref.read(databaseServiceProvider).markRecipeAsCooked(widget.recipe.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.recipe.name} tarifi tamamlandı! Afiyet olsun 🎉'),
        backgroundColor: AppTheme.successColor,
        action: SnackBarAction(
          label: 'Değerlendir',
          onPressed: _showRatingDialog,
        ),
      ),
    );
  }

  void _speakStep() {
    final voiceService = ref.read(voiceServiceProvider);
    final currentStepText = widget.recipe.steps[_currentStep];
    voiceService.speak('Adım ${_currentStep + 1}: $currentStepText');
  }

  void _shareRecipe() {
    final recipeText = '''
${widget.recipe.name}

${widget.recipe.description}

Süre: ${widget.recipe.timeMin} dakika
Porsiyon: ${widget.recipe.servings} kişi
Zorluk: ${widget.recipe.difficulty}

Malzemeler:
${widget.recipe.ingredients.map((ing) => '• ${ing.quantity} ${ing.unit} ${ing.ingredientId}').join('\n')}

Yapılışı:
${widget.recipe.steps.asMap().entries.map((entry) => '${entry.key + 1}. ${entry.value}').join('\n')}

Ne Yesem? uygulaması ile paylaşıldı.
''';

    // In a real app, you would use share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tarif panoya kopyalandı')),
    );
  }

  void _addToShoppingList() {
    // Add missing ingredients to shopping list
    final selectedIngredients = ref.read(selectedIngredientsProvider);
    final missingIngredients = widget.recipe.ingredients
        .where((ing) => !selectedIngredients.contains(ing.ingredientId))
        .toList();

    if (missingIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm malzemeleriniz mevcut!')),
      );
      return;
    }

    // In a real app, you would add to a shopping list
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${missingIngredients.length} malzeme alışveriş listesine eklendi'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tarifi Değerlendirin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Bu tarifi nasıl buldunuz?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${index + 1} yıldız verdiniz. Teşekkürler!'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  },
                  icon: const Icon(Icons.star_border),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}