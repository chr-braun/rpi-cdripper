#!/bin/bash
set -e

echo "📦 Starte Installation des CDRippers (headless)..."

INSTALL_DIR="/opt/cdripper"
SERVICE_FILE="/etc/systemd/system/cdripper.service"

# Schritt 1: Abhängigkeiten installieren
echo "🔧 Installiere benötigte Pakete..."
sudo apt update
sudo apt install -y abcde cdparanoia lame flac vorbis-tools glyrc curl eject yq

# Schritt 2: Verzeichnisstruktur anlegen
echo "📁 Erstelle Installationsverzeichnis: $INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
sudo chown $USER:$USER "$INSTALL_DIR"

# Schritt 3: config.yaml anlegen
echo "📝 Erstelle Konfigurationsdatei..."
cat <<EOF | sudo tee "$INSTALL_DIR/config.yaml" > /dev/null
output_dir: "/home/pi/Musik/CDs"
formats:
  - mp3
  - flac
  - ogg
auto_tag: true
auto_cover: true
log_to_file: true
EOF

# Schritt 4: Hauptskript erstellen
echo "🧠 Erstelle Ripperskript..."
cat <<'EOL' | sudo tee "$INSTALL_DIR/cdripper.sh" > /dev/null
#!/bin/bash
set -e

CONFIG_FILE="/opt/cdripper/config.yaml"
CONFIG=$(cat "$CONFIG_FILE")

OUTPUT_DIR=$(echo "$CONFIG" | yq '.output_dir')
FORMATS=$(echo "$CONFIG" | yq '.formats | join(",")')
TAGGING=$(echo "$CONFIG" | yq '.auto_tag')
COVER=$(echo "$CONFIG" | yq '.auto_cover')
LOGGING=$(echo "$CONFIG" | yq '.log_to_file')

DATE=$(date +%Y-%m-%d_%H-%M-%S)
LOGFILE="${OUTPUT_DIR}/cdrip_${DATE}.log"

[ "$LOGGING" == "true" ] && exec > >(tee -a "$LOGFILE") 2>&1

echo "🔄 Starte Ripping-Vorgang: $(date)"
echo "📁 Zielverzeichnis: $OUTPUT_DIR"
echo "🎵 Formate: $FORMATS"

mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR"

ABCDE_OPTS="-o $FORMATS -d /dev/cdrom -x -N -V"
[ "$TAGGING" == "true" ] && ABCDE_OPTS="$ABCDE_OPTS -t"
[ "$COVER" == "true" ] && ABCDE_OPTS="$ABCDE_OPTS -C"

abcde $ABCDE_OPTS
eject

echo "✅ Ripping abgeschlossen um $(date)"
EOL

sudo chmod +x "$INSTALL_DIR/cdripper.sh"

# Schritt 5: Systemd-Dienst erstellen
echo "🛠️ Erstelle Systemd-Dienst..."
cat <<EOF | sudo tee "$SERVICE_FILE" > /dev/null
[Unit]
Description=CDRipper Headless Auto Ripper
After=multi-user.target

[Service]
ExecStart=${INSTALL_DIR}/cdripper.sh
Type=oneshot

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable cdripper

echo "✅ Installation abgeschlossen."
echo "📀 Lege eine CD ein und starte manuell mit: sudo systemctl start cdripper"
