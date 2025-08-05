#!/bin/bash

# CoolBot Installation Script
# Installs Node-RED and required dependencies for CoolBot automation

set -e  # Exit on any error

echo "🌡️  CoolBot Installation Script"
echo "================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please do not run this script as root"
    exit 1
fi

# Check for Node.js
echo "📋 Checking prerequisites..."
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first:"
    echo "   curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -"
    echo "   sudo apt-get install -y nodejs"
    exit 1
fi

echo "✅ Node.js version: $(node --version)"
echo "✅ NPM version: $(npm --version)"

# Install Node-RED globally
echo ""
echo "📦 Installing Node-RED..."
npm install -g --unsafe-perm node-red

# Create Node-RED directory
echo "📁 Setting up Node-RED directory..."
mkdir -p ~/.node-red

# Install required Node-RED nodes
echo ""
echo "🔧 Installing Node-RED nodes..."
cd ~/.node-red

npm install node-red-contrib-home-assistant-websocket
npm install node-red-dashboard
npm install node-red-node-ui-table

# Create systemd service (optional)
read -p "🤖 Create systemd service for Node-RED? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📝 Creating systemd service..."
    
    sudo tee /etc/systemd/system/node-red.service > /dev/null <<EOF
[Unit]
Description=Node-RED graphical event wiring tool
Wants=network.target
Documentation=http://nodered.org/docs/

[Service]
Type=notify
User=$USER
ExecStart=/usr/bin/node-red --max-old-space-size=128 -v
Environment=NODE_ENV=production
Environment=NODE_PATH=/usr/lib/node_modules
WorkingDirectory=$HOME
Restart=on-failure
KillSignal=SIGINT
TimeoutStopSec=20
NotifyAccess=all
SyslogIdentifier=Node-RED

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable node-red
    
    echo "✅ Systemd service created. You can now use:"
    echo "   sudo systemctl start node-red"
    echo "   sudo systemctl stop node-red"
    echo "   sudo systemctl status node-red"
fi

# Copy flow files
echo ""
echo "📋 Setting up CoolBot flows..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -d "$PROJECT_DIR/node-red/flows" ]; then
    cp "$PROJECT_DIR/node-red/flows/"*.json ~/.node-red/ 2>/dev/null || true
    echo "✅ Flow files copied to Node-RED directory"
else
    echo "⚠️  Flow files not found. You'll need to import them manually."
fi

# Copy configuration
if [ -f "$PROJECT_DIR/node-red/config/settings.json" ]; then
    cp "$PROJECT_DIR/node-red/config/settings.json" ~/.node-red/coolbot-settings.json
    echo "✅ Configuration file copied"
fi

echo ""
echo "🎉 Installation complete!"
echo ""
echo "📚 Next steps:"
echo "1. Start Node-RED:"
if systemctl is-enabled node-red.service &>/dev/null; then
    echo "   sudo systemctl start node-red"
else
    echo "   node-red"
fi
echo ""
echo "2. Open Node-RED in your browser:"
echo "   http://localhost:1880"
echo ""
echo "3. Configure Home Assistant connection:"
echo "   - Go to the hamburger menu → Manage palette → Install"
echo "   - Search and install 'node-red-contrib-home-assistant-websocket'"
echo "   - Configure the Home Assistant server with your details"
echo ""
echo "4. Import the CoolBot flows:"
echo "   - Menu → Import → Select files from ~/.node-red/"
echo "   - Import coolbot-main-flow.json"
echo "   - Import coolbot-dashboard.json"
echo "   - Import coolbot-safety.json"
echo ""
echo "5. Update entity IDs to match your Home Assistant setup"
echo ""
echo "6. Deploy the flows and test the system"
echo ""
echo "📖 See docs/setup-guide.md for detailed setup instructions"
echo ""
echo "⚠️  SAFETY REMINDER:"
echo "   This system controls AC equipment. Always test thoroughly"
echo "   and maintain manual overrides. Monitor the system closely"
echo "   during initial operation."