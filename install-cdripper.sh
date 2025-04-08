#!/bin/bash

set -e

### Konfiguration
INSTALL_DIR="/opt/cdripper"
SERVICE_NAME="cdripper"
PYTHON_BIN="python3"
LOGFILE="/var/log/cdripper_installer.log"

# Fortschrittsbalken Funktion
step() {
    echo -e "\n[$(date +%H:%M:%S)] $1" | tee -a "$LOGFILE"
}

# Ermittle aktuellen Benutzer zur Laufzeit
RUN_USER=$(logname)

# Starte Logdatei
sudo touch "$LOGFILE"
sudo chown "$USER:$USER" "$LOGFILE"
echo "🚀 Starte Installation am $(date)" > "$LOGFILE"

### Funktion: Paketinstallation
install_packages() {
    step "🔧 Installiere Abhängigkeiten..."
    sudo apt update | tee -a "$LOGFILE"
    sudo apt install -y $PYTHON_BIN $PYTHON_BIN-venv abcde flac lame vorbis-tools cd-discid eyed3 python3-mutagen python3-pip libmagic1 libxml2-utils | tee -a "$LOGFILE"
}

### Funktion: Projektstruktur aufbauen
setup_project() {
    step "📁 Erstelle Projektverzeichnis..."
    sudo rm -rf "$INSTALL_DIR"
    sudo mkdir -p "$INSTALL_DIR"
    sudo chown "$RUN_USER:$RUN_USER" "$INSTALL_DIR"

    step "🐍 Richte virtuelles Python-Umfeld ein..."
    $PYTHON_BIN -m venv "$INSTALL_DIR/venv"
    source "$INSTALL_DIR/venv/bin/activate"

    step "📦 Installiere Python-Abhängigkeiten..."
    pip install --upgrade pip | tee -a "$LOGFILE"
    pip install flask pyyaml mutagen eyed3 python-magic requests flask-cors beautifulsoup4 | tee -a "$LOGFILE"

    step "📄 Erstelle Beispiel-Anwendung..."
    cat > "$INSTALL_DIR/app.py" <<EOF
import os
import yaml
from flask import Flask, request, jsonify
from flask_cors import CORS
app = Flask(__name__)
CORS(app)

CONFIG_PATH = os.path.join(os.path.dirname(__file__), 'config.yaml')

@app.route('/api/config', methods=['GET'])
def get_config():
    with open(CONFIG_PATH, 'r') as f:
        return yaml.safe_load(f)

@app.route('/api/config', methods=['POST'])
def set_config():
    data = request.json
    with open(CONFIG_PATH, 'w') as f:
        yaml.dump(data, f)
    return {'status': 'updated'}

@app.route('/')
def index():
    return "CDRipper Web UI läuft!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
EOF

    step "📝 Erstelle Standardkonfiguration (YAML)..."
    cat > "$INSTALL_DIR/config.yaml" <<EOF
output_formats:
  - mp3
  - flac
  - ogg
output_directory: /home/$RUN_USER/Music
use_album_art: true
tagging_mode: auto
rip_on_insert: true
scheduler:
  enabled: false
  time: "22:00"
EOF

    step "🔧 Erstelle Ripping-Skripte und Automatisierung..."
    cat > "$INSTALL_DIR/rip_cd.sh" <<'EOF'
#!/bin/bash

CONFIG="/opt/cdripper/config.yaml"
DIR=$(python3 -c "import yaml; print(yaml.safe_load(open('$CONFIG'))['output_directory'])")
FORMATS=$(python3 -c "import yaml; print(' '.join(yaml.safe_load(open('$CONFIG'))['output_formats']))")
ART=$(python3 -c "import yaml; print(yaml.safe_load(open('$CONFIG'))['use_album_art'])")

abcde -o "$FORMATS" -d /dev/cdrom -x -N -W -o lowdisc --outputdir "$DIR"
EOF
    chmod +x "$INSTALL_DIR/rip_cd.sh"

    cat > "$INSTALL_DIR/download_cover.py" <<'EOF'
# Optionales Skript zur automatischen Cover-Beschaffung
EOF
}

### Funktion: Systemdienst erstellen
setup_systemd_service() {
    step "🛠️ Erstelle systemd-Dienst..."
    sudo tee "/etc/systemd/system/$SERVICE_NAME.service" > /dev/null <<EOF
[Unit]
Description=CDRipper Web API
After=network-online.target

[Service]
Type=simple
User=$RUN_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python3 $INSTALL_DIR/app.py
Restart=on-failure
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

    step "🚀 Aktiviere und starte Dienst..."
    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME"
    sudo systemctl start "$SERVICE_NAME"
}

### Hauptablauf
install_packages
setup_project
setup_systemd_service

step "✅ CDRipper wurde erfolgreich installiert und läuft auf Port 8000."
echo "   Öffne http://<deine-ip>:8000 im Browser."
