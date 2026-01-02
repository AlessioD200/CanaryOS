#!/bin/bash
# === CANARY DEVELOPER PUSH ===
# Dit script kopieert jouw huidige live settings naar de repo en uploadt ze.

REPO_DIR="$HOME/CanaryOS"
cd "$REPO_DIR"

echo "📦 Configuraties verzamelen..."

# 1. Configuraties kopiëren (Labwc, Waybar, etc.)
# We gebruiken rsync om alles netjes te spiegelen
rsync -av --delete ~/.config/labwc/ config/labwc/
rsync -av --delete ~/.config/waybar/ config/waybar/
rsync -av --delete ~/.config/swaync/ config/swaync/
rsync -av --delete ~/.config/pcmanfm-qt/ config/pcmanfm-qt/

# 2. Eigen Scripts kopiëren (Canary Settings, etc.)
cp /usr/local/bin/canary-* bin/

# 3. Uploaden naar GitHub
echo "🚀 Uploaden naar GitHub..."
git add .
echo "Wat heb je aangepast? (Bijv: nieuwe taakbalk, vlc toegevoegd)"
read COMMIT_MSG
git commit -m "$COMMIT_MSG"
git push

echo "✅ Klaar! Je collega kan nu updaten."
