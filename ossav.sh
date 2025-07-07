#!/bin/bash

echo "🔍 OsSav Temizleme Başlatılıyor..."
LOGFILE="/var/log/ossav_removal.log"
echo "🕓 Başlangıç Zamanı: $(date)" > "$LOGFILE"

log() {
  echo -e "$1" | tee -a "$LOGFILE"
}

# 1. Sadece OsSav içeren cron dosyalarını/satırlarını sil
log "\n📁 OsSav ile ilgili cron kayıtları temizleniyor:"

cron_dirs=(
  "/etc/cron.d"
  "/etc/cron.daily"
  "/etc/cron.hourly"
  "/etc/cron.monthly"
  "/etc/cron.weekly"
)

for dir in "${cron_dirs[@]}"; do
  if [ -d "$dir" ]; then
    for file in "$dir"/*; do
      if [ -f "$file" ] && grep -qi ossav "$file"; then
        log "✔ Siliniyor (içeriği OsSav içeriyor): $file"
        rm -f "$file"
      fi
    done
  fi
done

if grep -qi ossav /etc/crontab; then
  sed -i '/ossav/d' /etc/crontab
  log "✔ /etc/crontab içindeki OsSav satırları temizlendi"
else
  log "ℹ /etc/crontab içinde OsSav kaydı yok"
fi

log "\n🗓️ root crontab (crontab -e) kontrol ediliyor..."
if crontab -l 2>/dev/null | grep -qi ossav; then
  crontab -l | grep -vi ossav | crontab -
  log "✔ root crontab'dan OsSav satırları silindi"
else
  log "ℹ root crontab'da OsSav ile ilgili kayıt bulunamadı"
fi

if [ -f "/var/spool/cron/root" ]; then
  if grep -qi ossav /var/spool/cron/root; then
    sed -i '/ossav/d' /var/spool/cron/root
    log "✔ /var/spool/cron/root içindeki OsSav satırları silindi"
  else
    log "ℹ /var/spool/cron/root içinde OsSav satırı bulunamadı"
  fi
else
  log "⚠ /var/spool/cron/root dosyası bulunamadı"
fi

# 2. OsSav modül dosyalarını sil
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

# 3. Sertifika dosyası
CRT="/etc/pki/ca-trust/source/anchors/OsSavCA.crt"
if [ -f "$CRT" ]; then
  rm -f "$CRT"
  log "✔ Silindi: $CRT"
else
  log "⚠ Bulunamadı: $CRT"
fi

# 4. main.js içindeki OsSav kod bloğunu sil (sürümden bağımsız)
JS="/usr/local/psa/admin/cp/public/javascript/main.js"
log "\n📝 main.js dosyasında OsSav kod bloğu kontrol ediliyor..."

if [ -f "$JS" ]; then
  if grep -q '/\*\* OsSav' "$JS"; then
    sed -i '/\/\*\* OsSav/,/\*\*\//d' "$JS"
    log "✔ OsSav JS kod bloğu silindi: $JS"
  else
    log "ℹ OsSav kod bloğu bulunamadı: $JS"
  fi
else
  log "⚠ Dosya bulunamadı: $JS"
fi

# 5. /etc/hosts dosyasındaki 185.50.69.214 IP'lerini 195.214.233.81 ile değiştir
log "\n📡 /etc/hosts dosyası düzenleniyor (185.50.69.214 → 195.214.233.81)"

if [ -f /etc/hosts ]; then
  chattr -i /etc/hosts 2>/dev/null
  chattr -a /etc/hosts 2>/dev/null

  if grep -q '185.50.69.214' /etc/hosts; then
    sed -i '/185\.50\.69\.214/d' /etc/hosts
    log "✔ /etc/hosts içindeki 185.50.69.214 satırları silindi"
  else
    log "ℹ /etc/hosts içinde 185.50.69.214 bulunamadı"
  fi

  cat <<EOF >> /etc/hosts

# OsSav temizliği sonrası güvenli IP ile güncellendi
195.214.233.81 ka.plesk.com
195.214.233.81 id-00.kaid.plesk.com
195.214.233.81 id-01.kaid.plesk.com
195.214.233.81 id-02.kaid.plesk.com
195.214.233.81 id-03.kaid.plesk.com
195.214.233.81 id-04.kaid.plesk.com
195.214.233.81 id-05.kaid.plesk.com
195.214.233.81 alternate.ka.plesk.com
195.214.233.81 feedback.pp.plesk.com
EOF

  log "✔ Yeni IP (195.214.233.81) ile domain kayıtları eklendi"
else
  log "⚠ /etc/hosts dosyası bulunamadı"
fi

# 6. Plesk uzantısını kaldır
log "\n🧩 OsSav uzantısı plesk üzerinden kaldırılıyor..."
if plesk bin extension --uninstall OsSav 2>/dev/null; then
  log "✔ plesk bin extension --uninstall OsSav başarılı"
else
  log "⚠ OsSav uzantısı ya kurulu değil ya da kaldırma başarısız"
fi

# 7. Plesk restart
log "\n🔄 Plesk servisi yeniden başlatılıyor..."
if service psa restart; then
  log "✅ Plesk başarıyla yeniden başlatıldı"
else
  log "❌ Plesk yeniden başlatılamadı, lütfen manuel kontrol edin"
fi

log "\n✅ OsSav temizleme işlemi tamamlandı. Detaylar: $LOGFILE"
