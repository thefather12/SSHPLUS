#!/usr/bin/env bash
# DragonX Manager - systemd + full menu
# Multi-port support
# Original author: Danilo (refactored for DragonX)

PROXY_DIR="$HOME/DragonX"
SERVICE_PREFIX="dragonx_port"
LOG_DIR="$PROXY_DIR/logs"
PORTS_FILE="$PROXY_DIR/ports.list"

mkdir -p "$LOG_DIR"
mkdir -p "$PROXY_DIR"

# Detect architecture automatically
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|i386|i686)
    BIN_NAME="dragon_go-x86"
    ;;
  aarch64|armv7l|armv6l|arm*)
    BIN_NAME="dragon_go-ARM"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

# Function to create/update a systemd service
update_service() {
    local PORT=$1
    local SERVICE_NAME="${SERVICE_PREFIX}_${PORT}.service"
    sudo tee /etc/systemd/system/$SERVICE_NAME > /dev/null <<EOF
[Unit]
Description=DragonX SSH Proxy (Port $PORT)
After=network.target

[Service]
Type=simple
WorkingDirectory=$PROXY_DIR
ExecStart=$PROXY_DIR/$BIN_NAME -port :$PORT
Restart=always
StandardOutput=file:$LOG_DIR/proxy_$PORT.log
StandardError=file:$LOG_DIR/proxy_$PORT.log

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable $SERVICE_NAME
}

# Start a port
start_port() {
    read -p "Enter proxy port (1-65535): " PORT
    while ! [[ $PORT =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); do
        echo "⚠️ Enter a valid port (1-65535)."
        read -p "Enter proxy port: " PORT
    done

    if ! grep -q "^$PORT$" "$PORTS_FILE" 2>/dev/null; then
        echo $PORT >> "$PORTS_FILE"
    fi

    update_service $PORT
    sudo systemctl start "${SERVICE_PREFIX}_${PORT}.service"
    echo "✅ DragonX started on port $PORT"
    read -p "Press ENTER to return to the menu..."
}

# Stop a port
stop_port() {
    read -p "Enter port to stop: " PORT
    local SERVICE_NAME="${SERVICE_PREFIX}_${PORT}.service"
    sudo systemctl stop "$SERVICE_NAME"
    echo "🛑 DragonX stopped on port $PORT"
    read -p "Press ENTER to return to the menu..."
}

# Restart a port
restart_port() {
    read -p "Enter port to restart: " PORT
    update_service $PORT
    sudo systemctl restart "${SERVICE_PREFIX}_${PORT}.service"
    echo "🔄 DragonX restarted on port $PORT"
    read -p "Press ENTER to return to the menu..."
}

# Remove all configured ports and services
uninstall_dragonx() {
    echo "❌ Removing DragonX..."
    if [ -f "$PORTS_FILE" ]; then
        while read -r PORT; do
            sudo systemctl stop "${SERVICE_PREFIX}_${PORT}.service"
            sudo systemctl disable "${SERVICE_PREFIX}_${PORT}.service"
            sudo rm -f "/etc/systemd/system/${SERVICE_PREFIX}_${PORT}.service"
        done < "$PORTS_FILE"
        rm -f "$PORTS_FILE"
    fi
    sudo systemctl daemon-reload
    rm -rf "$PROXY_DIR"
    sudo rm -f /usr/local/bin/dragonx
    echo "✅ DragonX removed successfully!"
    exit 0
}

# Main menu
menu() {
    clear
    echo "=============================="
    echo "           DragonX"
    echo "=============================="

    if [ -f "$PORTS_FILE" ]; then
        HAS_ACTIVE=0
        echo "Active ports:"
        while read -r PORT; do
            local SERVICE_NAME="${SERVICE_PREFIX}_${PORT}.service"
            if systemctl is-active --quiet "$SERVICE_NAME"; then
                echo " - Port $PORT (🟢 Active)"
                HAS_ACTIVE=1
            fi
        done < "$PORTS_FILE"

        if [ $HAS_ACTIVE -eq 0 ]; then
            echo "No active ports"
        fi
    else
        echo "No active ports"
    fi

    echo "------------------------------"
    echo "1) Start DragonX (add port)"
    echo "2) Stop DragonX (port)"
    echo "3) Restart DragonX (port)"
    echo "4) Uninstall DragonX"
    echo "5) Exit"
    echo "=============================="
    read -p "Choose an option: " option

    case $option in
        1) start_port ;;
        2) stop_port ;;
        3) restart_port ;;
        4) uninstall_dragonx ;;
        5) exit 0 ;;
        *) echo "Invalid option!"; sleep 1; menu ;;
    esac
}

# Menu loop
while true; do
    menu
done
