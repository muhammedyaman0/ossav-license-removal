#!/bin/bash

echo "🔍 OsSav Temizleme Başlatılıyor..."
LOGFILE="/var/log/ossav_removal.log"
echo "🕓 Başlangıç Zamanı: $(date)" > $LOGFILE

log() {
  echo -e "$1" | tee -a "$LOGFILE"
}

# 1. Sadece OsSav içeren cron dosyalarını/dosyadaki satırları sil
log "\n📁 OsSav ile ilgili cron kayıtları temizleniyor:"

# Belirli cron dizinleri
cron_dirs=(
  "/etc/cron.d"
  "/etc/cron.daily"
  "/etc/cron.hourly"
  "/etc/cron.monthly"
  "/etc/cron.weekly"
)

# Cron dosyalarını tarayıp içinde ossav geçenleri sil
for dir in "${cron_dirs[@]}"; do
  if [ -d "$dir" ]; then
    for file in "$dir"/*; do
      if [ -f "$file" ]; then
        if grep -qi ossav "$file"; then
          log "✔ Siliniyor (içeriği OsSav içeriyor): $file"
          rm -f "$file"
        fi
      fi
    done
  fi
done

# /etc/crontab dosyasını kontrol et ve sadece OsSav satırlarını sil
if grep -qi ossav /etc/crontab; then
  sed -i '/ossav/d' /etc/crontab
  log "✔ /etc/crontab içindeki OsSav satırları temizlendi"
else
  log "ℹ /etc/crontab içinde OsSav kaydı yok"
fi

# root crontab (crontab -l) içinde sadece OsSav satırlarını sil
log "\n🗓️ root crontab (crontab -e) kontrol ediliyor..."
if crontab -l 2>/dev/null | grep -qi ossav; then
  crontab -l | grep -vi ossav | crontab -
  log "✔ root crontab'dan OsSav satırları silindi"
else
  log "ℹ root crontab'da OsSav ile ilgili kayıt bulunamadı"
fi

# (Geri kalan script burada devam edebilir: dizin silme, main.js, hosts vs.)

# Devam etmek istersen diğer adımları da burada güncelleyebilirim...
