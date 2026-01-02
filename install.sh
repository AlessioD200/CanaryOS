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
# SWAYNC INSTALLATIE (ROBUUSTE VERSIE)
# ==========================================
if ! command -v swaync &> /dev/null; then
    echo "📥 SwayNC wordt geïnstalleerd..."
    
    # 1. Installeer jq (nodig om GitHub goed uit te lezen)
    apt install -y jq curl

    # 2. Oude bestanden opruimen
    rm -f swaync.deb

    # 3. Probeer de allerlaatste versie te vinden via API en jq
    echo "   ...zoeken naar nieuwste versie..."
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/ErikReider/SwayNotificationCenter/releases/latest | jq -r '.assets[] | select(.name | endswith("amd64.deb")) | .browser_download_url')

    # 4. HET VEILIGHEIDSNET (Fallback)
    # Als de API faalt (leeg is), gebruik dan deze vaste link (versie 0.10.1 werkt altijd)
    if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" == "null" ]; then
        echo "⚠️  API check mislukt. We gebruiken de vaste fallback link."
        DOWNLOAD_URL="https://github.com/ErikReider/SwayNotificationCenter/releases/download/v0.10.1/swaync_0.10.1_amd64.deb"
    fi

    echo "📥 Downloaden van: $DOWNLOAD_URL"
    
    # 5. Downloaden
    curl -L -o swaync.deb "$DOWNLOAD_URL"

    # 6. Check en Installeer
    if dpkg-deb -I swaync.deb &> /dev/null; then
        echo "✅ Bestand is goed. Installeren..."
        apt install -y ./swaync.deb
    else
        echo "❌ FOUT: SwayNC download is corrupt."
        echo "   Dit is waarschijnlijk een netwerkprobleem of een kapotte link."
    fi

    # 7. Opruimen
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
