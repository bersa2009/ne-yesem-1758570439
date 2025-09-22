import 'package:flutter/material.dart';
import '../../models/models.dart';

class FilterDialog extends StatefulWidget {
  final MatchFilters initialFilters;
  final Function(MatchFilters) onFiltersChanged;

  const FilterDialog({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late int? maxTimeMinutes;
  late int? minServings;
  late int? maxServings;
  late String? selectedDiet;
  late String? selectedDifficulty;
  late Set<String> excludedEquipment;

  final List<String> dietOptions = [
    'Vejetaryen',
    'Vegan',
    'Glutensiz',
    'Laktoz Intoleransı',
    'Keto',
    'Paleo',
  ];

  final List<String> difficultyOptions = [
    'Kolay',
    'Orta',
    'Zor',
  ];

  final List<String> equipmentOptions = [
    'Fırın',
    'Ocak',
    'Mikser',
    'Blender',
    'Robot',
    'Tencere',
    'Tava',
    'Izgara',
  ];

  @override
  void initState() {
    super.initState();
    maxTimeMinutes = widget.initialFilters.maxTimeMinutes;
    minServings = widget.initialFilters.minServings;
    maxServings = widget.initialFilters.maxServings;
    selectedDiet = widget.initialFilters.diet;
    selectedDifficulty = widget.initialFilters.difficulty;
    excludedEquipment = Set.from(widget.initialFilters.excludedEquipment);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filtreler'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Time filter
            Text('Maksimum Süre (dakika)', style: Theme.of(context).textTheme.titleSmall),
            Slider(
              value: (maxTimeMinutes ?? 120).toDouble(),
              min: 5,
              max: 120,
              divisions: 23,
              label: maxTimeMinutes != null ? '$maxTimeMinutes dk' : 'Sınır yok',
              onChanged: (value) {
                setState(() {
                  maxTimeMinutes = value.round();
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      maxTimeMinutes = null;
                    });
                  },
                  child: const Text('Sınır yok'),
                ),
                Text(maxTimeMinutes != null ? '$maxTimeMinutes dk' : 'Sınır yok'),
              ],
            ),
            const SizedBox(height: 16),

            // Servings filter
            Text('Porsiyon Sayısı', style: Theme.of(context).textTheme.titleSmall),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Min:'),
                      Slider(
                        value: (minServings ?? 1).toDouble(),
                        min: 1,
                        max: 12,
                        divisions: 11,
                        label: '${minServings ?? 1}',
                        onChanged: (value) {
                          setState(() {
                            minServings = value.round();
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Max:'),
                      Slider(
                        value: (maxServings ?? 8).toDouble(),
                        min: 1,
                        max: 12,
                        divisions: 11,
                        label: '${maxServings ?? 8}',
                        onChanged: (value) {
                          setState(() {
                            maxServings = value.round();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Diet filter
            Text('Diyet Türü', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Hepsi'),
                  selected: selectedDiet == null,
                  onSelected: (selected) {
                    setState(() {
                      selectedDiet = null;
                    });
                  },
                ),
                ...dietOptions.map((diet) => FilterChip(
                  label: Text(diet),
                  selected: selectedDiet == diet,
                  onSelected: (selected) {
                    setState(() {
                      selectedDiet = selected ? diet : null;
                    });
                  },
                )),
              ],
            ),
            const SizedBox(height: 16),

            // Difficulty filter
            Text('Zorluk Seviyesi', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Hepsi'),
                  selected: selectedDifficulty == null,
                  onSelected: (selected) {
                    setState(() {
                      selectedDifficulty = null;
                    });
                  },
                ),
                ...difficultyOptions.map((difficulty) => FilterChip(
                  label: Text(difficulty),
                  selected: selectedDifficulty == difficulty,
                  onSelected: (selected) {
                    setState(() {
                      selectedDifficulty = selected ? difficulty : null;
                    });
                  },
                )),
              ],
            ),
            const SizedBox(height: 16),

            // Equipment exclusion filter
            Text('Kullanmak İstemediğim Ekipmanlar', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: equipmentOptions.map((equipment) => FilterChip(
                label: Text(equipment),
                selected: excludedEquipment.contains(equipment),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      excludedEquipment.add(equipment);
                    } else {
                      excludedEquipment.remove(equipment);
                    }
                  });
                },
              )).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Reset filters
            setState(() {
              maxTimeMinutes = null;
              minServings = null;
              maxServings = null;
              selectedDiet = null;
              selectedDifficulty = null;
              excludedEquipment.clear();
            });
          },
          child: const Text('Sıfırla'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            final filters = MatchFilters(
              maxTimeMinutes: maxTimeMinutes,
              minServings: minServings,
              maxServings: maxServings,
              diet: selectedDiet,
              difficulty: selectedDifficulty,
              excludedEquipment: excludedEquipment.toList(),
            );
            widget.onFiltersChanged(filters);
            Navigator.of(context).pop();
          },
          child: const Text('Uygula'),
        ),
      ],
    );
  }
}