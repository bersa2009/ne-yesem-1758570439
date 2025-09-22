import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  // App Title
  String get appTitle => _localizedValues[locale.languageCode]!['app_title']!;
  String get appSubtitle => _localizedValues[locale.languageCode]!['app_subtitle']!;

  // Navigation
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get recipes => _localizedValues[locale.languageCode]!['recipes']!;
  String get ingredients => _localizedValues[locale.languageCode]!['ingredients']!;
  String get favorites => _localizedValues[locale.languageCode]!['favorites']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;

  // Welcome Screen
  String get welcomeTitle => _localizedValues[locale.languageCode]!['welcome_title']!;
  String get welcomeSubtitle => _localizedValues[locale.languageCode]!['welcome_subtitle']!;
  String get getStarted => _localizedValues[locale.languageCode]!['get_started']!;
  String get addIngredients => _localizedValues[locale.languageCode]!['add_ingredients']!;

  // Ingredient Screen
  String get searchIngredients => _localizedValues[locale.languageCode]!['search_ingredients']!;
  String get searchHint => _localizedValues[locale.languageCode]!['search_hint']!;
  String get findRecipes => _localizedValues[locale.languageCode]!['find_recipes']!;
  String get noIngredientsSelected => _localizedValues[locale.languageCode]!['no_ingredients_selected']!;

  // Voice Input
  String get voiceInput => _localizedValues[locale.languageCode]!['voice_input']!;
  String get startListening => _localizedValues[locale.languageCode]!['start_listening']!;
  String get stopListening => _localizedValues[locale.languageCode]!['stop_listening']!;
  String get listening => _localizedValues[locale.languageCode]!['listening']!;
  String get voiceHint => _localizedValues[locale.languageCode]!['voice_hint']!;

  // Camera Input
  String get cameraInput => _localizedValues[locale.languageCode]!['camera_input']!;
  String get takePicture => _localizedValues[locale.languageCode]!['take_picture']!;
  String get scanBarcode => _localizedValues[locale.languageCode]!['scan_barcode']!;
  String get analyzing => _localizedValues[locale.languageCode]!['analyzing']!;

  // Recipe Results
  String get recipeResults => _localizedValues[locale.languageCode]!['recipe_results']!;
  String get noRecipesFound => _localizedValues[locale.languageCode]!['no_recipes_found']!;
  String get matchScore => _localizedValues[locale.languageCode]!['match_score']!;
  String get cookingTime => _localizedValues[locale.languageCode]!['cooking_time']!;
  String get servings => _localizedValues[locale.languageCode]!['servings']!;
  String get difficulty => _localizedValues[locale.languageCode]!['difficulty']!;

  // Recipe Detail
  String get ingredients_needed => _localizedValues[locale.languageCode]!['ingredients_needed']!;
  String get instructions => _localizedValues[locale.languageCode]!['instructions']!;
  String get missingIngredients => _localizedValues[locale.languageCode]!['missing_ingredients']!;
  String get equipment => _localizedValues[locale.languageCode]!['equipment']!;
  String get addToFavorites => _localizedValues[locale.languageCode]!['add_to_favorites']!;
  String get removeFromFavorites => _localizedValues[locale.languageCode]!['remove_from_favorites']!;
  String get startCooking => _localizedValues[locale.languageCode]!['start_cooking']!;

  // Filters
  String get filters => _localizedValues[locale.languageCode]!['filters']!;
  String get maxCookingTime => _localizedValues[locale.languageCode]!['max_cooking_time']!;
  String get dietaryPreferences => _localizedValues[locale.languageCode]!['dietary_preferences']!;
  String get excludeEquipment => _localizedValues[locale.languageCode]!['exclude_equipment']!;
  String get applyFilters => _localizedValues[locale.languageCode]!['apply_filters']!;
  String get clearFilters => _localizedValues[locale.languageCode]!['clear_filters']!;

  // Diet Tags
  String get vegetarian => _localizedValues[locale.languageCode]!['vegetarian']!;
  String get vegan => _localizedValues[locale.languageCode]!['vegan']!;
  String get glutenFree => _localizedValues[locale.languageCode]!['gluten_free']!;
  String get dairyFree => _localizedValues[locale.languageCode]!['dairy_free']!;
  String get lowCarb => _localizedValues[locale.languageCode]!['low_carb']!;
  String get healthy => _localizedValues[locale.languageCode]!['healthy']!;

  // Difficulty Levels
  String get easy => _localizedValues[locale.languageCode]!['easy']!;
  String get medium => _localizedValues[locale.languageCode]!['medium']!;
  String get hard => _localizedValues[locale.languageCode]!['hard']!;

  // Time Units
  String get minutes => _localizedValues[locale.languageCode]!['minutes']!;
  String get hours => _localizedValues[locale.languageCode]!['hours']!;
  String get person => _localizedValues[locale.languageCode]!['person']!;
  String get people => _localizedValues[locale.languageCode]!['people']!;

  // Actions
  String get ok => _localizedValues[locale.languageCode]!['ok']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get edit => _localizedValues[locale.languageCode]!['edit']!;
  String get share => _localizedValues[locale.languageCode]!['share']!;
  String get retry => _localizedValues[locale.languageCode]!['retry']!;

  // Error Messages
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get networkError => _localizedValues[locale.languageCode]!['network_error']!;
  String get permissionError => _localizedValues[locale.languageCode]!['permission_error']!;
  String get cameraError => _localizedValues[locale.languageCode]!['camera_error']!;
  String get microphoneError => _localizedValues[locale.languageCode]!['microphone_error']!;
  String get databaseError => _localizedValues[locale.languageCode]!['database_error']!;
  String get unknownError => _localizedValues[locale.languageCode]!['unknown_error']!;

  // Settings
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get theme => _localizedValues[locale.languageCode]!['theme']!;
  String get lightTheme => _localizedValues[locale.languageCode]!['light_theme']!;
  String get darkTheme => _localizedValues[locale.languageCode]!['dark_theme']!;
  String get systemTheme => _localizedValues[locale.languageCode]!['system_theme']!;
  String get notifications => _localizedValues[locale.languageCode]!['notifications']!;
  String get voice => _localizedValues[locale.languageCode]!['voice']!;
  String get camera => _localizedValues[locale.languageCode]!['camera']!;
  String get privacy => _localizedValues[locale.languageCode]!['privacy']!;
  String get about => _localizedValues[locale.languageCode]!['about']!;

  // Voice Commands
  String get voiceCommandHint => _localizedValues[locale.languageCode]!['voice_command_hint']!;
  String get voiceCommandExample1 => _localizedValues[locale.languageCode]!['voice_command_example1']!;
  String get voiceCommandExample2 => _localizedValues[locale.languageCode]!['voice_command_example2']!;
  String get voiceCommandExample3 => _localizedValues[locale.languageCode]!['voice_command_example3']!;

  // Assistant
  String get assistantWelcome => _localizedValues[locale.languageCode]!['assistant_welcome']!;
  String get assistantHelp => _localizedValues[locale.languageCode]!['assistant_help']!;
  String get assistantListening => _localizedValues[locale.languageCode]!['assistant_listening']!;

  static const Map<String, Map<String, String>> _localizedValues = {
    'tr': {
      // App Title
      'app_title': 'Ne Yesem?',
      'app_subtitle': 'Dolapta ne varsa, sofrada lezzet olsun!',

      // Navigation
      'home': 'Ana Sayfa',
      'recipes': 'Tarifler',
      'ingredients': 'Malzemeler',
      'favorites': 'Favoriler',
      'settings': 'Ayarlar',

      // Welcome Screen
      'welcome_title': 'Ne Yesem?',
      'welcome_subtitle': 'Dolapta ne varsa, sofrada lezzet olsun!',
      'get_started': 'Başla',
      'add_ingredients': 'Malzemelerini ekle',

      // Ingredient Screen
      'search_ingredients': 'Malzeme ara',
      'search_hint': 'Malzeme ara: örn. domates',
      'find_recipes': 'Tarif Bul',
      'no_ingredients_selected': 'Henüz malzeme seçilmedi',

      // Voice Input
      'voice_input': 'Sesli Giriş',
      'start_listening': 'Dinlemeye Başla',
      'stop_listening': 'Dinlemeyi Durdur',
      'listening': 'Dinliyorum...',
      'voice_hint': 'Malzemelerinizi söyleyebilirsiniz',

      // Camera Input
      'camera_input': 'Kamera ile Ekle',
      'take_picture': 'Fotoğraf Çek',
      'scan_barcode': 'Barkod Tara',
      'analyzing': 'Analiz ediliyor...',

      // Recipe Results
      'recipe_results': 'Tarif Sonuçları',
      'no_recipes_found': 'Bu malzemelerle tarif bulunamadı',
      'match_score': 'Uyum Skoru',
      'cooking_time': 'Pişirme Süresi',
      'servings': 'Porsiyon',
      'difficulty': 'Zorluk',

      // Recipe Detail
      'ingredients_needed': 'Gerekli Malzemeler',
      'instructions': 'Yapılış',
      'missing_ingredients': 'Eksik Malzemeler',
      'equipment': 'Gerekli Araçlar',
      'add_to_favorites': 'Favorilere Ekle',
      'remove_from_favorites': 'Favorilerden Çıkar',
      'start_cooking': 'Pişirmeye Başla',

      // Filters
      'filters': 'Filtreler',
      'max_cooking_time': 'Maksimum Pişirme Süresi',
      'dietary_preferences': 'Diyet Tercihleri',
      'exclude_equipment': 'Hariç Tutulacak Araçlar',
      'apply_filters': 'Filtreleri Uygula',
      'clear_filters': 'Filtreleri Temizle',

      // Diet Tags
      'vegetarian': 'Vejetaryen',
      'vegan': 'Vegan',
      'gluten_free': 'Glutensiz',
      'dairy_free': 'Sütsüz',
      'low_carb': 'Düşük Karbonhidrat',
      'healthy': 'Sağlıklı',

      // Difficulty Levels
      'easy': 'Kolay',
      'medium': 'Orta',
      'hard': 'Zor',

      // Time Units
      'minutes': 'dakika',
      'hours': 'saat',
      'person': 'kişi',
      'people': 'kişi',

      // Actions
      'ok': 'Tamam',
      'cancel': 'İptal',
      'save': 'Kaydet',
      'delete': 'Sil',
      'edit': 'Düzenle',
      'share': 'Paylaş',
      'retry': 'Tekrar Dene',

      // Error Messages
      'error': 'Hata',
      'network_error': 'İnternet bağlantınızı kontrol edin',
      'permission_error': 'İzin gerekli. Ayarlardan izin verin',
      'camera_error': 'Kamera erişimi için izin gerekli',
      'microphone_error': 'Mikrofon erişimi için izin gerekli',
      'database_error': 'Veri kaydedilirken sorun oluştu',
      'unknown_error': 'Bilinmeyen hata oluştu',

      // Settings
      'language': 'Dil',
      'theme': 'Tema',
      'light_theme': 'Açık Tema',
      'dark_theme': 'Koyu Tema',
      'system_theme': 'Sistem Teması',
      'notifications': 'Bildirimler',
      'voice': 'Ses',
      'camera': 'Kamera',
      'privacy': 'Gizlilik',
      'about': 'Hakkında',

      // Voice Commands
      'voice_command_hint': 'Sesli komutlar: "Malzemeler: domates, yumurta"',
      'voice_command_example1': 'Malzemeler: domates, yumurta, peynir',
      'voice_command_example2': 'Hızlı yemek istiyorum',
      'voice_command_example3': 'Vejetaryen tarif öner',

      // Assistant
      'assistant_welcome': 'Ne yapmak istiyorsunuz?',
      'assistant_help': 'Size nasıl yardımcı olabilirim?',
      'assistant_listening': 'Sizi dinliyorum...',
    },
    'en': {
      // App Title
      'app_title': 'What to Eat?',
      'app_subtitle': 'Turn your ingredients into delicious meals!',

      // Navigation
      'home': 'Home',
      'recipes': 'Recipes',
      'ingredients': 'Ingredients',
      'favorites': 'Favorites',
      'settings': 'Settings',

      // Welcome Screen
      'welcome_title': 'What to Eat?',
      'welcome_subtitle': 'Turn your ingredients into delicious meals!',
      'get_started': 'Get Started',
      'add_ingredients': 'Add your ingredients',

      // Ingredient Screen
      'search_ingredients': 'Search ingredients',
      'search_hint': 'Search ingredients: e.g. tomato',
      'find_recipes': 'Find Recipes',
      'no_ingredients_selected': 'No ingredients selected yet',

      // Voice Input
      'voice_input': 'Voice Input',
      'start_listening': 'Start Listening',
      'stop_listening': 'Stop Listening',
      'listening': 'Listening...',
      'voice_hint': 'You can say your ingredients',

      // Camera Input
      'camera_input': 'Camera Input',
      'take_picture': 'Take Picture',
      'scan_barcode': 'Scan Barcode',
      'analyzing': 'Analyzing...',

      // Recipe Results
      'recipe_results': 'Recipe Results',
      'no_recipes_found': 'No recipes found with these ingredients',
      'match_score': 'Match Score',
      'cooking_time': 'Cooking Time',
      'servings': 'Servings',
      'difficulty': 'Difficulty',

      // Recipe Detail
      'ingredients_needed': 'Ingredients Needed',
      'instructions': 'Instructions',
      'missing_ingredients': 'Missing Ingredients',
      'equipment': 'Required Equipment',
      'add_to_favorites': 'Add to Favorites',
      'remove_from_favorites': 'Remove from Favorites',
      'start_cooking': 'Start Cooking',

      // Filters
      'filters': 'Filters',
      'max_cooking_time': 'Maximum Cooking Time',
      'dietary_preferences': 'Dietary Preferences',
      'exclude_equipment': 'Exclude Equipment',
      'apply_filters': 'Apply Filters',
      'clear_filters': 'Clear Filters',

      // Diet Tags
      'vegetarian': 'Vegetarian',
      'vegan': 'Vegan',
      'gluten_free': 'Gluten Free',
      'dairy_free': 'Dairy Free',
      'low_carb': 'Low Carb',
      'healthy': 'Healthy',

      // Difficulty Levels
      'easy': 'Easy',
      'medium': 'Medium',
      'hard': 'Hard',

      // Time Units
      'minutes': 'minutes',
      'hours': 'hours',
      'person': 'person',
      'people': 'people',

      // Actions
      'ok': 'OK',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'share': 'Share',
      'retry': 'Retry',

      // Error Messages
      'error': 'Error',
      'network_error': 'Check your internet connection',
      'permission_error': 'Permission required. Grant permission in settings',
      'camera_error': 'Camera access permission required',
      'microphone_error': 'Microphone access permission required',
      'database_error': 'Problem occurred while saving data',
      'unknown_error': 'Unknown error occurred',

      // Settings
      'language': 'Language',
      'theme': 'Theme',
      'light_theme': 'Light Theme',
      'dark_theme': 'Dark Theme',
      'system_theme': 'System Theme',
      'notifications': 'Notifications',
      'voice': 'Voice',
      'camera': 'Camera',
      'privacy': 'Privacy',
      'about': 'About',

      // Voice Commands
      'voice_command_hint': 'Voice commands: "Ingredients: tomato, egg"',
      'voice_command_example1': 'Ingredients: tomato, egg, cheese',
      'voice_command_example2': 'I want quick food',
      'voice_command_example3': 'Suggest vegetarian recipe',

      // Assistant
      'assistant_welcome': 'What would you like to do?',
      'assistant_help': 'How can I help you?',
      'assistant_listening': 'I\'m listening...',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['tr', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}