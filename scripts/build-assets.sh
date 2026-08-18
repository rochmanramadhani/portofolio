#!/usr/bin/env bash
# Membangun ulang seluruh aset deck dari sumber aslinya.
#
# Sumber ada di dua tempat:
#   ~/code/github.com/rochmanramadhani/slide-kka-smk/assets/  — aset deck lama
#   ~/Downloads/                                              — foto & video mentah
#
# Video sumber 4K HEVC. HEVC tidak jalan di Firefox sama sekali, jadi transcode
# ke H.264 itu soal benar/salah, bukan optimasi. Audio dibuang (-an): semua klip
# diputar muted, dan audio rapat internal tidak perlu ikut terbit.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO/assets"
OLD="$HOME/code/github.com/rochmanramadhani/slide-kka-smk/assets"
DL="$HOME/Downloads"

mkdir -p "$OUT"

say() { printf '\n\033[1m%s\033[0m\n' "$*"; }

# ---------- helpers ----------

# img <sumber> <tujuan> <lebar>
img() {
  sips -s format jpeg -s formatOptions 72 -Z "$3" "$1" --out "$OUT/$2" >/dev/null
  printf '  %-32s %s\n' "$2" "$(du -h "$OUT/$2" | cut -f1)"
}

# vid <sumber> <tujuan> <tinggi|lebar> <crf> <mode: v=vertikal, h=horizontal>
vid() {
  local scale
  if [ "$5" = "v" ]; then scale="scale=-2:$3"; else scale="scale=$3:-2"; fi
  ffmpeg -loglevel error -y -i "$1" \
    -vf "$scale" -c:v libx264 -crf "$4" -preset slow -pix_fmt yuv420p \
    -an -movflags +faststart "$OUT/$2"
  # poster diambil dari hasil encode, bukan sumber, supaya framing-nya persis sama
  ffmpeg -loglevel error -y -ss "${6:-0.5}" -i "$OUT/$2" -frames:v 1 -q:v 4 \
    "$OUT/${2%.mp4}-poster.jpg"
  sips -Z 640 "$OUT/${2%.mp4}-poster.jpg" >/dev/null
  printf '  %-32s %s (poster %s)\n' "$2" "$(du -h "$OUT/$2" | cut -f1)" \
    "$(du -h "$OUT/${2%.mp4}-poster.jpg" | cut -f1)"
}

# ---------- 1. salin apa adanya dari deck lama ----------
say "1/4  Salin dari slide-kka-smk"
for f in rochman.jpg \
         klhk-sparing.mp4 klhk-sparing-poster.jpg \
         siloam-hse.mp4 siloam-hse-poster.jpg; do
  cp "$OLD/$f" "$OUT/$f"
  printf '  %-32s %s\n' "$f" "$(du -h "$OUT/$f" | cut -f1)"
done

# ---------- 2. re-encode wisuda (18 MB di deck lama) ----------
say "2/4  Re-encode wisuda"
vid "$OLD/wisuda.mp4" wisuda.mp4 960 30 v 3
cp "$OLD/wisuda-poster.jpg" "$OUT/wisuda-poster.jpg"

# Sengaja TIDAK disalin:
#  - rochman-avatar.jpg, skolain-wordmark.png, frames-launch-02.jpg
#    tersisa dari deck lama, tidak dipakai satu slide pun.
#  - chat-01/05/06-*.png (screenshot WhatsApp) — slide testimoni dicabut,
#    dan itu pesan pribadi dari rekan kerja bernama, jadi tidak perlu
#    ikut terbit selama tidak ditampilkan.

# ---------- 3. foto baru ----------
say "3/4  Foto baru (sips)"
img "$DL/frames-1.jpg"            frames-launch-01.jpg      1066   # sumber cuma 1066x711
img "$DL/ig.webp"                 seminar-smkjp1-poster.jpg  900
img "$DL/IMG_E9087.HEIC"          bri-pdc-01.jpg            1400
img "$DL/private-1.HEIC"          caezar-01.jpg              820
img "$DL/private-2.JPG"           caezar-02.jpg              820
img "$DL/private-3.HEIC"          caezar-03.jpg              820
img "$DL/hegemoni.HEIC"           hegemoni-01.jpg            820

# ---------- 4. video baru ----------
say "4/4  Video baru (ffmpeg, H.264, tanpa audio)"
vid "$DL/IMG_7159.MOV"            frames-acara-01.mp4  960 30 v 6
vid "$DL/IMG_7172.MOV"            frames-acara-02.mp4  960 30 v 3.5
vid "$DL/badan-kedokteran.MOV"    kedokteran-01.mp4    960 30 v 1

say "Selesai — total aset: $(du -sh "$OUT" | cut -f1)"
