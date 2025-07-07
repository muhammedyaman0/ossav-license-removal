#!/bin/bash

echo "🧹 OsSav Temizleme Başlatılıyor..."

LOGFILE="/var/log/ossav_removal.log"
echo "OsSav temizleme işlemi - $(date)" > $LOGFILE

cron_paths=(
  "/etc/cron.d/ossav"
  "/etc/cron.daily/ossav"
  "/etc/cron.hourly/ossav"
  "/etc/cron.monthly/ossav"
  "/etc/cron.weekly/ossav"
  "/var/spool/cron/root"
)

echo "🔍 Cron görevleri temizleniyor..." | tee -a $LOGFILE
for path in "${cron_paths[@]}"; do
  if [[ -f "$path" || -d "$path" ]]; then
    rm -rf "$path"
    echo "✔ Silindi: $path" | tee -a $LOGFILE
  fi
done

if grep -qi ossav /etc/crontab; then
  sed -i '/ossav/d' /etc/crontab
  echo "✔ /etc/crontab içindeki OsSav satırları temizlendi" | tee -a $LOGFILE
fi

crontab -l | grep -v ossav | crontab -

ossav_dirs=(
  "/usr/local/psa/admin/plib/modules/OsSav/"
  "/usr/local/psa/admin/htdocs/modules/OsSav"
  "/usr/local/psa/var/modules/OsSav"
  "/opt/psa/admin/plib/modules/OsSav"
  "/opt/psa/admin/modules/OsSav"
  "/opt/psa/admin/htdocs/modules/OsSav"
  "/usr/local/psa/var/modules-packages/OsSav.zip"
)

echo "🗑️ OsSav modül dizinleri kaldırılıyor..." | tee -a $LOGFILE
for dir in "${ossav_dirs[@]}"; do
  if [ -e "$dir" ]; then
    rm -rf "$dir"
    echo "✔ Silindi: $dir" | tee -a $LOGFILE
  fi
done

rm -f /etc/pki/ca-trust/source/anchors/OsSavCA.crt && echo "✔ OsSavCA.crt silindi" | tee -a $LOGFILE

MAIN_JS="/usr/local/psa/admin/cp/public/javascript/main.js"
if grep -qi ossav "$MAIN_JS"; then
  sed
