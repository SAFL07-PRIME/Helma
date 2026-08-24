#!/bin/bash
# ============================================
# RECOVERY SCRIPT BOT OURIN (jalankan setelah env reset)
# Cara pakai: bash /home/z/my-project/Helma/recover-bot.sh
# Otomatis: clone kalau hilang, install deps, restore session, PM2, watchdog
# ============================================

HELMA=/home/z/my-project/Helma
TOKEN=""  # isi kalau token belum tersimpan di repo backup

echo "== [1/5] Cek repo =="
if [ ! -f "$HELMA/index.js" ]; then
  echo "Repo hilang, clone ulang..."
  cd /home/z/my-project
  git clone https://github.com/SAFL07-PRIME/Helma.git
  cd Helma && unzip -q -o Sec1.zip
  node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json'));delete p.dependencies['baileys-caller'];fs.writeFileSync('package.json',JSON.stringify(p,null,2))"
else
  echo "Repo OK"
fi

cd "$HELMA" || exit 1

echo "== [2/5] Ambil token dari repo backup =="
if [ ! -f "$HELMA/.backup-token" ]; then
  # token tersimpan di repo ourin-session (private)
  git clone https://github.com/SAFL07-PRIME/ourin-session.git /home/z/my-project/.session-backup 2>/dev/null
  cp /home/z/my-project/.session-backup/.backup-token "$HELMA/.backup-token" 2>/dev/null && echo "Token dipulihkan" || echo "Token tidak ditemukan, pakai var TOKEN"
  [ -n "$TOKEN" ] && echo -n "$TOKEN" > "$HELMA/.backup-token"
fi
chmod 600 "$HELMA/.backup-token" 2>/dev/null
GH_TOKEN=$(cat "$HELMA/.backup-token" 2>/dev/null)

echo "== [3/5] Restore session =="
if [ ! -f "$HELMA/storage/session/creds.json" ] && [ -n "$GH_TOKEN" ]; then
  rm -rf /home/z/my-project/.session-backup
  git clone https://$GH_TOKEN@github.com/SAFL07-PRIME/ourin-session.git /home/z/my-project/.session-backup 2>/dev/null
  mkdir -p "$HELMA/storage"
  cp -r /home/z/my-project/.session-backup/storage/session "$HELMA/storage/"
  echo "Session dipulihkan ($(ls $HELMA/storage/session | wc -l) file)"
fi

echo "== [4/5] Cek dependencies =="
if [ ! -d node_modules ] || [ ! -d node_modules/sharp ]; then
  # JALUR CEPAT: salin node_modules dari GitHub Releases (~46 detik vs 3-5 menit npm install)
  if [ -n "$GH_TOKEN" ]; then
    echo "Coba salin node_modules dari GitHub Releases (jalur cepat)..."
    ASSET_ID=$(curl -s -H "Authorization: Bearer $GH_TOKEN" "https://api.github.com/repos/SAFL07-PRIME/ourin-session/releases" | rg -o '"id": [0-9]+' | head -1 | rg -o '[0-9]+')
    curl -s -L -H "Authorization: Bearer $GH_TOKEN" -H "Accept: application/octet-stream" \
      "https://api.github.com/repos/SAFL07-PRIME/ourin-session/releases/assets/$ASSET_ID" \
      -o /tmp/nm.tar.gz && \
    file /tmp/nm.tar.gz | rg -q "gzip" && \
    tar -xzf /tmp/nm.tar.gz -C "$HELMA" && rm -f /tmp/nm.tar.gz && \
    echo "node_modules tersalin dari release ✅"
  fi
  # Kalau jalur cepat gagal, fallback ke npm install
  if [ ! -d node_modules/sharp ]; then
    echo "Jalur cepat gagal, install via npm (lebih lama)..."
    npm install 2>&1 | tail -3
    npm approve-scripts sharp skia-canvas ssh2 @ffmpeg-installer/linux-x64 esbuild protobufjs cpu-features btch-downloader tesseract.js 2>/dev/null | tail -2
    npm rebuild sharp skia-canvas @ffmpeg-installer/linux-x64 2>&1 | tail -1
  fi
else
  echo "Dependencies OK"
fi

echo "== [5/5] Install PM2 + jalankan semua =="
if ! command -v pm2 &>/dev/null; then
  npm install -g pm2 2>&1 | tail -1
fi

pm2 delete ourin-bot ourin-watchdog ourin-backup 2>/dev/null
pm2 start index.js --name ourin-bot --max-memory-restart 1G
pm2 start watchdog-bot.sh --name ourin-watchdog
pm2 start backup-session.sh --name ourin-backup
pm2 save

echo ""
echo "✅ Recovery selesai $(date '+%F %T')"
echo "Cek: pm2 list"
