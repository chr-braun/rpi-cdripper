#!/bin/bash
set -e

echo "🧼 Entferne CDRipper Headless-Installation..."

SERVICE_FILE="/etc/systemd/system/cdripper.service"
INSTALL_DIR="/opt/cdripper"

echo "🛑 Stoppe Systemdienst (falls aktiv)..."
sudo systemctl stop cdripper || true
sudo systemctl disable cdripper || true

echo "🗑️ Entferne Systemdienst..."
sudo rm -f "$SERVICE_FILE"
sudo systemctl daemon-reload

echo "🧹 Entferne Installationsverzeichnis..."
sudo rm -rf "$INSTALL_DIR"

echo "✅ Deinstallation abgeschlossen."
