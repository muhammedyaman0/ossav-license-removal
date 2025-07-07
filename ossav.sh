#!/bin/bash

LOGFILE="/var/log/ossav_removal.log"
echo "🔍 OsSav License Removal is Processing." | tee "$LOGFILE"

log() {
  echo -e "$1" | tee -a "$LOGFILE"
}

# 0. Plesk kontrolü
if ! command -v plesk >/dev/null; then
  log "❌ Plesk is not installed on this system. Aborting."
  exit 1
fi

# 1. Cron temizliği (satır bazlı)
log "\n📁 Removing OsSav Crons."

cron_dirs=(/etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.monthly /etc/cron.weekly)

for dir in "${cron_dirs[@]}"; do
  if [[ -d "$dir" ]]; then
    for file in "$dir"/*; do
      [[ -f "$file" && "$(grep -i 'ossav' "$file")" ]] && {
        log "✔ Deleting (content contains OsSav): $file"
        rm -f "$file"
      }
    done
  fi
done

grep -qi 'ossav' /etc/crontab && {
  sed -i '/ossav/d' /etc/crontab
  log "✔ OsSav lines removed from /etc/crontab"
} || log "ℹ No OsSav record in /etc/crontab"

if crontab -l 2>/dev/null | grep -qi 'ossav'; then
  crontab -l | grep -vi 'ossav' | crontab -
  log "✔ OsSav record removed from root's crontab"
else
  log "ℹ No record found for OsSav in root crontab"
fi

if [[ -f /var/spool/cron/root ]]; then
  if grep -qi 'ossav' /var/spool/cron/root; then
    sed -i '/ossav/d' /var/spool/cron/root
    log "✔ OsSav lines in /var/spool/cron/root deleted"
  fi
fi

# 2. Modül dizinleri temizliği
log "\n📦 Checking OsSav module directories:"

ossav_paths=(
  /usr/local/psa/admin/plib/modules/OsSav/
  /usr/local/psa/admin/htdocs/modules/OsSav
  /usr/local/psa/var/modules/OsSav
  /opt/psa/admin/plib/modules/OsSav
  /opt/psa/admin/modules/OsSav
  /opt/psa/admin/htdocs/modules/OsSav
  /usr/local/psa/var/modules-packages/OsSav.zip
)

for path in "${ossav_paths[@]}"; do
  if [[ -e "$path" ]]; then
    rm -rf "$path"
    log "✔ Deleted: $path"
  else
    log "⚠ Cannot Find: $path"
  fi
done

# 3. Sertifika
CRT="/etc/pki/ca-trust/source/anchors/OsSavCA.crt"
[[ -f "$CRT" ]] && { rm -f "$CRT"; log "✔ Deleted: $CRT"; } || log "⚠ Cannot Find: $CRT"

# 4. main.js içinde OsSav kod bloğu
log "\n📝 Checking the OsSav code block in main.js"
MAINJS="/usr/local/psa/admin/cp/public/javascript/main.js"

if [[ -f "$MAINJS" ]]; then
  if grep -q '/\*\* OsSav' "$MAINJS"; then
    sed -i '/\/\*\* OsSav/,/\*\*\//d' "$MAINJS"
    log "✔ OsSav JS code block deleted: $MAINJS"
  else
    log "ℹ No OsSav block found in $MAINJS"
  fi
else
  log "⚠ Cannot Find: $MAINJS"
fi

# 5. /etc/hosts güncelle
log "\n📡 Editing /etc/hosts file"

if [[ -f /etc/hosts ]]; then
  chattr -i /etc/hosts 2>/dev/null
  chattr -a /etc/hosts 2>/dev/null

  sed -i '/185\.50\.69\.214/d' /etc/hosts
  log "✔ Deleted lines contains OsSav in /etc/hosts"

  cat <<EOF >> /etc/hosts

# Replaced by secure IP after OsSav removal
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

  log "✔ Plesk IP address has been added!"
else
  log "⚠ /etc/hosts not found!"
fi

# 6. OsSav uzantısını Plesk'ten kaldır
log "\n🧩 OsSav extension is being removed from plesk..."
plesk bin extension --uninstall OsSav &>/dev/null && log "✔ plesk bin extension --uninstall OsSav completed." || log "⚠ OsSav extension not found or already removed"

# 7. Plesk restart
log "\n🔄 Plesk is restarting..."
if command -v systemctl >/dev/null; then
  systemctl restart psa && log "✅ Plesk restarted." || log "❌ Failed to restart Plesk via systemctl"
else
  service psa restart && log "✅ Plesk restarted." || log "❌ Failed to restart Plesk via service"
fi

log "\n✅ Ossav Cleaned Successfully!  Logs: $LOGFILE"
