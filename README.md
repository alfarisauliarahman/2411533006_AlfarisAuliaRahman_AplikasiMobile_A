# Praktikum 5 Akhir

Aplikasi keuangan Flutter dengan SQLite lokal. Project asli praktikum tetap terpisah; seluruh fitur di project ini dijalankan melalui satu `lib/main.dart`.

## Menjalankan

```sh
flutter pub get
flutter run
```

Daftar akun melalui tombol **Daftar**, kemudian masuk memakai akun tersebut. Tidak ada akun bawaan atau login bebas. Nama, email, password ter-hash, sesi, transaksi, pilihan tampil/sembunyi saldo, dan hasil latihan disimpan di SQLite pada perangkat. Setiap pengguna mempunyai data sendiri.

## Fitur yang digabung

- Basic TextField: input nama dan SnackBar, dapat dibuka dari menu **Latihan lainnya** di dashboard.
- Basic Form: validasi nama/email, dapat dibuka dari menu yang sama.
- Kalkulator Kabataku: tambah, kurang, kali, bagi; input dan hasil terakhir disimpan.
- Widgets/state: sapaan, saldo, tombol mata, dan nomor rekening.
- Layout dashboard: aksi **Pemasukan**, **Pengeluaran**, **Transfer**, serta daftar transaksi dengan warna nominal sesuai jenisnya.
- Form: judul, nominal, dropdown kategori, format/validasi tanggal DD/MM/YYYY, dan kalender.
- Navigasi: named routes, dashboard, detail, riwayat, profil, tiga tab, serta logout.
- Register/login lokal: email unik, password minimal 6 karakter, konfirmasi password, dan verifikasi password. Password disimpan dengan salt acak dan PBKDF2-HMAC-SHA256 (120.000 iterasi).

Tombol Transfer mencatat transfer keluar dari saldo pengguna. Tidak mengirim uang atau data ke bank/server. Akun baru mulai tanpa transaksi contoh; saldo dihitung dari transaksi tersimpan, bukan angka statis.

## Acuan tampilan

Dashboard merah, kartu saldo merah, FAB dan navigasi amber mengikuti project keuangan terakhir. Widget lama seperti tombol mata, nomor rekening, tombol aksi, dan dropdown digunakan kembali. Halaman login/register memakai warna merah dan amber yang sama. Halaman latihan dasar dan kalkulator mempertahankan susunan komponen sebelumnya. Riwayat memakai satu kartu dengan garis pemisah, subtitle menampilkan tanggal, dan detail memakai susunan Kategori/Tanggal/Status seperti acuan sebelumnya. Nilai akun, saldo, dan transaksi berubah mengikuti data SQLite.

## Pengujian

```sh
flutter analyze
flutter test
flutter test integration_test/persistence_test.dart -d <id-simulator>
```

Pengujian mencakup register/login/logout, penolakan password salah/email duplikat, penyimpanan setelah database dibuka ulang, pemisahan data akun, input transaksi dan kalender, navigasi/detail, serta pemulihan hasil latihan.

## APK

APK versi **1.0.1+2** tersedia pada [rilis Praktikum 5 Akhir](https://github.com/alfarisauliarahman/2411533006_AlfarisAuliaRahman_AplikasiMobile_A/releases/tag/praktikum5-akhir-v1.0.1).

Untuk membangun APK dari source:

```sh
flutter build apk --release
```

Hasilnya berada pada `build/app/outputs/flutter-apk/app-release.apk`. Nama package Flutter adalah `praktikum5_akhir` dan identitas Android/iOS adalah `com.praktikum5.alfarisaulia`. Folder `output` berisi berkas lokal dan tidak masuk repository.
