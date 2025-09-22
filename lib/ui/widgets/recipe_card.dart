import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../ui/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class RecipeCard extends StatefulWidget {
  final Recipe recipe;
  final MatchResult? matchResult;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;
  final bool showFavoriteButton;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.matchResult,
    this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
    this.showFavoriteButton = true,
  });

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.shortAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    
    return Semantics(
      label: 'Tarif: ${widget.recipe.name}',
      hint: 'Tarif detaylarını görmek için dokunun',
      button: true,
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: AppTheme.mediumRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe Image
                    _buildRecipeImage(context),
                    
                    // Recipe Content
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Favorite Button
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.recipe.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.showFavoriteButton) ...[
                                const SizedBox(width: AppTheme.spacingSmall),
                                Semantics(
                                  label: widget.isFavorite 
                                      ? 'Favorilerden çıkar' 
                                      : 'Favorilere ekle',
                                  button: true,
                                  child: IconButton(
                                    onPressed: widget.onFavoriteToggle,
                                    icon: Icon(
                                      widget.isFavorite 
                                          ? Icons.favorite 
                                          : Icons.favorite_border,
                                      color: widget.isFavorite 
                                          ? AppTheme.errorColor 
                                          : AppTheme.mediumGray,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          if (widget.recipe.description.isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spacingSmall),
                            Text(
                              widget.recipe.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.mediumGray,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          
                          const SizedBox(height: AppTheme.spacingMedium),
                          
                          // Recipe Info Row
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
                              _buildDifficultyChip(widget.recipe.difficulty),
                            ],
                          ),
                          
                          // Match Score (if available)
                          if (widget.matchResult != null) ...[
                            const SizedBox(height: AppTheme.spacingMedium),
                            _buildMatchScore(context, widget.matchResult!),
                          ],
                          
                          // Diet Tags
                          if (widget.recipe.dietTags.isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spacingSmall),
                            Wrap(
                              spacing: AppTheme.spacingSmall,
                              runSpacing: AppTheme.spacingSmall,
                              children: widget.recipe.dietTags.take(3).map(
                                (tag) => Chip(
                                  label: Text(
                                    _getDietTagText(tag, l10n),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  backgroundColor: AppTheme.successColor.withOpacity(0.1),
                                  side: BorderSide(
                                    color: AppTheme.successColor.withOpacity(0.3),
                                  ),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ).toList(),
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
        ),
      ),
    );
  }

  Widget _buildRecipeImage(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        gradient: AppTheme.primaryGradient,
      ),
      child: widget.recipe.imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                widget.recipe.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholderImage();
                },
              ),
            )
          : _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSmall,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyChip(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'kolay':
      case 'easy':
        color = AppTheme.successColor;
        break;
      case 'orta':
      case 'medium':
        color = AppTheme.warningColor;
        break;
      case 'zor':
      case 'hard':
        color = AppTheme.errorColor;
        break;
      default:
        color = AppTheme.mediumGray;
    }
    
    return _buildInfoChip(Icons.bar_chart, difficulty, color);
  }

  Widget _buildMatchScore(BuildContext context, MatchResult matchResult) {
    final theme = Theme.of(context);
    final scorePercentage = (matchResult.score / (matchResult.recipe.ingredients.length * 3)).clamp(0.0, 1.0);
    
    Color scoreColor;
    String scoreText;
    
    if (scorePercentage >= 0.8) {
      scoreColor = AppTheme.scoreGoodColor;
      scoreText = 'Mükemmel Eşleşme';
    } else if (scorePercentage >= 0.6) {
      scoreColor = AppTheme.scoreMediumColor;
      scoreText = 'İyi Eşleşme';
    } else {
      scoreColor = AppTheme.scorePoorColor;
      scoreText = 'Kısmi Eşleşme';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                scoreText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scoreColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${(scorePercentage * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scoreColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: scorePercentage,
          backgroundColor: scoreColor.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
          minHeight: 4,
        ),
        if (matchResult.missingIngredientIds.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            'Eksik: ${matchResult.missingIngredientIds.length} malzeme',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.mediumGray,
            ),
          ),
        ],
      ],
    );
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
}