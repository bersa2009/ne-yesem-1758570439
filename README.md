Ne Yesem? (MVP)

Overview
 - Mobil öncelikli yemek öneri uygulaması. Kullanıcı elindeki malzemeleri girer, uygulama uyum skoruna göre tarif önerir.

Durum
 - Bu depo Flutter kurulumu olmayan ortamda oluşturuldu. Kod yapısı Flutter standardını izler. `flutter` kurulduğunda normal şekilde derlenebilir.

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

Lisans: MIT

