import 'package:flutter_riverpod/flutter_riverpod.dart';

// Navigation provider for managing bottom navigation state
final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((ref) {
  return NavigationNotifier();
});

class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0);

  void setIndex(int index) {
    state = index;
  }

  void goToIngredients() => setIndex(0);
  void goToResults() => setIndex(1);
  void goToFavorites() => setIndex(2);
  void goToSettings() => setIndex(3);
}