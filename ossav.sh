#!/bin/bash

echo "🔍 OsSav License Removal is Processing."
LOGFILE="/var/log/ossav_removal.log"
echo "🕓 Start Date: $(date)" > "$LOGFILE"

log() {
  echo -e "$1" | tee -a "$LOGFILE"
}

log "\n📁 Removing OsSav Crons."

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
        log "✔ Deleting (content contains OsSav): $file"
        rm -f "$file"
      fi
    done
  fi
done

if grep -qi ossav /etc/crontab; then
  sed -i '/ossav/d' /etc/crontab
  log "✔ Cleaned OsSav lines in /etc/crontab"
else
  log "ℹ No OsSav record in /etc/crontab"
fi

log "\n🗓️ checking root crontab (crontab -e)..."
if crontab -l 2>/dev/null | grep -qi ossav; then
  crontab -l | grep -vi ossav | crontab -
  log "✔ OsSav lines deleted from root crontab"
else
  log "ℹ No record found for OsSav in root crontab"
fi

if [ -f "/var/spool/cron/root" ]; then
  if grep -qi ossav /var/spool/cron/root; then
    sed -i '/ossav/d' /var/spool/cron/root
    log "✔ OsSav lines in /var/spool/cron/root deleted"
  else
    log "ℹ No OsSav line found in /var/spool/cron/root"
  fi
else
  log "⚠ /var/spool/cron/root file not found"
fi

ossav_dirs=(
  "/usr/local/psa/admin/plib/modules/OsSav/"
  "/usr/local/psa/admin/htdocs/modules/OsSav"
  "/usr/local/psa/var/modules/OsSav"
  "/opt/psa/admin/plib/modules/OsSav"
  "/opt/psa/admin/modules/OsSav"
  "/opt/psa/admin/htdocs/modules/OsSav"
  "/usr/local/psa/var/modules-packages/OsSav.zip"
)

log "\n📦 Checking OsSav module directories:"
for dir in "${ossav_dirs[@]}"; do
  if [ -e "$dir" ]; then
    rm -rf "$dir"
    log "✔ Deleted: $dir"
  else
    log "⚠ Cannot Find: $dir"
  fi
done

CRT="/etc/pki/ca-trust/source/anchors/OsSavCA.crt"
if [ -f "$CRT" ]; then
  rm -f "$CRT"
  log "✔ Deleted: $CRT"
else
  log "⚠ Cannot Find: $CRT"
fi

JS="/usr/local/psa/admin/cp/public/javascript/main.js"
log "\n📝 Checking the OsSav code block in main.js"

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

  log "✔ Plesk IP address (195.214.233.81) has been added!"
else
  log "⚠ Cannot find /etc/hosts file."
fi

log "\n🧩 OsSav extension is being removed from plesk..."
if plesk bin extension --uninstall OsSav 2>/dev/null; then
  log "✔ plesk bin extension --uninstall OsSav completed."
else
  log "⚠ OsSav extension is either not installed or the removal failed"
fi

log "\n🔄 Plesk is restarting..."
if service psa restart; then
  log "✅ Plesk restarted."
else
  log "❌ Cannot restart Plesk, please check manually."
fi

log "\n✅ Ossav Cleaned Successfully!  Logs: $LOGFILE"
