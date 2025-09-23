# Ne Yesem? 🤖

Akıllı yemek tarif öneri uygulaması. Dolaptaki malzemeleri analiz ederek, yapay zeka destekli kişiselleştirilmiş tarif önerileri sunar.

## ✨ Özellikler

### 🧠 Yapay Zeka Entegrasyonu
- **TensorFlow Lite** ile offline çalışan AI modeli
- **Dinamik skor hesaplama** - Malzeme uyumu, süre, popülerlik faktörleri
- **Kişiselleştirme** - Kullanıcı geçmişi ve tercihlerine göre öneri optimizasyonu
- **İkame önerileri** - Kullanıcı geri bildirimlerinden öğrenen dinamik alternatifler

### 🎯 Temel Özellikler
- **Malzeme tabanlı arama** - Eldeki malzemelerle eşleşen tarifler
- **Klasik ve AI modları** - İki farklı arama deneyimi
- **Filtreleme** - Zaman, diyet, ekipman kısıtları
- **Tarif detayları** - Adım adım talimatlar ve malzeme listesi
- **Favori tarifler** - Kişisel tarif koleksiyonu

### 📱 Platform Desteği
- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Offline çalışma

## 🚀 Kurulum

### Gereksinimler
- Flutter SDK 3.4.0+
- Dart 3.0+

### Adımlar
1. **Bağımlılıkları yükleyin:**
   ```bash
   flutter pub get
   ```

2. **Uygulamayı çalıştırın:**
   ```bash
   flutter run -d chrome   # Web için
   flutter run -d android  # Android için
   flutter run -d ios      # iOS için
   ```

## 📁 Proje Yapısı

```
lib/
├── main.dart                 # Ana giriş noktası
├── app.dart                  # Ana uygulama widget'ı
├── models/
│   └── models.dart          # Veri modelleri
├── services/
│   ├── ai_service.dart      # AI entegrasyonu
│   ├── ai_provider.dart     # State management
│   ├── matching_service.dart # Klasik eşleştirme
│   └── local_store.dart     # Yerel depolama
└── ui/
    ├── screens/
    │   ├── welcome_screen.dart
    │   ├── ingredients_screen.dart  # Malzeme seçimi (AI butonu ile)
    │   ├── results_screen.dart      # Sonuçlar (AI modu ile)
    │   └── recipe_detail_screen.dart # Tarif detayları (AI analizi ile)
    └── widgets/
        └── score_bar.dart

assets/
├── data/
│   ├── training_data.json    # AI eğitim verileri
│   └── recipe_model.tflite   # TensorFlow Lite modeli
├── recipes.json             # Tarif verileri
├── ingredients.json         # Malzeme verileri
└── substitutions.json       # İkame önerileri
```

## 🤖 AI Entegrasyonu

### AI Servisi
- **AIService.dart**: TensorFlow Lite entegrasyonu ve dinamik skor hesaplama
- **AIProvider.dart**: Riverpod ile state management
- **Fallback mekanizması**: Model yüklenemezse KNN tabanlı yaklaşım

### Özellikler
- ✅ Malzeme benzerlik analizi
- ✅ Dinamik skor hesaplama (+3 tam eşleşme, -2 eksik, -1 ikame)
- ✅ Kullanıcı tercihleri öğrenme
- ✅ Hata yönetimi ve offline destek
- ✅ 3 saniye altı eşleştirme
- ✅ %80+ doğruluk hedefi

### Kullanım
1. Malzemeleri seçin
2. "AI ile Tarif Öner" butonuna tıklayın
3. AI destekli sonuçları görün
4. Detaylarda AI analizi bilgilerini inceleyin

## 🔧 Geliştirme

### Yeni Özellik Ekleme
1. AI modelini güncellemek için `assets/data/training_data.json`'u düzenleyin
2. UI bileşenlerini `lib/ui/` altına ekleyin
3. State management için provider ekleyin

### Test
```bash
flutter test
```

### Build
```bash
flutter build apk        # Android APK
flutter build ios        # iOS IPA
flutter build web        # Web build
```

## 📊 Performans

- **Eşleştirme hızı**: < 3 saniye
- **AI doğruluk**: %80+ (test verilerinde)
- **Bellek kullanımı**: Optimize edilmiş
- **Offline destek**: Tam

## 🔄 V2 Yol Haritası

- [ ] Firebase ile online model eğitimi
- [ ] Gelişmiş kullanıcı profilleri
- [ ] Sosyal özellikler (tarif paylaşımı)
- [ ] Sesli asistan entegrasyonu
- [ ] Gelişmiş görüntü tanıma

## 📝 Lisans

MIT License - Daha fazla detay için LICENSE dosyasına bakın.

## 👥 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'Add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📞 İletişim

Sorularınız için issue açabilir veya e-posta gönderebilirsiniz.

---

**Ne Yesem?** - Dolapta ne varsa, sofrada lezzet olsun! 🍽️🤖

