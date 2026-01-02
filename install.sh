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
# SwayNC (Notificaties) - FIX MET CURL
if ! command -v swaync &> /dev/null; then
    echo "📥 SwayNC wordt gedownload..."
    
    # 1. Verwijder oude rommel
    rm -f swaync.deb
    
    # 2. Download met curl en volg redirects (-L)
    # Dit is veiliger dan wget voor GitHub links
    curl -L -o swaync.deb https://github.com/ErikReider/SwayNotificationCenter/releases/download/v0.12.3/swaync_0.12.3_amd64.deb
    
    # 3. Check of het bestand groter is dan 0 bytes
    if [ -s swaync.deb ]; then
        echo "✅ Download gelukt, installeren..."
        apt install -y ./swaync.deb
    else
        echo "❌ Fout: SwayNC download mislukt (bestand is leeg)."
    fi
    
    # 4. Opruimen
    rm -f swaync.deb
else
    echo "✅ SwayNC is al geïnstalleerd."
fi
# 2. SYSTEEM TOOLS (Scripts)
echo "🛠  Scripts plaatsen in /usr/local/bin..."
cp bin/canary-* /usr/local/bin/
chmod +x /usr/local/bin/canary-*

# 3. ASSETS (Plaatjes & Thema's) - VOOR IEDEREEN
echo "🎨 Assets plaatsen..."
# Maak de algemene map
mkdir -p /usr/local/share/canaryos
# Kopieer alles uit jouw assets map naar de systeem map
cp -r assets/* /usr/local/share/canaryos/
# Zorg dat iedereen ze mag lezen
chmod -R 755 /usr/local/share/canaryos

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

echo "✅ Klaar! Herstart Labwc of de PC."
