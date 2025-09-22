# Ne Yesem? 🍽️

**"Dolapta ne varsa, sofrada lezzet olsun!"**

Mobil öncelikli akıllı yemek tarifi uygulaması. Evdeki malzemelerinizle yapabileceğiniz en uygun tarifleri bulur, israfı önler ve zamandan tasarruf sağlar.

## ✨ Özellikler

### 🎯 Temel Özellikler (MVP)
- **Malzeme Girişi**: Metin, sesli ve kamera ile malzeme ekleme
- **Akıllı Eşleştirme**: Uyum skoruna göre tarif önerisi
- **Tarif Detayları**: Adım adım talimatlar, süre, zorluk seviyesi
- **Favori Tarifler**: Kişisel tarif koleksiyonu
- **Offline Destek**: SQLite ile yerel depolama

### 🔧 Gelişmiş Özellikler (V2 Hazır)
- **Sesli Asistan**: Siri/Google Assistant entegrasyonu
- **Kamera Tanıma**: Barkod ve görsel malzeme tanıma
- **Performans**: Isolate-based matching, akıllı önbellekleme
- **Güvenlik**: Veri şifreleme, KVKK uyumu
- **Erişilebilirlik**: Screen reader, büyük font, yüksek kontrast desteği
- **Çoklu Dil**: Türkçe/İngilizce lokalizasyon

## 🏗️ Mimari

### Teknoloji Stack'i
- **Framework**: Flutter 3.22+
- **State Management**: Riverpod
- **Local Database**: SQLite + Shared Preferences
- **Services**: Camera, Speech-to-Text, Image Recognition
- **Security**: Custom encryption, GDPR compliance

### Klasör Yapısı
```
lib/
├── main.dart                 # Uygulama giriş noktası
├── app.dart                  # Ana uygulama widget'ı
├── models/                   # Veri modelleri
│   └── models.dart
├── providers/               # Riverpod provider'ları
│   └── app_providers.dart
├── services/                # İş mantığı servisleri
│   ├── matching_service.dart
│   ├── storage_service.dart
│   ├── camera_service.dart
│   ├── speech_service.dart
│   ├── security_service.dart
│   ├── error_handling_service.dart
│   ├── performance_service.dart
│   ├── assistant_service.dart
│   └── accessibility_service.dart
└── ui/
    ├── screens/             # Ana ekranlar
    │   ├── welcome_screen.dart
    │   ├── ingredients_screen.dart
    │   ├── results_screen.dart
    │   └── recipe_detail_screen.dart
    └── widgets/             # Yeniden kullanılabilir widget'lar
        ├── speech_button.dart
        ├── camera_button.dart
        └── score_bar.dart
```

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler
- Flutter SDK 3.22+
- Android Studio / Xcode (platform-specific)
- Camera ve mikrofon izinleri

### Adımlar
```bash
# Bağımlılıkları yükle
flutter pub get

# Web'de çalıştır (geliştirme)
flutter run -d chrome

# Android/iOS'ta çalıştır
flutter run -d [device_id]

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

## 📱 Kullanım

1. **Hoş Geldin**: Uygulamayı açın ve "Malzemelerini ekle"ye tıklayın
2. **Malzeme Ekleme**:
   - Metin ile arama yapın
   - 🎤 Mikrofon ile sesli ekleyin
   - 📷 Kamera ile görsel tanıma yapın
3. **Tarif Arama**: "Tarif Ara" ile önerileri görün
4. **Tarif İnceleme**: Beğendiğiniz tarifi favorilere ekleyin

## 🔍 Eşleştirme Algoritması

```
Skor Formülü:
+3 puan × tam eşleşen malzeme
-2 puan × eksik malzeme
-1 puan × ikame malzeme
+5 puan × süre filtresi
+5 puan × diyet filtresi
+2 puan × az ekipman
```

## 🛡️ Güvenlik ve Gizlilik

- **Veri Şifreleme**: Tüm hassas veriler şifrelenmiş olarak saklanır
- **KVKK Uyumu**: Kullanıcı verilerini silme hakkı
- **Anonim Analitik**: GDPR uyumlu veri toplama
- **İzin Yönetimi**: Kamera/mikrofon izinleri isteğe bağlı

## 📊 Performans

- **3 saniye**: 100 malzeme × 50 tarif eşleştirme
- **Offline Öncelik**: İnternet bağımlılığı minimum
- **Akıllı Önbellek**: Sık kullanılan sonuçlar ön belleğe alınır
- **Memory Efficient**: Büyük veri setleri için optimize edilmiş

## 🌍 Lokalizasyon

Desteklenen Diller:
- 🇹🇷 Türkçe (varsayılan)
- 🇺🇸 English

## 🔄 Versiyon Geçmişi

### V1.0.0 (MVP) ✅
- [x] Temel malzeme girişi
- [x] Tarif eşleştirme algoritması
- [x] Favori tarifler
- [x] SQLite entegrasyonu
- [x] Error handling
- [x] Temel UI/UX

### V2.0.0 (Yakında) 🚧
- [ ] Sesli asistan entegrasyonu
- [ ] Gelişmiş kamera tanıma
- [ ] Push notifications
- [ ] Sosyal özellikler
- [ ] Premium abonelik

## 🤝 Katkıda Bulunma

1. Bu repoyu fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Değişikliklerinizi commit edin (`git commit -m 'Add amazing feature'`)
4. Branch'inizi push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır. Detaylar için [LICENSE](LICENSE) dosyasına bakın.

## 🙏 Teşekkür

- Flutter ekibine teşekkürler
- Açık kaynak topluluğuna destekleri için
- Test kullanıcılarımıza geri bildirimleri için

---

**Ne Yesem?** - Mutfakta en iyi arkadaşınız! 🍳👨‍🍳

