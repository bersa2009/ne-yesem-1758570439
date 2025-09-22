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

Firebase Kurulumu (opsiyonel, backend özellikleri için)
 1) Firebase projesi oluşturun ve Web (veya Android/iOS) uygulaması ekleyin
 2) FlutterFire CLI ile yapılandırın:
 ```
 dart pub global activate flutterfire_cli
 flutterfire configure
 ```
 3) Authentication'da Anonymous + Email/Password etkinleştirin
 4) Firestore etkinleştirin. Basit Security Rules örneği:
 ```
 rules_version = '2';
 service cloud.firestore {
   match /databases/{database}/documents {
     match /users/{userId}/{document=**} {
       allow read, write: if request.auth != null && request.auth.uid == userId;
     }
   }
 }
 ```
 5) Uygulama Firebase olmadan da açılır; ancak favoriler/pantry/arama geçmişi/alışveriş listesi senkronu için Firebase gerekir.

Yeni Özellikler (MVP paketi)
 - Firebase entegrasyonu: anonim oturum açma, Firestore depoları
 - Filtreler: süre, porsiyon, diyet, ekipman hariç tutma
 - Skor barı: sonuç kartlarında renkli bar
 - Alışveriş listesi: eksikleri ekle, CSV paylaşımı

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

