#!/bin/bash

# === Styling ===
bold=$(tput bold)
info=$(tput setaf 2)
warn=$(tput setaf 214)
reset=$(tput sgr0)

# === Root Check ===
if [[ $EUID -ne 0 ]]; then
   echo "${warn}${bold}Please run this script as root.${reset}"
   exit 1
fi

# === Banner ===
echo "${bold}${info}"
echo "🚀 Installing Flussonic Media Server 25.11"
echo "${reset}"

# === Add Repository & GPG Key ===
wget -q -O - https://flussonic.com/public/gpg.key | apt-key add -
echo "deb https://flussonic.com/public/apt/ stable main" > /etc/apt/sources.list.d/flussonic.list

# === Update & Install ===
apt-get update
apt-get install -y flussonic flussonic-transcoder

# === Optional: Add License Key ===
echo "l4|AbOFvyPq7piW0ub_MfFUL2|r6BzpmVPpjgKpn9IunpFp6lLbCZOp3" > /etc/flussonic/license.txt

# === Basic Configuration ===
cat > /etc/flussonic/flussonic.conf <<EOF
http 80;
rtmp 1935;
srt 1234;
pulsedb /var/lib/flussonic;
session_log /var/lib/flussonic;
edit_auth admin admin;
iptv;
EOF

# === Start Service ===
systemctl restart flussonic

# === Output Info ===
local_ip=$(hostname -I | awk '{print $1}')
public_ip=$(curl -s https://ifconfig.me)
http_port=$(grep http /etc/flussonic/flussonic.conf | awk '{print $2}' | tr -d ';')

echo
echo "${info}${bold}✅ Flussonic 25.11 Installed Successfully!${reset}"
echo "${warn}Local Access: http://$local_ip:$http_port${reset}"
echo "${warn}Public Access: http://$public_ip:$http_port${reset}"
echo "${warn}Username: admin${reset}"
echo "${warn}Password: admin${reset}"
echo "${warn}License Key: l4|AbOFvyPq7piW0ub_MfFUL2|r6BzpmVPpjgKpn9IunpFp6lLbCZOp3${reset}"
echo
