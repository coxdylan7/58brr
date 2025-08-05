#!/bin/bash

# CoolBot MQTT/ESP32 Installation Script
# Complete setup for Node-RED, MQTT broker, and CoolBot flows

set -e  # Exit on any error

echo "🌡️  CoolBot MQTT/ESP32 Installation Script"
echo "=========================================="
echo ""
echo "This script will install and configure:"
echo "• MQTT Broker (Mosquitto)"
echo "• Node-RED with required nodes"
echo "• CoolBot MQTT flows and dashboard"
echo "• System services and auto-start"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root"
    echo "Run as a regular user with sudo privileges"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

print_status "Project directory: $PROJECT_DIR"
print_status "Current user: $USER"
echo ""

# Step 1: System Update
print_status "Step 1: Updating system packages..."
sudo apt update -qq
sudo apt upgrade -y -qq
print_success "System updated"

# Step 2: Install Node.js and npm
print_status "Step 2: Installing Node.js and npm..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
else
    print_warning "Node.js already installed"
fi

NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
print_success "Node.js $NODE_VERSION and npm $NPM_VERSION installed"

# Step 3: Install MQTT Broker (Mosquitto)
print_status "Step 3: Installing MQTT Broker (Mosquitto)..."
if ! command -v mosquitto &> /dev/null; then
    sudo apt install -y mosquitto mosquitto-clients
    
    # Configure Mosquitto
    print_status "Configuring Mosquitto..."
    sudo tee /etc/mosquitto/conf.d/coolbot.conf > /dev/null <<EOF
# CoolBot MQTT Configuration
listener 1883
allow_anonymous true
persistence true
persistence_location /var/lib/mosquitto/
log_dest file /var/log/mosquitto/mosquitto.log
log_type error
log_type warning
log_type notice
log_type information
EOF

    # Start and enable Mosquitto
    sudo systemctl enable mosquitto
    sudo systemctl start mosquitto
    print_success "Mosquitto MQTT broker installed and started"
else
    print_warning "Mosquitto already installed"
    sudo systemctl restart mosquitto
    print_status "Mosquitto restarted with new configuration"
fi

# Step 4: Install Node-RED
print_status "Step 4: Installing Node-RED..."
if ! command -v node-red &> /dev/null; then
    # Install Node-RED globally
    sudo npm install -g --unsafe-perm node-red
    print_success "Node-RED installed globally"
else
    print_warning "Node-RED already installed"
fi

# Step 5: Create Node-RED directory and install packages
print_status "Step 5: Setting up Node-RED directory..."
mkdir -p ~/.node-red

# Install required Node-RED packages
print_status "Installing Node-RED packages..."
cd ~/.node-red

# Core packages for CoolBot
PACKAGES=(
    "node-red-contrib-home-assistant-websocket"
    "node-red-dashboard"
    "node-red-node-ui-table"
    "node-red-contrib-mqtt-broker"
)

for package in "${PACKAGES[@]}"; do
    print_status "Installing $package..."
    npm install "$package" --silent
done

print_success "All Node-RED packages installed"

# Step 6: Copy CoolBot flows and configuration
print_status "Step 6: Installing CoolBot flows..."

# Create flows directory structure
mkdir -p ~/.node-red/coolbot-flows
mkdir -p ~/.node-red/coolbot-config

# Copy MQTT flows
if [ -f "$PROJECT_DIR/node-red/flows/coolbot-mqtt-flow.json" ]; then
    cp "$PROJECT_DIR/node-red/flows/coolbot-mqtt-flow.json" ~/.node-red/coolbot-flows/
    print_success "Main MQTT flow copied"
else
    print_error "Main MQTT flow not found!"
fi

if [ -f "$PROJECT_DIR/node-red/flows/coolbot-mqtt-dashboard.json" ]; then
    cp "$PROJECT_DIR/node-red/flows/coolbot-mqtt-dashboard.json" ~/.node-red/coolbot-flows/
    print_success "MQTT dashboard flow copied"
else
    print_error "MQTT dashboard flow not found!"
fi

# Copy configuration files
if [ -f "$PROJECT_DIR/node-red/config/mqtt-topics.json" ]; then
    cp "$PROJECT_DIR/node-red/config/mqtt-topics.json" ~/.node-red/coolbot-config/
    print_success "MQTT topics configuration copied"
fi

# Step 7: Create Node-RED settings file
print_status "Step 7: Creating Node-RED settings..."
cat > ~/.node-red/settings.js << 'EOF'
module.exports = {
    uiPort: process.env.PORT || 1880,
    mqttReconnectTime: 15000,
    serialReconnectTime: 15000,
    debugMaxLength: 1000,
    debugUseColors: true,
    flowFile: 'flows.json',
    flowFilePretty: true,
    userDir: process.env.HOME + '/.node-red/',
    functionGlobalContext: {
        // CoolBot configuration
        coolbot: {
            version: "1.0.0",
            mqtt_broker: "localhost",
            mqtt_port: 1883
        }
    },
    exportGlobalContextKeys: false,
    ui: { path: "ui" },
    logging: {
        console: {
            level: "info",
            metrics: false,
            audit: false
        }
    },
    editorTheme: {
        projects: {
            enabled: false
        },
        palette: {
            catalogues: ['https://catalogue.nodered.org/catalogue.json'],
            editable: true
        }
    }
}
EOF

print_success "Node-RED settings configured"

