import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../../models/models.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  late MatchFilters _currentFilters;
  int? _maxTime;
  String? _selectedDiet;
  List<String> _excludedEquipment = [];

  final List<int> _timeOptions = [15, 30, 45, 60, 90, 120];
  final List<String> _dietOptions = [
    'vejetaryen',
    'vegan',
    'glutensiz',
    'sütsüz',
    'düşük_karbonhidrat',
    'sağlıklı',
  ];
  final List<String> _equipmentOptions = [
    'fırın',
    'mikrodalga',
    'blender',
    'robot',
    'mangal',
    'buharlama_sepeti',
    'pressure_cooker',
  ];

  @override
  void initState() {
    super.initState();
    _currentFilters = ref.read(searchFiltersProvider);
    _maxTime = _currentFilters.maxTimeMinutes;
    _selectedDiet = _currentFilters.diet;
    _excludedEquipment = List.from(_currentFilters.excludedEquipment);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
            child: Row(
              children: [
                Text(
                  l10n.filters,
                  style: theme.textTheme.headlineMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: Text(l10n.clearFilters),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Max Cooking Time
                  _buildSectionTitle(l10n.maxCookingTime),
                  const SizedBox(height: AppTheme.spacingMedium),
                  _buildTimeSelector(),
                  
                  const SizedBox(height: AppTheme.spacingLarge),
                  
                  // Dietary Preferences
                  _buildSectionTitle(l10n.dietaryPreferences),
                  const SizedBox(height: AppTheme.spacingMedium),
                  _buildDietSelector(l10n),
                  
                  const SizedBox(height: AppTheme.spacingLarge),
                  
                  // Exclude Equipment
                  _buildSectionTitle(l10n.excludeEquipment),
                  const SizedBox(height: AppTheme.spacingMedium),
                  _buildEquipmentSelector(),
                ],
              ),
            ),
          ),
          
          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            decoration: BoxDecoration(
              color: AppTheme.veryLightGray,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: Text(l10n.applyFilters),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.darkGray,
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _maxTime != null ? '${_maxTime!} dakika' : 'Zaman sınırı yok',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            if (_maxTime != null)
              IconButton(
                onPressed: () => setState(() => _maxTime = null),
                icon: const Icon(Icons.clear, size: 20),
              ),
          ],
        ),
        if (_maxTime != null) ...[
          const SizedBox(height: AppTheme.spacingSmall),
          Slider(
            value: _maxTime!.toDouble(),
            min: 5,
            max: 180,
            divisions: 35,
            label: '${_maxTime!} dakika',
            onChanged: (value) => setState(() => _maxTime = value.round()),
          ),
        ],
        const SizedBox(height: AppTheme.spacingMedium),
        Wrap(
          spacing: AppTheme.spacingSmall,
          runSpacing: AppTheme.spacingSmall,
          children: _timeOptions.map((time) {
            final isSelected = _maxTime == time;
            return FilterChip(
              label: Text('${time}dk'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _maxTime = selected ? time : null;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDietSelector(AppLocalizations l10n) {
    return Wrap(
      spacing: AppTheme.spacingSmall,
      runSpacing: AppTheme.spacingSmall,
      children: _dietOptions.map((diet) {
        final isSelected = _selectedDiet == diet;
        return FilterChip(
          label: Text(_getDietDisplayName(diet, l10n)),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedDiet = selected ? diet : null;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildEquipmentSelector() {
    return Wrap(
      spacing: AppTheme.spacingSmall,
      runSpacing: AppTheme.spacingSmall,
      children: _equipmentOptions.map((equipment) {
        final isExcluded = _excludedEquipment.contains(equipment);
        return FilterChip(
          label: Text(_getEquipmentDisplayName(equipment)),
          selected: isExcluded,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _excludedEquipment.add(equipment);
              } else {
                _excludedEquipment.remove(equipment);
              }
            });
          },
          selectedColor: AppTheme.errorColor.withOpacity(0.2),
          checkmarkColor: AppTheme.errorColor,
        );
      }).toList(),
    );
  }

  String _getDietDisplayName(String diet, AppLocalizations l10n) {
    switch (diet) {
      case 'vejetaryen':
        return l10n.vegetarian;
      case 'vegan':
        return l10n.vegan;
      case 'glutensiz':
        return l10n.glutenFree;
      case 'sütsüz':
        return l10n.dairyFree;
      case 'düşük_karbonhidrat':
        return l10n.lowCarb;
      case 'sağlıklı':
        return l10n.healthy;
      default:
        return diet;
    }
  }

  String _getEquipmentDisplayName(String equipment) {
    switch (equipment) {
      case 'fırın':
        return 'Fırın';
      case 'mikrodalga':
        return 'Mikrodalga';
      case 'blender':
        return 'Blender';
      case 'robot':
        return 'Mutfak Robotu';
      case 'mangal':
        return 'Mangal';
      case 'buharlama_sepeti':
        return 'Buharlama Sepeti';
      case 'pressure_cooker':
        return 'Düdüklü Tencere';
      default:
        return equipment;
    }
  }

  void _clearAllFilters() {
    setState(() {
      _maxTime = null;
      _selectedDiet = null;
      _excludedEquipment.clear();
    });
  }

  void _applyFilters() {
    final newFilters = MatchFilters(
      maxTimeMinutes: _maxTime,
      diet: _selectedDiet,
      excludedEquipment: _excludedEquipment,
    );
    
    ref.read(searchFiltersProvider.notifier).setMaxTime(_maxTime);
    ref.read(searchFiltersProvider.notifier).setDiet(_selectedDiet);
    ref.read(searchFiltersProvider.notifier).setExcludedEquipment(_excludedEquipment);
    
    // Trigger new search with updated filters
    ref.read(recipeResultsProvider.notifier).searchRecipes();
    
    Navigator.of(context).pop();
  }
}