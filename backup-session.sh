#!/bin/bash
# BACKUP SESSION — tiap 30 menit push session WhatsApp ke GitHub (repo private ourin-session)
TOKEN=$(cat /home/z/my-project/Helma/.backup-token 2>/dev/null)
SRC=/home/z/my-project/Helma/storage/session
BAK=/home/z/my-project/.session-backup

while true; do
  sleep 1800
  if [ -f "$SRC/creds.json" ] && [ -n "$TOKEN" ]; then
    cd "$BAK" || exit 1
    # sinkron file session (hapus yang tidak ada, salin yang baru)
    rsync -a --delete "$SRC"/ storage/session/ 2>/dev/null || cp -r "$SRC"/. storage/session/
    git add storage/session .backup-token 2>/dev/null
    git commit -m "auto-backup $(date '+%F %H:%M')" -q 2>/dev/null
    # pull-rebase dulu supaya push tidak ditolak kalau session lain juga push
    git pull --rebase -q origin main 2>/dev/null
    git push -q origin main 2>&1 | rg -v "warning" > /dev/null
    echo "[backup $(date '+%F %H:%M')] Backup terkirim"
  else
    echo "[backup $(date '+%F %H:%M')] tidak ada creds.json, skip"
  fi
done
