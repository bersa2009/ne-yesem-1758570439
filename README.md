# Ne Yesem? 🍽️

**"Dolapta ne varsa, sofrada lezzet olsun!"**

Ne Yesem?, kullanıcıların mevcut malzemelerine göre yapabilecekleri tarifleri bulan, AI destekli akıllı bir mutfak asistanı uygulamasıdır.

## ✨ Özellikler

### 🎯 Temel Özellikler
- **Manuel Malzeme Ekleme**: Kapsamlı malzeme veritabanından seçim yapma
- **Akıllı Tarif Eşleştirme**: Mevcut malzemelere göre en uygun tarifleri bulma
- **Puan Bazlı Sıralama**: Malzeme uyumluluğuna göre tarif puanlama
- **Detaylı Tarif Görüntüleme**: Malzemeler, adımlar ve pişirme süresi

### 📱 Gelişmiş Özellikler
- **📸 Kamera Entegrasyonu**: Fotoğraf çekerek malzeme tanıma (ML Kit)
- **🎤 Sesli Giriş**: Mikrofon ile hands-free malzeme ekleme
- **🤖 AI Asistan**: Siri ve Google Assistant entegrasyonu
- **🎨 Modern UI/UX**: Animasyonlu ve kullanıcı dostu arayüz
- **♿ Erişilebilirlik**: Ekran okuyucu ve yüksek kontrast desteği

### 🛡️ Güvenlik ve Performans
- **Hata Yönetimi**: Kapsamlı hata yakalama ve kullanıcı bilgilendirme
- **Performans İzleme**: Otomatik performans ölçümü ve optimizasyon
- **Önbellek Yönetimi**: Akıllı veri önbellekleme
- **Bellek Optimizasyonu**: Efficient resource management

## 🚀 Teknolojiler

### Core Technologies
- **Flutter 3.4+**: Cross-platform mobile development
- **Dart**: Programming language
- **Material Design 3**: Modern UI components

### AI & ML
- **Google ML Kit**: Text recognition from images
- **Speech-to-Text**: Voice input processing
- **Flutter TTS**: Text-to-speech functionality

### Services & Integrations
- **Camera Plugin**: Photo capture and gallery access
- **Permission Handler**: Runtime permission management
- **Local Notifications**: Smart cooking suggestions
- **Provider**: State management

### Performance & Quality
- **Lottie Animations**: Smooth micro-interactions
- **Staggered Animations**: Enhanced user experience
- **Error Handling**: Comprehensive error management
- **Accessibility Services**: Screen reader and contrast support

## 📱 Desteklenen Platformlar

- ✅ **Android 7.0+** (API level 24+)
- ✅ **iOS 12.0+**
- 🔄 **Web** (Gelecek sürümde)

## 🛠️ Kurulum

### Gereksinimler
- Flutter SDK 3.4.0 veya üzeri
- Dart SDK 3.0.0 veya üzeri
- Android Studio / VS Code
- iOS: Xcode 14+ (iOS geliştirme için)

### Adımlar

1. **Repository'yi klonlayın**
   ```bash
   git clone https://github.com/your-username/ne-yesem.git
   cd ne-yesem
   ```

2. **Bağımlılıkları yükleyin**
   ```bash
   flutter pub get
   ```

3. **Platform izinlerini yapılandırın**
   - Android: `android/app/src/main/AndroidManifest.xml` kontrol edin
   - iOS: `ios/Runner/Info.plist` kontrol edin

4. **Uygulamayı çalıştırın**
   ```bash
   flutter run
   ```

## 🔧 Yapılandırma

### Kamera ve Mikrofon İzinleri

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>Bu uygulama malzeme fotoğrafları çekmek için kamera kullanır.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Bu uygulama sesli malzeme girişi için mikrofon kullanır.</string>
```

### AI Asistan Entegrasyonu

#### Siri Shortcuts (iOS)
```xml
<key>NSUserActivityTypes</key>
<array>
    <string>SearchRecipesIntent</string>
    <string>AddIngredientIntent</string>
</array>
```

#### Google Assistant Actions (Android)
Deep link yapılandırması `AndroidManifest.xml` dosyasında mevcuttur.

## 🧪 Test Etme

```bash
# Unit testler
flutter test

# Widget testler
flutter test test/widget_test.dart

# Integration testler
flutter drive --target=test_driver/app.dart
```

## 📊 Performans İzleme

Uygulama yerleşik performans izleme araçları içerir:

```dart
// Performans ölçümü başlatma
PerformanceService().startOperation('recipe_search');

// İşlem tamamlandığında
PerformanceService().endOperation('recipe_search');
```

## ♿ Erişilebilirlik

### Desteklenen Özellikler
- **Screen Reader**: TalkBack (Android) ve VoiceOver (iOS) desteği
- **High Contrast**: Yüksek kontrast tema
- **Large Text**: Büyük metin boyutu desteği
- **Voice Navigation**: Sesli navigasyon
- **Keyboard Navigation**: Klavye ile gezinme

### Kullanım
```dart
// Erişilebilir buton oluşturma
AccessibilityService.createAccessibleButton(
  label: 'Tarif Ara',
  onPressed: () => searchRecipes(),
  semanticLabel: 'Mevcut malzemelerle tarif ara',
);
```

## 🚨 Hata Yönetimi

Uygulama kapsamlı hata yönetimi içerir:

```dart
// Global hata yakalama
ErrorHandler.initialize();

// Özel hata mesajları
String message = ErrorHandler.getErrorMessage(error);
ErrorHandler.showErrorSnackBar(context, message);
```

## 🔄 Güncelleme Geçmişi

### v1.0.0 (Mevcut)
- ✅ Temel tarif eşleştirme
- ✅ Kamera entegrasyonu
- ✅ Sesli giriş
- ✅ AI asistan desteği
- ✅ Modern UI/UX
- ✅ Erişilebilirlik özellikleri
- ✅ Performans optimizasyonu

### Gelecek Sürümler
- 🔄 Web platform desteği
- 🔄 Çevrimdışı mod
- 🔄 Kullanıcı hesapları
- 🔄 Sosyal paylaşım
- 🔄 Gelişmiş AI önerileri

## 🎯 Kullanım Senaryoları

### 👨‍🍳 Ev Aşçıları İçin
- Dolaptaki malzemelerle ne yapabileceğini öğrenme
- Yeni tarifler keşfetme
- Malzeme israfını önleme

### 👩‍🦽 Erişilebilirlik
- Görme engelli kullanıcılar için sesli rehberlik
- Motor engeli olan kullanıcılar için sesli giriş
- Yaşlı kullanıcılar için büyük metin desteği

### 🏃‍♀️ Hızlı Kullanım
- Fotoğraf çekerek hızlı malzeme ekleme
- Sesli komutlarla hands-free kullanım
- AI asistan ile akıllı öneriler

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 👨‍💻 Geliştirici

**Ne Yesem? Team**
- 📧 Email: info@neyesem.app
- 🌐 Website: https://neyesem.app
- 📱 GitHub: https://github.com/neyesem

## 🙏 Teşekkürler

- Flutter Team - Amazing framework
- Google ML Kit Team - AI/ML capabilities
- Material Design Team - Beautiful UI components
- Open source community - Inspiration and libraries

---

**"Dolapta ne varsa, sofrada lezzet olsun!"** 🍽️✨