#!/bin/bash
# === CANARY OS INSTALLER (MULTI-USER) ===

if [ "$EUID" -ne 0 ]; then 
  echo "❌ Draai dit met sudo!"
  exit
fi

echo "🐤 CanaryOS Installatie..."

# Huidige gebruiker bepalen
REAL_USER=$SUDO_USER
if [ -z "$REAL_USER" ]; then REAL_USER=$(whoami); fi
REAL_HOME=$(getent passwd $REAL_USER | cut -d: -f6)

# 1. SOFTWARE
echo "📥 Apps installeren..."
apt update -qq
grep -v '^#' packages.txt | xargs apt install -y

# SwayNC apart (zit niet in Debian)
# ==========================================
# SWAYNC INSTALLATIE (HYBRIDE METHODE)
# ==========================================

# 1. Probeer eerst de makkelijke manier (APT)
if apt-cache show sway-notification-center &> /dev/null; then
    echo "📥 SwayNC gevonden in de winkel! Installeren via apt..."
    apt install -y sway-notification-center

# 2. Als dat niet lukt, doe de handmatige GitHub manier
elif ! command -v swaync &> /dev/null; then
    echo "⚠️  SwayNC niet in apt. We downloaden hem handmatig..."
    
    # Installeer jq en curl voor de download
    apt install -y jq curl

    # Zoek de link via de API
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/ErikReider/SwayNotificationCenter/releases/latest | jq -r '.assets[] | select(.name | endswith("amd64.deb")) | .browser_download_url')

    # Fallback link als API faalt
    if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" == "null" ]; then
        DOWNLOAD_URL="https://github.com/ErikReider/SwayNotificationCenter/releases/download/v0.10.1/swaync_0.10.1_amd64.deb"
    fi

    echo "📥 Downloaden van: $DOWNLOAD_URL"
    rm -f swaync.deb
    curl -L -o swaync.deb "$DOWNLOAD_URL"

    if dpkg-deb -I swaync.deb &> /dev/null; then
        apt install -y ./swaync.deb
        echo "✅ Handmatige installatie gelukt."
    else
        echo "❌ FOUT: Download mislukt."
    fi
    rm -f swaync.deb

else
    echo "✅ SwayNC is al geïnstalleerd."
fi

# ==========================================
# 2. SYSTEEM TOOLS (Scripts)
echo "🛠  Scripts plaatsen in /usr/local/bin..."
cp bin/canary-* /usr/local/bin/
chmod +x /usr/local/bin/canary-*

# 3. ASSETS (Plaatjes & Thema's) - VOOR IEDEREEN
# ... in install.sh bij stap 3 Assets ...
# 3. ASSETS (Plaatjes & Thema's) - ROBUUSTE VERSIE
echo "🎨 Assets plaatsen..."

# Bestemmingsmap maken (altijd veilig)
mkdir -p /usr/local/share/canaryos

# We checken of de bronmap 'assets' bestaat EN of hij bestanden bevat
if [ -d "assets" ] && [ "$(ls -A assets)" ]; then
    # We gebruiken een punt (.) om ALLES te kopiëren (ook verborgen bestanden)
    cp -r assets/. /usr/local/share/canaryos/ 2>/dev/null
    
    # Rechten goedzetten
    chmod -R 755 /usr/local/share/canaryos
    echo "✅ Assets zijn gekopieerd."
else
    echo "⚠️  Waarschuwing: Geen bestanden gevonden in map 'assets'. Sla ik over."
    # We maken een leeg bestandje zodat de map niet leeg blijft (voorkomt crashes)
    touch /usr/local/share/canaryos/.installed
fi
# Thema (als je die hebt in assets/themes)
# mkdir -p /usr/share/themes
# cp -r assets/themes/* /usr/share/themes/ 2>/dev/null

# 4. CONFIGURATIES
echo "⚙️  Configs uitrollen..."

deploy_config() {
    TARGET=$1
    OWNER=$2
    mkdir -p "$TARGET"
    cp -r config/* "$TARGET/"
    chown -R $OWNER "$TARGET"
}

# A. Voor nieuwe gebruikers (Skelet)
deploy_config "/etc/skel/.config" "root:root"

# B. Voor huidige gebruiker
deploy_config "$REAL_HOME/.config" "$REAL_USER:$REAL_USER"

#install stuff

echo "🐍 Python bibliotheken installeren..."
# We gebruiken --break-system-packages omdat dit jouw eigen OS is
pip3 install customtkinter --break-system-packages --quiet
fc-cache -f -v
echo "✅ Klaar! Herstart Labwc of de PC."
