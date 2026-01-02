#!/bin/bash
# === CANARY OS INSTALLER & UPDATER ===

# Check op root
if [ "$EUID" -ne 0 ]; then 
  echo "❌ Draai dit script aub met sudo!"
  exit
fi

echo "🐤 CanaryOS wordt geïnstalleerd/bijgewerkt..."

# Bepaal wie de echte gebruiker is (niet root)
REAL_USER=$SUDO_USER
if [ -z "$REAL_USER" ]; then REAL_USER=$(whoami); fi
REAL_HOME=$(getent passwd $REAL_USER | cut -d: -f6)

# 1. APPS INSTALLEREN
echo "📥 Applicaties installeren..."
apt update -qq
# Lees packages.txt en installeer alles (negeer commentaar regels met #)
grep -v '^#' packages.txt | xargs apt install -y

# 2. SYSTEEM TOOLS PLAATSEN
echo "🛠  Canary Tools installeren..."
cp bin/canary-* /usr/local/bin/
chmod +x /usr/local/bin/canary-*

# 3. CONFIGURATIES (MULTI-USER SETUP)
echo "⚙️  Configuraties uitrollen..."

# Functie om configs te kopiëren
deploy_config() {
    TARGET=$1
    OWNER=$2
    GROUP=$3
    
    mkdir -p "$TARGET"
    cp -r config/* "$TARGET/"
    chown -R $OWNER:$GROUP "$TARGET"
}

# A. Zet het in /etc/skel (Voor alle TOEKOMSTIGE gebruikers)
echo "   -> Updaten van Systeem Skelet (/etc/skel)..."
mkdir -p /etc/skel/.config
deploy_config "/etc/skel/.config" "root" "root"

# B. Zet het bij de HUIDIGE gebruiker (zodat het nu werkt)
echo "   -> Updaten van gebruiker $REAL_USER..."
mkdir -p "$REAL_HOME/.config"
deploy_config "$REAL_HOME/.config" "$REAL_USER" "$REAL_USER"

# 4. STARTEN
echo "✅ Installatie voltooid!"
echo "   Als dit de eerste keer is: Typ 'labwc' om te starten."
echo "   Als je al in Labwc zit: Druk Windows+Shift+R om te herladen."
