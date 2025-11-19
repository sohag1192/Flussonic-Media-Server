#!/bin/bash

# === Styling ===
bold=$(tput bold)
underline=$(tput smul)
info=$(tput setaf 2)
warn=$(tput setaf 214)
reset=$(tput sgr0)

# === Root Check ===
if [ "$(id -u)" != "0" ]; then
    echo "${warn}${bold}Please run this script as root.${reset}"
    exit 1
fi

# === Architecture Check ===
arch=$(uname -m)
if [[ "$arch" != "x86_64" && "$arch" != "aarch64" ]]; then
    echo "${warn}${bold}Flussonic requires x86_64 or ARM64 architecture.${reset}"
    exit 1
fi

# === Detect Distro ===
if [ -f /etc/debian_version ]; then
    distro="debian"
    package_manager="apt-get"
    debian_updated="no"
else
    distro="not_debian"
    if command -v dnf >/dev/null 2>&1; then
        package_manager="dnf"
    elif command -v yum >/dev/null 2>&1; then
        package_manager="yum"
    else
        echo "${warn}${bold}No supported package manager found (yum/dnf).${reset}"
        exit 1
    fi
fi

# === Curl Check ===
check_curl() {
    if ! command -v curl >/dev/null 2>&1; then
        ${package_manager} install -y curl
    fi
}

# === Debian Install ===
debian_update() {
    if [ "$debian_updated" = "no" ]; then
        apt-get update
        debian_updated="yes"
    fi
}

debian_install() {
    curl -sSf http://apt.flussonic.com/binary/gpg.key > /etc/apt/trusted.gpg.d/flussonic.gpg
    rm -f /etc/apt/sources.list.d/erlyvideo.list
    echo "deb http://apt.flussonic.com binary/" > /etc/apt/sources.list.d/flussonic.list
    debian_update
    apt-get -y --install-recommends --install-suggests install flussonic flussonic-transcoder
}

# === RHEL/CentOS Install ===
not_debian_install() {
    cat > /etc/yum.repos.d/Flussonic.repo <<EOF
[flussonic]
name=Flussonic
baseurl=http://apt.flussonic.com/rpm
enabled=1
gpgcheck=0
EOF
    ${package_manager} -y install flussonic-erlang flussonic flussonic-transcoder
}

# === Install Release ===
install_release() {
    check_curl
    ${distro}_install
    echo "${info}${bold}Flussonic installed. Starting service...${reset}"
    systemctl start flussonic || /etc/init.d/flussonic restart
}

# === Configure Flussonic ===
configure_flussonic() {
    cat > /etc/flussonic/flussonic.conf <<EOF
http 80;
rtmp 1935;
srt 1234;
pulsedb /var/lib/flussonic;
session_log /var/lib/flussonic;
edit_auth admin admin;
iptv;
EOF

    echo "l4|AbOFvyPq7piW0ub_MfFUL2|r6BzpmVPpjgKpn9IunpFp6lLbCZOp3" > /etc/flussonic/license.txt
    systemctl restart flussonic || /etc/init.d/flussonic restart
}

# === Output Info ===
show_info() {
    local_ip=$(hostname -I | awk '{print $1}')
    public_ip=$(curl -s https://ifconfig.me)
    http_port=$(grep http /etc/flussonic/flussonic.conf | awk '{print $2}' | tr -d ';')
    rtmp_port=$(grep rtmp /etc/flussonic/flussonic.conf | awk '{print $2}' | tr -d ';')
    srt_port=$(grep srt /etc/flussonic/flussonic.conf | awk '{print $2}' | tr -d ';')

    echo
    echo "${info}${bold}✅ Flussonic Installed Successfully!${reset}"
    echo "${warn}${bold}Local IP: $local_ip${reset}"
    echo "${warn}${bold}Public Access: http://$public_ip:$http_port${reset}"
    echo "${warn}${bold}HTTP Port: $http_port${reset}"
    echo "${warn}${bold}RTMP Port: $rtmp_port${reset}"
    echo "${warn}${bold}SRT Port: $srt_port${reset}"
    echo "${warn}${bold}Username: admin${reset}"
    echo "${warn}${bold}Password: admin${reset}"
    echo "${warn}${bold}License Key: l4|AbOFvyPq7piW0ub_MfFUL2|r6BzpmVPpjgKpn9IunpFp6lLbCZOp3${reset}"
    echo
}

# === Run All ===
install_release
configure_flussonic
show_info
