#!/bin/sh
set -e

SERVICE_NAME="nordvpn-hotspot"
SCRIPT_PATH="/usr/local/bin/nordvpn-hotspot.sh"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}.service"

echo "Creating hotspot script..."

cat << 'EOF' | sudo tee "$SCRIPT_PATH" > /dev/null
#!/bin/bash
set -e

nmcli connection show "Hotspot" &>/dev/null && exit 0
nordvpn set firewall disabled
nordvpn meshnet peer connect <peer>
nmcli device wifi hotspot \
  ssid raspberry-hotspot \
  password raspberrypi5 \
  ifname wlan0
EOF

sudo chmod +x "$SCRIPT_PATH"

echo "Creating systemd service..."

cat << EOF | sudo tee "$SERVICE_PATH" > /dev/null
[Unit]
Description=NordVPN Meshnet + WiFi Hotspot
After=network-online.target NetworkManager.service nordvpnd.service
Wants=network-online.target
Requires=NetworkManager.service nordvpnd.service

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
User=root

Restart=on-failure
RestartSec=5
StartLimitIntervalSec=0
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd and enabling service..."

sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl restart "$SERVICE_NAME"

echo "Done."
echo
echo "Check status with:"
echo "  systemctl status $SERVICE_NAME"
echo "  journalctl -u $SERVICE_NAME -f"
