Ne Yesem? (AI Entegre)

Overview
 - Mobil öncelikli yemek öneri uygulaması. Kullanıcı elindeki malzemeleri girer, uygulama AI destekli uyum skoruna göre tarif önerir.

Durum
 - Yerel AI (TFLite) eklendi. Model bulunamazsa geliştirilmiş sezgisel motor devreye girer.

Hızlı Başlangıç
 1) Flutter SDK kurun (3.22+)
 2) Komutları çalıştırın:
```
flutter pub get
flutter run -d chrome   # veya bağlı cihaz
```

Proje Yapısı
 - lib/
   - main.dart
   - app.dart
   - data/
   - models/
   - services/
   - ui/
     - screens/
     - widgets/
 - assets/
   - recipes.json
   - ingredients.json
   - substitutions.json
    - data/ai_matcher.tflite
    - data/ai_schema.json

AI Hakkında
- `lib/services/ai_service.dart`: TFLite tabanlı tahmin + kişiselleştirme + öğrenen ikameler
- Riverpod provider: `aiServiceProvider`
- V2 Hazırlık: `exportLearningSnapshot()` ile veriyi dışa aktarın; Firebase ile birleştirip `firebase_ml_model_downloader` üzerinden yeni modeli indirip kullanıma hazırlayabilirsiniz.

Lisans: MIT

