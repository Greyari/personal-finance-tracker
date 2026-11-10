---
trigger: always_on
---

# Aturan Desain UI - Aplikasi Keuangan & Tabungan (v4: Monochrome Luxury Glass)

> File ini adalah SATU-SATUNYA sumber kebenaran desain. Kalau ada konflik dengan
> kode lama atau rule lain, file ini yang menang.

## 1. Identitas visual
- Gaya: dark mode & light mode support, **glassmorphism halus**, elegan, monokrom minimalis premium (ala Apple & Linear).
- Mood: tenang, berkelas, presisi, percaya diri.
- Kesan elegan datang dari: perpaduan Obsidian Black & Crisp White di Dark Mode, serta Clean Slate White & Jet Black di Light Mode, tipografi tegas (*Plus Jakarta Sans* & *Inter*), dan kaca tipis (*frosted glass*). Dilarang memakai warna ungu/indigo/violet.

## 2. Pemetaan referensi visual (`referensi visual/`)
Ditiru: layout, hierarki, kepadatan, gaya kartu, nuansa premium.
- **`1.webp`** - Dashboard clean: saldo besar dominan di atas, disusul action pills, lalu list transaksi dengan pemisah waktu ("Hari ini", "Kemarin").
- **`2.webp`** (layar tengah) - Input nominal dengan custom keypad (angka 1-9, 000, 0, backspace) tanpa keyboard bawaan OS.
- **`3.webp`** (layar kiri & tengah) - Carousel kartu tabungan / budget horizontal dengan cover foto + overlay dark gradient.

## 3. Warna (token wajib, jangan hardcode warna lain)
| Token | Hex (Dark) | Hex (Light) | Pakai untuk |
|---|---|---|---|
| background | #0A0D14 | #F8FAFC | latar layar (obsidian navy-ink / clean slate) |
| surface | #131826 | #FFFFFF | kartu dasar |
| surfaceHigh | #1B2236 | #F1F5F9 | elemen terangkat / keypad / modal |
| aksen utama (monochrome) | #FFFFFF | #0F172A | tombol utama, icon aktif, highlight (Hitam di Light, Putih di Dark) |
| aksen sekunder | #94A3B8 | #64748B | variasi border, badge, subtitle |
| pemasukan | #34D399 | #059669 | uang masuk (emerald lembut) |
| pengeluaran | #F87171 | #DC2626 | uang keluar (rose lembut) |
| teks utama | #F8FAFC | #0F172A | teks utama (crisp white / jet black) |
| teks sekunder | #94A3B8 | #64748B | teks pendukung / subtitle |
| garis kaca | putih alpha 10-14% | gelap alpha 8-12% | border kartu kaca |
| note card | putih/gelap glass | sticky note glass monokrom |

