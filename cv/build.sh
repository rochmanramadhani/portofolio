#!/usr/bin/env bash
# Merender cv.html jadi PDF lewat Chrome headless, lalu mengecek hasilnya
# masih terbaca sebagai teks oleh parser ATS.
#
# Chrome dipilih karena: nol dependensi baru (sudah terpasang), sumbernya
# plain-text yang bisa di-diff di git, dan hasilnya teks asli satu kolom —
# bukan gambar teks. Pandoc/LaTeX/Typst/WeasyPrint tidak ada di mesin ini.
set -euo pipefail

CV="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
OUT="$CV/../assets/CV_Rochman_Ramadhani_Product_Owner.pdf"

[ -x "$CHROME" ] || { echo "Google Chrome tidak ditemukan di $CHROME" >&2; exit 1; }

mkdir -p "$(dirname "$OUT")"

"$CHROME" \
  --headless \
  --disable-gpu \
  --no-pdf-header-footer \
  --export-tagged-pdf \
  --virtual-time-budget=10000 \
  --print-to-pdf="$OUT" \
  "file://$CV/cv.html" 2>/dev/null

[ -s "$OUT" ] || { echo "PDF gagal dibuat" >&2; exit 1; }
printf 'PDF   : %s (%s)\n' "$OUT" "$(du -h "$OUT" | cut -f1)"

# ---------- regresi ATS ----------
# Kalau salah satu baris ini hilang, berarti PDF-nya tidak terbaca sebagai teks
# biasa dan CV-nya akan tersaring sebelum sampai ke mata manusia.
if ! command -v pdftotext >/dev/null 2>&1; then
  echo "LEWAT : pdftotext tidak terpasang, cek ATS dilewati (brew install poppler)" >&2
  exit 0
fi

TXT="$(pdftotext -layout "$OUT" - )"
fail=0
while IFS= read -r probe; do
  [ -z "$probe" ] && continue
  if printf '%s' "$TXT" | grep -qF "$probe"; then
    printf '  ok   %s\n' "$probe"
  else
    printf '  GAGAL %s\n' "$probe" >&2; fail=1
  fi
done <<'PROBES'
Rochman Ramadhani Chiefto Irawan
PRODUCT OWNER & TECH FOUNDER
+62 813 8103 9158
rochmanramadhani12@gmail.com
linkedin.com/in/rochmanrmdhn
github.com/rochmanramadhani
omanlabs.tech
PENGALAMAN PROFESIONAL
PENDIDIKAN
Peringkat 1 — kategori Supporter
PROBES

# pdftotext menaruh form feed di akhir SETIAP halaman, termasuk yang terakhir —
# jadi jumlah form feed = jumlah halaman, bukan jumlah halaman dikurangi satu.
# ---------- tautan harus benar-benar bisa diklik ----------
# Teks URL saja tidak cukup: yang membuat email/WhatsApp/GitHub bisa dibuka
# langsung dari PDF adalah anotasi /URI. Anotasinya bisa berada di dalam stream
# terkompresi, jadi semua stream di-inflate dulu sebelum diperiksa.
python3 - "$OUT" <<'PYEOF'
import re, sys, zlib
raw = open(sys.argv[1], 'rb').read()
found = set()
for m in re.finditer(rb'stream\r?\n', raw):
    s = m.end(); e = raw.find(b'endstream', s)
    if e < 0: continue
    try: data = zlib.decompress(raw[s:e])
    except Exception: data = raw[s:e]
    found |= {u.decode('latin1') for u in re.findall(rb'/URI\s*\((.*?)\)', data, re.S)}
found |= {u.decode('latin1') for u in re.findall(rb'/URI\s*\((.*?)\)', raw, re.S)}
harus = ['mailto:', 'wa.me/', 'linkedin.com/in/', 'github.com/', 'omanlabs.tech']
gagal = [w for w in harus if not any(w in f for f in found)]
for w in harus:
    print(('  ok   tautan ' if w not in gagal else '  GAGAL tautan ') + w)
sys.exit(1 if gagal else 0)
PYEOF
[ $? -eq 0 ] || { echo "TAUTAN: ada yang tidak tertanam" >&2; exit 1; }

pages=$(pdfinfo "$OUT" 2>/dev/null | awk '/^Pages:/{print $2}')
printf 'Halaman: %s\n' "${pages:-?}"
[ "$fail" = 0 ] && echo "ATS   : lolos" || { echo "ATS   : ADA YANG HILANG" >&2; exit 1; }
