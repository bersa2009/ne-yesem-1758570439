# 🍽️ Ne Yesem? - Smart Recipe Finder

**"Dolapta ne varsa, sofrada lezzet olsun!"**

Ne Yesem? is a comprehensive Flutter mobile application that helps users find recipes based on available ingredients using voice commands, camera scanning, and intelligent matching algorithms.

## ✨ Features

### 🗣️ Voice-First Experience
- **Speech Recognition**: Turkish and English voice commands
- **Natural Language**: "Malzemeler: domates, yumurta, peynir"
- **Voice Assistant**: Custom Siri-like assistant
- **Text-to-Speech**: Audio feedback and recipe reading

### 📸 Smart Camera Integration
- **Ingredient Recognition**: AI-powered ingredient detection
- **Barcode Scanning**: Product identification
- **Real-time Analysis**: Instant ingredient detection

### 🔍 Intelligent Recipe Matching
- **Advanced Algorithm**: Smart scoring system
- **Ingredient Substitutions**: Automatic replacements
- **Smart Filters**: Time, diet, equipment preferences
- **Performance Optimized**: Sub-3-second matching

### 💾 Offline-First Architecture
- **SQLite Database**: Complete offline functionality
- **Data Sync**: Smart synchronization
- **GDPR Compliant**: Privacy-first design

### 🎨 Modern UI/UX
- **Material Design 3**: Beautiful, accessible interface
- **Dark/Light Theme**: System-adaptive theming
- **Animations**: Smooth micro-interactions
- **Responsive**: Works on all screen sizes

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.4.0+
- Dart 3.0+
- Android Studio / Xcode
- Android API 21+ / iOS 12.0+

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ne_yesem
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Build for Production

**Android:**
```bash
flutter build apk --release
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ipa --release
```

## 📱 App Structure

### Main Screens
- **Splash Screen**: Animated app introduction
- **Welcome Screen**: Feature showcase and onboarding
- **Ingredients Screen**: Voice/camera/manual ingredient selection
- **Recipe Results**: Smart recipe matching with scores
- **Recipe Detail**: Step-by-step cooking instructions
- **Favorites**: Saved recipes management
- **Settings**: App configuration and preferences

### Voice Commands
- `"Malzemeler: domates, yumurta, peynir"` - Add ingredients
- `"Hızlı yemek istiyorum"` - Quick recipes (15 min)
- `"Vejetaryen tarif öner"` - Vegetarian recipes
- `"Tarif öner"` - General recipe suggestions

## 🍽️ Recipe Database

### 15 Traditional Turkish Recipes
- Menemen, Mercimek Çorbası, Karnıyarık
- Domatesli Makarna, Pirinç Pilavı, Çoban Salatası
- Tavuk Sote, Bulgur Pilavı, Peynirli Omlet
- Sucuklu Yumurta, Patates Kızartması, Yoğurtlu Kebap
- Lahmacun, Köfte, Mantı

### 46 Ingredients with Categories
- **Vegetables**: Tomato, Onion, Potato, Eggplant, etc.
- **Proteins**: Eggs, Meat, Chicken, etc.
- **Dairy**: Cheese, Yogurt, Milk, Butter, etc.
- **Grains**: Pasta, Rice, Bulgur, Flour, etc.
- **Legumes**: Lentils, Chickpeas, Beans, etc.

## 🏗️ Architecture

### Technologies Used
- **Flutter 3.x**: Cross-platform framework
- **Riverpod**: State management
- **SQLite**: Local database
- **Speech-to-Text**: Voice recognition
- **Camera**: Image processing
- **Material Design 3**: UI framework

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── app.dart                  # App configuration
├── models/                   # Data models
├── services/                 # Business logic
├── providers/                # State management
├── ui/                       # User interface
│   ├── screens/             # App screens
│   ├── widgets/             # Reusable widgets
│   ├── theme/               # Design system
│   └── splash/              # Splash screen
└── l10n/                    # Localization
```

## 🔧 Development

### Running Tests
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

### Generate Assets
```bash
flutter packages pub run build_runner build
```

## 📊 Performance

### Target Metrics
- **App Startup**: < 2 seconds
- **Recipe Matching**: < 3 seconds for 100 ingredients
- **Voice Recognition**: < 1 second response
- **Camera Analysis**: < 5 seconds
- **Memory Usage**: < 100MB average
- **Crash Rate**: < 1%

## 🔒 Privacy & Security

### Data Protection
- **Local-First**: Data stays on device
- **Encryption**: Sensitive data encrypted
- **GDPR Compliant**: Right to deletion
- **No Tracking**: Privacy-focused design

### Permissions
- **Camera**: Ingredient scanning
- **Microphone**: Voice commands
- **Storage**: Recipe caching

## 🌍 Localization

### Supported Languages
- **Turkish (tr)**: Primary language
- **English (en)**: Secondary language

## 📄 License

This project is licensed under the MIT License.

---

**Made with ❤️ for Turkish cuisine lovers**