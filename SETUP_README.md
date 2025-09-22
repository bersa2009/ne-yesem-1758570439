# Ne Yesem? - Recipe Matching App

Bu uygulama, kullanıcıların kilerindeki malzemelerle eşleşen tarifler öneren Flutter tabanlı bir mobil uygulamadır.

## 🚀 Özellikler

### ✅ Tamamlanan Özellikler
- **Firebase Entegrasyonu**: Auth ve Firestore kurulumu
- **Kullanıcı Yönetimi**: E-posta ile kayıt/giriş sistemi
- **Kalıcı Veri Saklama**: Pantry, favoriler, alışveriş listesi
- **Akıllı Tarif Eşleştirme**: Gelişmiş skorlama algoritması
- **Skor Görselleştirme**: Renk kodlu skor barları
- **Alışveriş Listesi**: Eksik malzemeleri listeye ekleme
- **Filtre Sistemi**: Süre, diyet, ekipman filtreleri
- **SQLite Önbellek**: Çevrimdışı tarif saklama

### 🔄 Geliştirme Aşamasında
- **Bildirimler**: SKT takibi için push notifications
- **Besin Bilgisi**: Nutrition API entegrasyonu
- **Geniş Veri Seti**: 2-5K tarif ve malzeme kataloğu
- **Pro Özellikler**: Sınırsız arama, reklamsız deneyim

## 🛠 Kurulum

### 1. Flutter Kurulumu
```bash
# Flutter SDK'yı indirin ve PATH'e ekleyin
# https://flutter.dev/docs/get-started/install
```

### 2. Firebase Kurulumu
1. Firebase Console'da yeni bir proje oluşturun
2. Authentication'ı e-posta/şifre ile etkinleştirin
3. Firestore Database'i etkinleştirin
4. `lib/firebase_options.dart` dosyasını güncelleyin:
   ```dart
   static const FirebaseOptions android = FirebaseOptions(
     apiKey: 'your-api-key',
     appId: 'your-app-id',
     // ... diğer ayarlar
   );
   ```

### 3. Bağımlılıkları Yükleme
```bash
flutter pub get
```

### 4. Uygulamayı Çalıştırma
```bash
flutter run
```

## 📱 Kullanım

1. **Kayıt/Giriş**: E-posta ve şifre ile hesap oluşturun
2. **Kiler Yönetimi**: Malzemelerinizi ekleyin/düzenleyin
3. **Tarif Arama**: Kilerinizdeki malzemelerle tarif arayın
4. **Filtreler**: Süre, diyet tercihine göre filtreleyin
5. **Alışveriş Listesi**: Eksik malzemeleri listeye ekleyin

## 🏗 Mimari

```
lib/
├── models/           # Veri modelleri
├── providers/        # State management (Provider)
├── services/         # API servisleri ve veritabanı işlemleri
├── ui/
│   ├── screens/      # Ana ekranlar
│   └── widgets/      # Yeniden kullanılabilir bileşenler
└── firebase_options.dart
```

## 🔐 Güvenlik

- Firestore Security Rules ile veri erişimi kontrolü
- Kullanıcı kimlik doğrulaması
- KVKK/GDPR uyumlu veri saklama

## 📊 Performans

- Çevrimdışı önbellekleme (SQLite)
- Verimli tarif eşleştirme algoritması
- Lazy loading ve pagination

## 🎯 MVP Hedefleri

- [x] Temel tarif eşleştirme
- [x] Kullanıcı kimlik doğrulaması
- [x] Kalıcı veri saklama
- [x] Alışveriş listesi yönetimi
- [x] Filtre sistemi
- [ ] Geniş tarif kataloğu (2-5K tarif)
- [ ] Besin bilgisi entegrasyonu
- [ ] Push bildirimler

## 🤝 Katkıda Bulunma

1. Bu repoyu fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.