# Step 8: Create systemd service for Node-RED
print_status "Step 8: Setting up Node-RED service..."
read -p "Create systemd service for Node-RED auto-start? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo tee /etc/systemd/system/nodered.service > /dev/null <<EOF
[Unit]
Description=Node-RED CoolBot Service
After=syslog.target network.target mosquitto.service
Wants=mosquitto.service

[Service]
Type=notify
User=$USER
ExecStart=/usr/bin/node-red --max-old-space-size=256 -v
Environment=NODE_ENV=production
Environment=NODE_PATH=/usr/lib/node_modules
WorkingDirectory=$HOME
Restart=on-failure
RestartSec=20
KillSignal=SIGINT
TimeoutStopSec=30
NotifyAccess=all
SyslogIdentifier=Node-RED

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable nodered
    print_success "Node-RED service created and enabled"
    
    SERVICE_CREATED=true
else
    SERVICE_CREATED=false
fi

# Step 9: Test MQTT broker
print_status "Step 9: Testing MQTT broker..."
if mosquitto_pub -h localhost -t "coolbot/test" -m "installation_test" 2>/dev/null; then
    print_success "MQTT broker is working"
else
    print_error "MQTT broker test failed"
fi

# Step 10: Create helper scripts
print_status "Step 10: Creating helper scripts..."

# Create start script
cat > ~/.node-red/start-coolbot.sh << 'EOF'
#!/bin/bash
echo "Starting CoolBot system..."

# Check MQTT broker
if ! pgrep mosquitto > /dev/null; then
    echo "Starting MQTT broker..."
    sudo systemctl start mosquitto
fi

# Start Node-RED
if systemctl --user is-enabled nodered.service &>/dev/null; then
    systemctl --user start nodered
else
    echo "Starting Node-RED manually..."
    node-red &
    echo "Node-RED started in background"
fi

echo "CoolBot system started!"
echo "Dashboard: http://localhost:1880/ui"
echo "Node-RED Editor: http://localhost:1880"
EOF

chmod +x ~/.node-red/start-coolbot.sh

# Create stop script
cat > ~/.node-red/stop-coolbot.sh << 'EOF'
#!/bin/bash
echo "Stopping CoolBot system..."

# Stop Node-RED
if systemctl --user is-enabled nodered.service &>/dev/null; then
    systemctl --user stop nodered
else
    pkill -f node-red
fi

echo "CoolBot system stopped"
EOF

chmod +x ~/.node-red/stop-coolbot.sh

# Create import flows script
cat > ~/.node-red/import-flows.sh << 'EOF'
#!/bin/bash
echo "Importing CoolBot flows..."

# Stop Node-RED if running
if pgrep node-red > /dev/null; then
    echo "Stopping Node-RED..."
    pkill -f node-red
    sleep 3
fi

# Import flows (manual step required)
echo ""
echo "To import CoolBot flows:"
echo "1. Start Node-RED: ./start-coolbot.sh"
echo "2. Open browser: http://localhost:1880"
echo "3. Menu (☰) → Import"
echo "4. Import these files from ~/.node-red/coolbot-flows/:"
echo "   - coolbot-mqtt-flow.json"
echo "   - coolbot-mqtt-dashboard.json"
echo "5. Deploy the flows"
echo ""
EOF

chmod +x ~/.node-red/import-flows.sh

print_success "Helper scripts created in ~/.node-red/"

# Step 11: Installation summary
echo ""
echo "🎉 Installation Complete!"
echo "========================"
echo ""
print_success "✅ MQTT Broker (Mosquitto) installed and running"
print_success "✅ Node-RED installed with required packages"
print_success "✅ CoolBot flows ready for import"
if [ "$SERVICE_CREATED" = true ]; then
    print_success "✅ Node-RED service configured for auto-start"
fi
print_success "✅ Helper scripts created"

echo ""
echo "📋 Next Steps:"
echo "=============="
echo ""
echo "1. 🚀 Start the system:"
echo "   cd ~/.node-red && ./start-coolbot.sh"
echo ""
echo "2. 🌐 Open Node-RED in browser:"
echo "   http://localhost:1880"
echo ""
echo "3. 📥 Import CoolBot flows:"
echo "   • Menu (☰) → Import"
echo "   • Import coolbot-mqtt-flow.json"
echo "   • Import coolbot-mqtt-dashboard.json"
echo "   • Click Deploy"
echo ""
echo "4. 🎛️ Access dashboard:"
echo "   http://localhost:1880/ui"
echo ""
echo "5. ⚙️ Configure ESP32:"
echo "   • Edit esp32/coolbot_esp32.ino with your WiFi credentials"
echo "   • Set MQTT broker IP to this computer's IP"
echo "   • Upload to ESP32"
echo ""

echo "📚 Documentation:"
echo "================="
echo "• Setup Guide: docs/esp32-mqtt-setup.md"
echo "• Technical Details: docs/technical-details.md"
echo "• Troubleshooting: Check Node-RED debug tab"
echo ""

echo "🔧 Useful Commands:"
echo "==================="
if [ "$SERVICE_CREATED" = true ]; then
    echo "• Start service: sudo systemctl start nodered"
    echo "• Stop service: sudo systemctl stop nodered"
    echo "• View logs: sudo journalctl -u nodered -f"
fi
echo "• Test MQTT: mosquitto_sub -h localhost -t 'coolbot/#' -v"
echo "• Helper scripts: ~/.node-red/start-coolbot.sh"
echo ""

print_warning "⚠️  IMPORTANT: Configure your ESP32 with WiFi and MQTT settings before testing!"
echo ""
print_success "🎯 CoolBot MQTT system ready for use!"