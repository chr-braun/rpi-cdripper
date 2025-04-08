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

RUN_USER=$(logname)

sudo touch "$LOGFILE"
sudo chown "$USER:$USER" "$LOGFILE"
echo "🚀 Starte Installation am $(date)" > "$LOGFILE"

### Paketinstallation
install_packages() {
    step "🔧 Installiere Abhängigkeiten..."
    sudo apt update | tee -a "$LOGFILE"
    sudo apt install -y $PYTHON_BIN $PYTHON_BIN-venv abcde flac lame vorbis-tools cd-discid eyed3 python3-mutagen python3-pip libmagic1 git curl nginx | tee -a "$LOGFILE"
}

### Projektstruktur & WebUI aufbauen
setup_project() {
    step "📁 Erstelle Projektverzeichnis..."
    sudo rm -rf "$INSTALL_DIR"
    sudo mkdir -p "$INSTALL_DIR"
    sudo chown "$RUN_USER:$RUN_USER" "$INSTALL_DIR"

    step "🐍 Richte virtuelles Python-Umfeld ein..."
    $PYTHON_BIN -m venv "$INSTALL_DIR/venv"
    source "$INSTALL_DIR/venv/bin/activate"

    step "📦 Installiere Backend-Abhängigkeiten..."
    pip install --upgrade pip | tee -a "$LOGFILE"
    pip install flask pyyaml mutagen eyed3 python-magic requests flask-cors | tee -a "$LOGFILE"

    step "⬇️ Lade WebUI herunter..."
    git clone https://github.com/chr-braun/rpi-cdripper.git "$INSTALL_DIR/webui" | tee -a "$LOGFILE"

    step "🏗️ Baue WebUI..."
    cd "$INSTALL_DIR/webui"
    npm install | tee -a "$LOGFILE"
    npm run build | tee -a "$LOGFILE"
}

### Backend und Konfiguration
setup_backend() {
    step "📝 Backend API vorbereiten..."
    cat > "$INSTALL_DIR/app.py" <<EOF
from flask import Flask, jsonify, request
from flask_cors import CORS
import yaml
import os
import subprocess
import time
import threading

# Lade Konfiguration
with open('config.yaml', 'r') as file:
    config = yaml.safe_load(file)

app = Flask(__name__)
CORS(app)

# Hilfsfunktionen
def start_ripping(formats, directory):
    try:
        command = ['abcde', '-d', '/dev/cdrom', '-o', *formats, '-p', directory]
        subprocess.run(command, check=True)
    except subprocess.CalledProcessError as e:
        return str(e)

def schedule_ripping():
    while True:
        current_time = time.strftime("%H:%M")
        if current_time == config['scheduler']['time']:
            print("Automatisches Rippen startet...")
            start_ripping(config['output_formats'], config['output_directory'])
        time.sleep(60)

# API-Endpunkte
@app.route('/api/rip', methods=['POST'])
def rip_cd():
    formats = request.json.get('formats', ['mp3'])
    directory = request.json.get('directory', config['output_directory'])
    thread = threading.Thread(target=start_ripping, args=(formats, directory))
    thread.start()
    return jsonify({"status": "Rip started"}), 200

@app.route('/api/status', methods=['GET'])
def get_status():
    return jsonify({"status": "CDRipper is running"}), 200

@app.route('/api/config', methods=['GET'])
def get_config():
    return jsonify(config), 200

# Starten des Planers für automatisches Rippen
if config['scheduler']['enabled']:
    threading.Thread(target=schedule_ripping, daemon=True).start()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)
EOF

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
  enabled: true
  time: "22:00"
EOF
}

setup_nginx() {
    step "🌐 Konfiguriere NGINX für WebUI..."
    sudo tee /etc/nginx/sites-available/cdripper > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        root $INSTALL_DIR/webui/dist;
        index index.html;
        try_files \$uri /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
    sudo ln -sf /etc/nginx/sites-available/cdripper /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl restart nginx
}

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

    sudo systemctl daemon-reload
    sudo systemctl enable "$SERVICE_NAME"
    sudo systemctl start "$SERVICE_NAME"
}

### Hauptablauf
install_packages
setup_project
setup_backend
setup_nginx
setup_systemd_service

step "✅ CDRipper mit WebUI wurde erfolgreich installiert und ist über http://<IP-Adresse> erreichbar."
echo "👉 Installationslog: $LOGFILE"
