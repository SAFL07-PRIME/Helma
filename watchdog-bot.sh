#!/bin/bash
# WATCHDOG — tiap 30 detik cek bot, kalau mati restart + alarm
while true; do
  sleep 30
  STATUS=$(pm2 info ourin-bot 2>/dev/null | rg "status" | rg -o "online|stopped|errored|launching")
  if [ "$STATUS" != "online" ]; then
    echo "[watchdog $(date '+%F %H:%M:%S')] bot mati ($STATUS), restart..."
    pm2 restart ourin-bot
    sleep 60
  fi
done
