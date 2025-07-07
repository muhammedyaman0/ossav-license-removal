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

# OsSav modül dizinleri
ossav_dirs=(
  "/usr/local/psa/admin/plib/modules/OsSav/"
  "/usr/local/psa/admin/htdocs/modules/OsSav"
  "/usr/local/psa/var/modules/OsSav"
  "/opt/psa/admin/plib/modules/OsSav"
  "/opt/psa/admin/modules/OsSav"
  "/opt/psa/admin/htdocs/modules/OsSav"
  "/usr/local/psa/var/modules-packages/OsSav.zip"
)

log "\n📦 OsSav modül dizinleri kontrol ediliyor:"
for dir in "${ossav_dirs[@]}"; do
  if [ -e "$dir" ]; then
    rm -rf "$dir"
    log "✔ Silindi: $dir"
  else
    log "⚠ Bulunamadı: $dir"
  fi
done

# Sertifika dosyası
CRT="/etc/pki/ca-trust/source/anchors/OsSavCA.crt"
if [ -f "$CRT" ]; then
  rm -f "$CRT"
  log "✔ Silindi: $CRT"
else
  log "⚠ Bulunamadı: $CRT"
fi

# main.js dosyasında Ossav varsa sil
JS="/usr/local/psa/admin/cp/public/javascript/main.js"
log "\n📝 main.js dosyası kontrol ediliyor..."
if [ -f "$JS" ]; then
  if grep -qi ossav "$JS"; then
    sed -i '/ossav/d' "$JS"
    log "✔ OsSav ile ilgili kod satırları silindi: $JS"
  else
    log "ℹ OsSav ile ilgili kod satırı bulunamadı: $JS"
  fi
else
  log "⚠ Dosya bulunamadı: $JS"
fi

# /etc/hosts dosyasından 185.* IP'yi sil
log "\n📡 /etc/hosts dosyası düzenleniyor..."
if [ -f /etc/hosts ]; then
  chattr -i /etc/hosts 2>/dev/null
  chattr -a /etc/hosts 2>/dev/null
  BEFORE=$(grep '^185\.' /etc/hosts)
  sed -i '/^185\./d' /etc/hosts
  AFTER=$(grep '^185\.' /etc/hosts)
  if [[ -n "$BEFORE" && -z "$AFTER" ]]; then
    log "✔ /etc/hosts dosyasından 185.* IP silindi"
  else
    log "ℹ /etc/hosts içinde 185.* IP bulunamadı"
  fi
else
  log "⚠ /etc/hosts dosyası bulunamadı"
fi

# Plesk uzantısını kaldır
log "\n🧩 OsSav uzantısı plesk üzerinden kaldırılıyor..."
if plesk bin extension --uninstall OsSav 2>/dev/null; then
  log "✔ plesk bin extension --uninstall OsSav başarılı"
else
  log "⚠ OsSav uzantısı ya kurulu değil ya da kaldırma başarısız"
fi

# Plesk restart
log "\n🔄 Plesk servisi yeniden başlatılıyor..."
if service psa restart; then
  log "✅ Plesk başarıyla yeniden başlatıldı"
else
  log "❌ Plesk yeniden başlatılamadı, lütfen manuel kontrol edin"
fi

log "\n✅ İşlem tamamlandı. Detaylar: $LOGFILE"
