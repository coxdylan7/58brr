# 🚀 CoolBot Quick Start Guide

## What You'll Build
A CoolBot system that cools a room to 30°F using:
- **ESP32** controlling temperature sensors and AC relay
- **Heating diode** to spoof the AC thermostat  
- **Node-RED** for automation logic and web dashboard
- **MQTT** for communication between components

## ⏱️ Time Required
- **Installation**: 15-20 minutes
- **Hardware setup**: 30-45 minutes
- **Testing**: 15-30 minutes

---

## 📁 Step 1: Get the Code

### Option A: Download ZIP
1. Download this project as ZIP
2. Extract to a folder like `/home/pi/coolbot/` or `~/coolbot/`

### Option B: Git Clone
```bash
git clone <repository-url> ~/coolbot
cd ~/coolbot
```

**📂 Your directory should look like:**
```
~/coolbot/
├── scripts/
│   └── install-mqtt.sh     ← Installation script
├── node-red/
│   ├── flows/              ← Node-RED automation flows
│   └── config/             ← MQTT configuration
├── esp32/
│   └── coolbot_esp32.ino   ← ESP32 Arduino code
└── docs/                   ← Documentation
```

---

## 🛠️ Step 2: Run Installation

### Simple One-Command Install
```bash
cd ~/coolbot
./scripts/install-mqtt.sh
```

### What This Installs
- ✅ **MQTT Broker** (Mosquitto) - handles communication
- ✅ **Node-RED** - automation engine and dashboard
- ✅ **Required packages** - all Node-RED nodes needed
- ✅ **CoolBot flows** - ready-to-import automation
- ✅ **Helper scripts** - easy start/stop commands
- ✅ **System service** - auto-start on boot (optional)

### Installation Output
The script will show colored progress:
- 🔵 **[INFO]** - Current step
- 🟢 **[SUCCESS]** - Completed successfully  
- 🟡 **[WARNING]** - Minor issue, continuing
- 🔴 **[ERROR]** - Problem that needs attention

---

## 🌐 Step 3: Set Up Node-RED

### Start the System
```bash
cd ~/.node-red
./start-coolbot.sh
```

### Import CoolBot Flows
1. **Open Node-RED**: http://localhost:1880
2. **Click Menu** (☰ in top-right)
3. **Select Import**
4. **Import these files** (from `~/.node-red/coolbot-flows/`):
   - `coolbot-mqtt-flow.json`
   - `coolbot-mqtt-dashboard.json`
5. **Click Deploy** (red button)

### ✅ Verify Installation
- **Node-RED Editor**: http://localhost:1880
- **CoolBot Dashboard**: http://localhost:1880/ui
- **MQTT Test**: 
  ```bash
  mosquitto_sub -h localhost -t "coolbot/#" -v
  ```

---

## 🔧 Step 4: Hardware Setup

### ESP32 Wiring
```
ESP32 Pin    →  Component
─────────────────────────────────
GPIO4        →  Room temp sensor (DS18B20)
GPIO5        →  Coil temp sensor (DS18B20)  
GPIO12       →  AC relay control
GPIO25       →  Heating diode (PWM)
3.3V         →  Pull-up resistors (4.7kΩ)
GND          →  All grounds
```

### Configure ESP32 Code
1. **Open**: `esp32/coolbot_esp32.ino` in Arduino IDE
2. **Edit WiFi settings**:
   ```cpp
   const char* ssid = "YOUR_WIFI_NAME";
   const char* password = "YOUR_WIFI_PASSWORD";
   ```
3. **Set MQTT broker IP**:
   ```cpp
   const char* mqtt_server = "192.168.1.100";  // Your computer's IP
   ```
4. **Upload to ESP32**

### Find Your Computer's IP
```bash
hostname -I | awk '{print $1}'
```

---

## 🎯 Step 5: Test the System

### Check ESP32 Connection
```bash
mosquitto_sub -h localhost -t "coolbot/esp32/status" -v
```
*Should show ESP32 online status*

### Check Temperature Readings
```bash
mosquitto_sub -h localhost -t "coolbot/sensors/+" -v
```
*Should show room and coil temperatures*

### Test AC Control
```bash
# Turn AC on
mosquitto_pub -h localhost -t "coolbot/controls/ac_plug" -m '{"command":"on"}'

# Turn AC off  
mosquitto_pub -h localhost -t "coolbot/controls/ac_plug" -m '{"command":"off"}'
```

### Monitor Dashboard
- **Open**: http://localhost:1880/ui
- **Check**: Temperature gauges update
- **Test**: Controls work (sliders, buttons)

---

## 📱 Directory Layout After Installation

