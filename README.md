===============================================================
📦 CDRipper – Installationsanleitung / Installation Guide
===============================================================

Inhalt:
1. 🇩🇪 Anleitung auf Deutsch
2. 🇬🇧 Instructions in English
3. Copyright & License

===============================================================
🇩🇪 INSTALLATION (Deutsch)
===============================================================

Voraussetzungen:
- Raspberry Pi OS (empfohlen: Lite oder Desktop)
- Internetverbindung
- CD-Laufwerk (USB)
- Git installiert (z.B.: sudo apt install git)

---------------------------------------------------------------
1. Repository klonen
---------------------------------------------------------------

    git clone https://github.com/chr-braun/rpi-cdripper.git
    cd rpi-cdripper

---------------------------------------------------------------
2. Installationsskript ausführbar machen
---------------------------------------------------------------

    chmod +x install_cdripper.sh

---------------------------------------------------------------
3. Installation starten
---------------------------------------------------------------

    ./install_cdripper.sh

Die Installation richtet automatisch alle benötigten Pakete,
Konfigurationen, Systemdienste und Zielverzeichnisse ein.

---------------------------------------------------------------
4. CD-Ripping starten (automatisch)
---------------------------------------------------------------

Legen Sie einfach eine CD ein – der Dienst erkennt sie automatisch
und beginnt mit dem Rippen.

Die gerippten Dateien werden im konfigurierten Zielverzeichnis
gespeichert (siehe config.yaml unter /opt/cdripper/).

---------------------------------------------------------------
5. Logs ansehen
---------------------------------------------------------------

    journalctl -u cdripper -f

---------------------------------------------------------------
6. Deinstallation (optional)
---------------------------------------------------------------

    chmod +x uninstall_cdripper.sh
    ./uninstall_cdripper.sh

===============================================================
🇬🇧 INSTALLATION (English)
===============================================================

Requirements:
- Raspberry Pi OS (Lite or Desktop recommended)
- Internet connection
- CD drive (USB)
- Git installed (e.g., sudo apt install git)

---------------------------------------------------------------
1. Clone the repository
---------------------------------------------------------------

    git clone https://github.com/chr-braun/rpi-cdripper.git
    cd rpi-cdripper

---------------------------------------------------------------
2. Make the installer executable
---------------------------------------------------------------

    chmod +x install_cdripper.sh

---------------------------------------------------------------
3. Start the installation
---------------------------------------------------------------

    ./install_cdripper.sh

This will automatically install all required packages,
configure system services, and set up the necessary configuration files 
and directories.

---------------------------------------------------------------
4. Start CD ripping (automatic)
---------------------------------------------------------------

Simply insert an audio CD – the service detects it automatically
and starts ripping.

The ripped files will be saved in the configured output directory
(see config.yaml in /opt/cdripper/).

---------------------------------------------------------------
5. View logs
---------------------------------------------------------------

    journalctl -u cdripper -f

---------------------------------------------------------------
6. Uninstallation (optional)
---------------------------------------------------------------

    chmod +x uninstall_cdripper.sh
    ./uninstall_cdripper.sh

===============================================================
© 2023 chr-braun
===============================================================
Lizenz / License:
Dieses Projekt wird unter der Apache License, Version 2.0, zur freien Anpassung freigegeben.
Die Nutzung, Bearbeitung und Weitergabe erfolgt unter der Bedingung, dass der ursprüngliche Autor (chr-braun) genannt wird.
Weitere Details findest du in der Datei LICENSE oder unter:
https://www.apache.org/licenses/LICENSE-2.0
===============================================================
