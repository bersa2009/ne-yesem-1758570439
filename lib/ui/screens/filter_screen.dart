import 'package:flutter/material.dart';
import '../../models/models.dart';

class FilterScreen extends StatefulWidget {
  final MatchFilters initialFilters;

  const FilterScreen({super.key, required this.initialFilters});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late MatchFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtreler'),
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text('Sıfırla'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tarif arama filtreleri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Time Filter
            _buildFilterSection(
              title: 'Maksimum Süre',
              child: Column(
                children: [
                  Slider(
                    value: _filters.maxTimeMinutes?.toDouble() ?? 120.0,
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: '${(_filters.maxTimeMinutes ?? 120)} dk',
                    onChanged: (value) {
                      setState(() {
                        _filters = MatchFilters(
                          maxTimeMinutes: value.round(),
                          diet: _filters.diet,
                          excludedEquipment: _filters.excludedEquipment,
                        );
                      });
                    },
                  ),
                  Text('${(_filters.maxTimeMinutes ?? 120)} dakika'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Diet Filter
            _buildFilterSection(
              title: 'Diyet Tercihi',
              child: DropdownButtonFormField<String?>(
                value: _filters.diet,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                hint: const Text('Tümü'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tümü')),
                  const DropdownMenuItem(value: 'vejetaryen', child: Text('Vejetaryen')),
                  const DropdownMenuItem(value: 'vegan', child: Text('Vegan')),
                  const DropdownMenuItem(value: 'glutensiz', child: Text('Glutensiz')),
                  const DropdownMenuItem(value: 'düşük_karbonhidrat', child: Text('Düşük Karbonhidrat')),
                ],
                onChanged: (value) {
                  setState(() {
                    _filters = MatchFilters(
                      maxTimeMinutes: _filters.maxTimeMinutes,
                      diet: value,
                      excludedEquipment: _filters.excludedEquipment,
                    );
                  });
                },
              ),
            ),

            const SizedBox(height: 24),

            // Equipment Filter
            _buildFilterSection(
              title: 'Hariç Tutulacak Ekipmanlar',
              child: Column(
                children: [
                  const Text('Aşağıdaki ekipmanları gerektiren tarifleri hariç tut'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      'fırın',
                      'mikrodalga',
                      'blender',
                      'mutfak robotu',
                      'ızgara',
                    ].map((equipment) {
                      final isExcluded = _filters.excludedEquipment.contains(equipment);
                      return FilterChip(
                        label: Text(equipment),
                        selected: isExcluded,
                        onSelected: (selected) {
                          setState(() {
                            final currentExcluded = List<String>.from(_filters.excludedEquipment);
                            if (selected) {
                              currentExcluded.add(equipment);
                            } else {
                              currentExcluded.remove(equipment);
                            }
                            _filters = MatchFilters(
                              maxTimeMinutes: _filters.maxTimeMinutes,
                              diet: _filters.diet,
                              excludedEquipment: currentExcluded,
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(_filters);
                },
                child: const Text('Filtreleri Uygula'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  void _resetFilters() {
    setState(() {
      _filters = const MatchFilters();
    });
  }
}