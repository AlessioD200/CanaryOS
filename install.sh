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
# SwayNC (Notificaties) - AUTO UPDATE VERSIE
if ! command -v swaync &> /dev/null; then
    echo "📥 SwayNC: Laatste versie zoeken..."
    
    # 1. Oude rommel opruimen
    rm -f swaync.deb
    
    # 2. Haal de URL van de allerlaatste release op via de GitHub API
    # Dit is veel veiliger dan een vaste link typen
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/ErikReider/SwayNotificationCenter/releases/latest | grep "browser_download_url.*amd64.deb" | cut -d : -f 2,3 | tr -d \")
    
    if [ -z "$DOWNLOAD_URL" ]; then
        echo "❌ Fout: Kon de download link niet vinden."
    else
        echo "📥 Downloaden van: $DOWNLOAD_URL"
        wget -O swaync.deb "$DOWNLOAD_URL"
        
        # 3. Check of het bestand echt een Debian archief is
        if dpkg-deb -I swaync.deb &> /dev/null; then
            echo "✅ Bestand is geldig. Installeren..."
            apt install -y ./swaync.deb
        else
            echo "❌ Fout: Gedownload bestand is corrupt (waarschijnlijk een HTML pagina)."
            echo "   Inhoud van bestand:"
            head -n 5 swaync.deb
        fi
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
# ... in install.sh bij stap 3 Assets ...
echo "🎨 Assets plaatsen..."

# Check of de map wel bestaat in de git repo
if [ -d "assets" ]; then
    mkdir -p /usr/local/share/canaryos
    cp -r assets/* /usr/local/share/canaryos/
    chmod -R 755 /usr/local/share/canaryos
else
    echo "⚠️  Let op: Map 'assets' niet gevonden in de download. Sla ik over."
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

echo "✅ Klaar! Herstart Labwc of de PC."
