Ne Yesem? (Enhanced MVP)

Overview
 - Mobil öncelikli yemek öneri uygulaması. Kullanıcı elindeki malzemeleri girer, uygulama uyum skoruna göre tarif önerir.
 - Kamera ile malzeme fotoğrafı çekme, sesli giriş ve sesli asistan entegrasyonu özellikleri eklendi.

Yeni Özellikler
 - 📷 Kamera ile malzeme fotoğrafı çekme
 - 🎤 Sesli malzeme girişi ve arama
 - 🤖 Siri/Google Assistant entegrasyonu
 - ⭐ Gelişmiş favori sistemi (kalıcı depolama)
 - 🎨 Modern UI tasarımı
 - ♿ Erişilebilirlik özellikleri
 - 🚀 Performans optimizasyonları
 - 🛡️ Gelişmiş hata yönetimi

Durum
 - Bu depo Flutter kurulumu olmayan ortamda oluşturuldu. Kod yapısı Flutter standardını izler. `flutter` kurulduğunda normal şekilde derlenebilir.

Gereksinimler
 - Flutter SDK 3.22+
 - iOS/Android cihaz (kamera ve ses özellikleri için)
 - İnternet bağlantısı (resim önbellekleme için)

Hızlı Başlangıç
 1) Flutter SDK kurun (3.22+)
 2) Komutları çalıştırın:
```bash
flutter pub get
flutter run -d chrome   # veya bağlı cihaz
```

Kullanım
 1) Ana sayfada "Malzemelerini Ekle" butonuna tıklayın
 2) Sesli giriş için mikrofon simgesine tıklayın
 3) Kamera ile malzeme eklemek için kamera simgesine tıklayın
 4) Menüden sesli asistanı açabilirsiniz

Proje Yapısı
 - lib/
   - main.dart
   - app.dart
   - models/
   - services/
     - assistant_service.dart (yeni)
     - local_store.dart (geliştirildi)
     - matching_service.dart
   - ui/
     - screens/
       - welcome_screen.dart (geliştirildi)
       - ingredients_screen.dart (geliştirildi)
       - results_screen.dart (geliştirildi)
       - recipe_detail_screen.dart (geliştirildi)
     - widgets/
 - assets/
   - recipes.json
   - ingredients.json
   - substitutions.json

Kullanılan Paketler
 - image_picker: Kamera ve galeri erişimi
 - speech_to_text: Ses tanıma
 - flutter_tts: Metin okuma
 - cached_network_image: Resim önbellekleme
 - url_launcher: Asistan entegrasyonu
 - logger: Hata yönetimi
 - path_provider: Yerel depolama

Lisans: MIT