```
~/.node-red/                    ← Node-RED working directory
├── coolbot-flows/              ← CoolBot automation flows
│   ├── coolbot-mqtt-flow.json       ← Main automation logic
│   └── coolbot-mqtt-dashboard.json  ← Web dashboard
├── coolbot-config/             ← Configuration files
│   └── mqtt-topics.json            ← MQTT topic definitions
├── start-coolbot.sh            ← Start system script
├── stop-coolbot.sh             ← Stop system script
├── import-flows.sh             ← Flow import helper
├── settings.js                 ← Node-RED configuration
├── flows.json                  ← Active flows (after import)
└── node_modules/               ← Installed packages
```

---

## 🔧 Daily Operations

### Start System
```bash
cd ~/.node-red && ./start-coolbot.sh
```

### Stop System  
```bash
cd ~/.node-red && ./stop-coolbot.sh
```

### View Logs
```bash
# Node-RED logs (if using service)
sudo journalctl -u nodered -f

# MQTT broker logs
sudo tail -f /var/log/mosquitto/mosquitto.log
```

### Monitor MQTT Traffic
```bash
# All CoolBot messages
mosquitto_sub -h localhost -t "coolbot/#" -v

# Just temperature sensors
mosquitto_sub -h localhost -t "coolbot/sensors/+" -v
```

---

## 🌡️ Using the Dashboard

### Access
- **URL**: http://localhost:1880/ui
- **Mobile**: Works on phones/tablets too!

### Controls
- **Target Temperature**: Set desired room temp (25-45°F)
- **Hysteresis**: Temperature range before AC starts
- **Heating Diode**: Intensity control (0-255)
- **Emergency Stop**: Immediate shutdown button

### Monitoring
- **Temperature Gauges**: Room, coil, heating diode temps
- **Status LEDs**: AC on/off, ESP32 online, heating active
- **WiFi Signal**: ESP32 connection strength
- **Runtime**: How long AC has been running

---

## 🆘 Troubleshooting

### Node-RED Won't Start
```bash
# Check if port 1880 is in use
sudo netstat -tlnp | grep 1880

# Start manually with debug
node-red -v
```

### ESP32 Not Connecting
1. Check WiFi credentials in code
2. Verify MQTT broker IP address
3. Check ESP32 serial monitor for errors
4. Test ping to MQTT broker from ESP32 network

### No Temperature Readings
1. Check DS18B20 wiring and pull-up resistors
2. Verify sensor addresses in ESP32 code
3. Test sensors with simple Arduino sketch

### Dashboard Not Loading
1. Verify Node-RED is running: http://localhost:1880
2. Check flows are deployed (Deploy button should be grey)
3. Clear browser cache
4. Check for JavaScript errors in browser console

### MQTT Issues
```bash
# Test broker
mosquitto_pub -h localhost -t "test" -m "hello"
mosquitto_sub -h localhost -t "test"

# Check broker status
sudo systemctl status mosquitto

# Restart broker
sudo systemctl restart mosquitto
```

---

## 🎯 Success Checklist

Before using with real AC equipment:

- [ ] ✅ Node-RED dashboard loads and shows data
- [ ] ✅ ESP32 shows "online" in dashboard  
- [ ] ✅ Temperature readings are updating
- [ ] ✅ Manual AC relay control works via MQTT
- [ ] ✅ Heating diode responds to intensity changes
- [ ] ✅ Emergency stop button works
- [ ] ✅ All safety systems tested
- [ ] ✅ Temperature sensors properly placed on AC unit

---

## 📞 Getting Help

### Check These First
1. **Node-RED debug tab** - shows system messages
2. **Browser console** - for dashboard issues  
3. **ESP32 serial monitor** - for hardware issues
4. **MQTT logs** - for communication problems

### Common File Locations
- **Node-RED files**: `~/.node-red/`
- **MQTT config**: `/etc/mosquitto/conf.d/coolbot.conf`
- **System logs**: `/var/log/mosquitto/mosquitto.log`
- **Service status**: `sudo systemctl status nodered mosquitto`

### Documentation
- **Detailed setup**: `docs/esp32-mqtt-setup.md`
- **Technical details**: `docs/technical-details.md`
- **Troubleshooting**: Look for error patterns in logs

---

## ⚠️ Safety Reminder

This system controls AC equipment. Before connecting to real AC:

1. ✅ Test all safety systems (emergency stop, freeze protection)
2. ✅ Verify temperature sensor accuracy
3. ✅ Have manual AC shutoff readily available
4. ✅ Monitor system closely during initial operation
5. ✅ Never leave unattended until proven reliable

**🎉 Enjoy your CoolBot system! 🌡️**