Aturan pakai warna:
- Monokrom (Hitam di Light Mode, Putih di Dark Mode) sebagai identitas utama.
- Menu navigasi bawah: teks dan icon aktif wajib HITAM PEKAT (#0F172A) di Light Mode dan PUTIH BERSIH (#FFFFFF) di Dark Mode.
- Dilarang keras: warna ungu / violet / indigo, neon norak, kuning emas kusam, dan warna sembarangan di luar token.

## 4. Gaya Glass (konsep utama)
- Kartu kaca = `BackdropFilter` blur (sigma 16-24) + fill putih alpha 4-8% (dark) / gelap alpha 3-5% (light) + border tipis 1px + gradient halus.
- Latar layar memakai `GlassBackground` dengan **multi-orb ambient lighting** (emerald, slate white, rose, teal) serta **kontur gelombang topografis halus (`_BackgroundMeshPainter`)** agar refraksi kaca terlihat sangat nyata dan futuristik berkelas ala Apple & Linear.
- Radius kartu 24px, tombol 16px, spacing proporsional padat-rapi.
- Gunakan komponen di `lib/shared/widgets/glass_widgets.dart` (`GlassScaffold`, `GlassCard`, `GlassButton`, dll).

## 5. Input nominal & custom keypad
- DILARANG memunculkan keyboard bawaan OS untuk nominal transaksi/transfer/tabungan.
- Wajib `NumericKeypad` (`lib/shared/widgets/numeric_keypad.dart`):
  - Baris 1: `1 2 3`, baris 2: `4 5 6`, baris 3: `7 8 9`, baris 4: `000`, `0`, `⌫`.
  - Tombol bergaya kaca (surfaceHigh + border tipis), radius 16px.
- Nominal tampil besar di tengah atas, minimal 40px, bold, format `Rp 1.250.000`.

## 6. Kartu slider tabungan (carousel)
- Pakai `GoalCardSlider` (`lib/shared/widgets/goal_card_slider.dart`), horizontal `PageView`.
- Setiap kartu: nama target, terkumpul, target akhir, persen badge, indikator progres halus.
- Background kartu = foto cover (upload user / asset) + dark gradient overlay agar teks terbaca jelas.

## 7. Foto cover (upload sendiri)
- Saat membuat/edit target tabungan WAJIB ada pemilih cover: **Galeri**, **Kamera**, **Gambar contoh**, atau **Hapus foto**.
- Foto yang dipilih disalin ke folder dokumen aplikasi (`getApplicationDocumentsDirectory`); yang disimpan di database adalah path-nya (`coverImagePath`).
- Gambar harus punya 3 state: loading (shimmer), sukses, fallback (gradient indigo-obsidian placeholder).

## 8. Widget Catatan / Pengingat Melayang (Floating Glass Note Bubble)
- Komponen `FloatingNoteButton` dan `showGlassNotesSheet` di `lib/shared/widgets/note_sticky_widget.dart`.
- Tampilan: **Tombol melayang (Floating Glass Badge)** di layar dengan icon `📌` / `Notes`.
- Saat ditekan, muncul **Frosted Glass Modal Sheet** dari bawah dengan efek blur:
  - Menampilkan daftar catatan pengingat.
  - Tambah catatan baru dengan input bebas overflow (`SingleChildScrollView`).
  - Checklist selesai (teks dicoret).
  - Hapus catatan.
  - Penyimpanan mandiri menggunakan `SharedPreferences.getInstance()` yang dijamin aman tanpa crash.

## 9. Dashboard Super Informatif
Dashboard harus lengkap, kaya data finansial, dan enak dilihat:
1. **Hero Balance Card**: Saldo total dominan (>= 32px), cash flow bar (in vs out), sisa budget harian.
2. **Quick Action Pills**: Tombol cepat masuk, keluar, tabungan, transfer.
3. **Carousel Target Tabungan (`GoalCardSlider`)**: Slider kartu tabungan dengan foto cover dan progres.
4. **Grafik Finansial Interaktif (`fl_chart`)**: Bar / Line chart mingguan & bulanan arus kas tanpa grid tebal.
5. **Ringkasan 4 Kartu Metrik**: Pemasukan, Pengeluaran, Tabungan, Health Score.
6. **Aktivitas Transaksi Terbaru**: List rapi dengan grouping tanggal ("Hari ini", "Kemarin") dan avatar kategori.
7. **Tombol Melayang Pengingat**: Akses cepat ke catatan/reminder tanpa membuat feed dashboard berantakan.

## 10. Implementasi Flutter
- Semua token warna didefinisikan di `lib/core/theme/app_theme.dart` (`AppColors`, `AppRadius`, `AppSpacing`).
- Font: `google_fonts` (`GoogleFonts.plusJakartaSans`, `GoogleFonts.inter`).
- Micro-animation transisi 200-300ms (`flutter_animate`). Skeleton shimmer (`shimmer`).
- Jalankan `flutter analyze` dan pastikan tidak ada error setelah setiap modifikasi.
