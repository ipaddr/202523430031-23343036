# Setup Firebase untuk Aplikasi Flutter

Panduan lengkap untuk mengkonfigurasi Firebase Authentication dan Firestore di aplikasi Flutter Anda.

## 📋 Prasyarat

1. **Google Account** - Untuk membuat Firebase Project
2. **Aplikasi Flutter** - Sudah terinstall dan ter-setup
3. **Firebase CLI** (opsional tapi disarankan)

## 🚀 Step-by-Step Setup

### 1. Buat Firebase Project

1. Kunjungi [Firebase Console](https://console.firebase.google.com/)
2. Klik **"Create a new project"** atau **"Add project"**
3. Masukkan nama project (contoh: `pertemuan-1`)
4. Pilih lokasi (pilih yang terdekat dengan Anda)
5. Klik **"Create project"** dan tunggu selesai

### 2. Tambahkan Aplikasi iOS (jika ingin di iOS)

1. Di Firebase Console, klik **"Add app"** → pilih **iOS**
2. Masukkan:
   - **iOS Bundle ID**: `com.example.pertemuan1` (atau sesuaikan dengan app Anda)
3. Download file `GoogleService-Info.plist`
4. Buka Xcode project Anda:
   ```bash
   open ios/Runner.xcworkspace
   ```
5. Drag & drop `GoogleService-Info.plist` ke Xcode (pastikan "Copy items if needed" tercentang)
6. Di Xcode, pilih target **"Runner"** dan pastikan file sudah di-link dengan benar

### 3. Tambahkan Aplikasi Android

1. Di Firebase Console, klik **"Add app"** → pilih **Android**
2. Masukkan:
   - **Android package name**: `com.example.pertemuan_1` (cek di `android/app/build.gradle.kts`)
   - **Debug signing certificate SHA-1** (optional untuk development):
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
3. Download file `google-services.json`
4. Letakkan file di:
   ```
   android/app/google-services.json
   ```

### 4. Update Firebase Options

Edit file `lib/firebase_options.dart` dan isi dengan credential dari Firebase Console:

1. Buka **Project Settings** di Firebase Console
2. Pilih tab **"Your apps"**
3. Untuk setiap app (Android, iOS, Web), copy konfigurasinya ke `firebase_options.dart`

Contoh untuk Android:
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyD....',
  appId: '1:000000:android:....',
  messagingSenderId: '000000',
  projectId: 'pertemuan-1',
  databaseURL: 'https://pertemuan-1.firebasedatabase.app',
  storageBucket: 'pertemuan-1.appspot.com',
);
```

### 5. Setup Firestore Database

1. Di Firebase Console, buka **Firestore Database**
2. Klik **"Create database"**
3. Pilih environment (gunakan **"Start in test mode"** untuk development)
4. Pilih lokasi data center
5. Klik **"Enable"**

### 6. Setup Authentication

1. Di Firebase Console, buka **Authentication**
2. Klik tab **"Sign-in method"**
3. Aktifkan **"Email/Password"**:
   - Klik provider **"Email/Password"**
   - Toggle **"Enable"** pada Email/Password
   - Pilih opsi Email link (optional)
   - Klik **"Save"**

### 7. Jalankan Aplikasi

```bash
# Instal dependencies
flutter pub get

# Jalankan di emulator/device
flutter run
```

## 📁 Struktur Folder Proyek

```
lib/
├── main.dart                    # Entry point aplikasi
├── app_initialization.dart      # Inisialisasi Firebase
├── auth_wrapper.dart            # Wrapper untuk auth state management
├── firebase_options.dart        # Konfigurasi Firebase
├── services/
│   └── firebase_service.dart   # Service untuk Firebase operations
└── screens/
    ├── login_screen.dart        # Screen untuk login
    ├── register_screen.dart     # Screen untuk registrasi
    └── home_screen.dart         # Screen setelah login berhasil
```

## 🔧 File Penting

### `firebase_options.dart`
- Berisi konfigurasi Firebase untuk semua platform
- **Jangan commit credential ke git** (gunakan environment variables di production)

### `services/firebase_service.dart`
- Service class untuk semua operasi Firebase
- Menghandle authentication dan Firestore operations

### `auth_wrapper.dart`
- Widget utama yang menangani routing antara login/register dan home
- Menggunakan `authStateChanges` stream untuk detect user state changes

## ⚠️ Firestore Security Rules

Untuk production, update Security Rules di Firestore:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users dapat membaca/menulis data mereka sendiri
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

## 🧪 Testing

1. Buka aplikasi
2. Klik **"Daftar di sini"** untuk membuat akun baru
3. Isi form dengan:
   - Nama (minimal 3 karakter)
   - Email yang valid
   - Password (minimal 6 karakter)
4. Klik **"Daftar"**
5. Jika berhasil, aplikasi akan menampilkan Home Screen
6. Di Home Screen, Anda bisa melihat informasi user
7. Klik **"Logout"** untuk keluar

## 🐛 Troubleshooting

### Build Error: "Firebase not initialized"
- Pastikan `WidgetsFlutterBinding.ensureInitialized()` dipanggil sebelum `Firebase.initializeApp()`

### Error: "App not configured for Android"
- Pastikan `google-services.json` ada di `android/app/`
- Clean build: `flutter clean` then `flutter pub get`

### Firestore Rules Error
- Update Security Rules di Firebase Console ke mode "Start in test mode"
- Atau sesuaikan rules untuk production

### Google Play Services Error (Android)
- Update Google Play Services di Android
- Di `android/app/build.gradle.kts`, pastikan minSdkVersion minimal 21

## 📚 Resources

- [Firebase Docs](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Auth Guide](https://firebase.flutter.dev/docs/auth/overview)
- [Firestore Guide](https://firebase.flutter.dev/docs/firestore/overview)

## 📝 Catatan

- File `google-services.json` dan `GoogleService-Info.plist` berisi sensitive data
- **Jangan commit kredensial ke Git** - gunakan `.gitignore`
- Untuk production, gunakan environment variables atau secret management

---

**Selamat! Aplikasi Firebase Anda siap digunakan.** 🎉
