---
name: generate-visual-assets
description: Panduan dan workflow untuk men-generate aset gambar (ilustrasi 3D, cover kartu target tabungan) menggunakan subagent image-generator dengan gaya dark mode premium yang serasi dengan aplikasi.
---

# Skill: Generate Visual Assets

Skill ini digunakan saat aplikasi membutuhkan aset gambar baru (seperti cover target tabungan: rumah impian, mobil, gadget, liburan, atau avatar) agar selaras dengan identitas visual di `.agents/rules/ui-design.md`.

## Gaya Visual Gambar
- **Gaya**: 3D clay / sleek render modern, premium, dark minimalist.
- **Warna Aksen**: Nuansa mint (#3DFFB5) atau neon glow lembut pada background gelap (#0E0F13 - #171922).
- **Format**: WebP atau PNG transparan/dark backdrop.
- **Lokasi Simpan**: `assets/images/goals/` atau `assets/images/illustrations/`.

## Prosedur
1. Buat folder target jika belum ada: `assets/images/...`
2. Panggil subagent `image-generator` dengan prompt brief yang detail dan spesifik warna tema.
3. Simpan file yang dihasilkan ke dalam folder `assets/images/`.
4. Daftarkan path asset di `pubspec.yaml` di bawah bagian `flutter: assets:`.
5. Hubungkan ke widget `GoalCardSlider` atau komponen gambar terkait.
