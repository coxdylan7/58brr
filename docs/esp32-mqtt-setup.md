# ESP32 MQTT CoolBot Setup Guide

## Overview

This guide covers the ESP32-based CoolBot system that uses MQTT for communication and includes a heating diode for AC thermostat spoofing.

## Hardware Requirements

### Required Components
- **ESP32 Development Board** (ESP32-WROOM-32 or similar)
- **2x DS18B20 Temperature Sensors** (waterproof recommended)
- **Relay Module** (5V/3.3V compatible, 10A+ rating for AC control)
- **Heating Element/Diode** (High-power resistor or heating element)
- **4.7kΩ Resistors** (2x for DS18B20 pull-ups)
- **MOSFET or Transistor** (for heating diode control, if needed)
- **Power Supply** (5V/3A minimum for ESP32 + relay + heating element)
- **Breadboard/PCB** for connections
- **Jumper Wires**

### Optional Components
- **IR LED + Receiver** (for AC remote control)
- **Temperature Sensor for Heating Diode** (monitoring)
- **Status LEDs**
- **Enclosure** (weatherproof if outdoor installation)

## Heating Diode Specifications

### Recommended Heating Elements
1. **High-Power Resistor**: 10-20Ω, 5-10W
2. **Ceramic Heating Element**: Small 12V ceramic heater
3. **Heating Wire**: Nichrome wire wrapped around heat sink
4. **Peltier Element**: TEC module in heating mode

### Power Requirements
- **Voltage**: 5V-12V (depending on element)
- **Current**: 500mA-2A typical
- **PWM Control**: 0-255 (8-bit resolution)
- **Placement**: Near AC internal thermostat sensor

## Pin Configuration

### ESP32 Pin Assignments
```
GPIO4  - Room Temperature Sensor (DS18B20)
GPIO5  - Coil Temperature Sensor (DS18B20)
GPIO12 - AC Relay Control
GPIO25 - Heating Diode PWM Output
GPIO2  - Status LED (built-in)
GPIO14 - IR Transmitter (optional)
GPIO15 - IR Receiver (optional)
GPIO26 - Heating Diode Temperature Feedback (optional)
```

### Wiring Diagram
```
ESP32                    Components
-----                    ----------
GPIO4  ───── 4.7kΩ ───── VCC
   │                      │
   └────────────────── DS18B20 (Room)
                         │
                        GND

GPIO5  ───── 4.7kΩ ───── VCC
   │                      │
   └────────────────── DS18B20 (Coil)
                         │
                        GND

GPIO12 ──────────────── Relay IN
                         │
                    Relay Module
                    (Controls AC)

GPIO25 ──── MOSFET ──── Heating Element
              │              │
             GND            GND
```

## Software Setup

### Arduino IDE Configuration

1. **Install ESP32 Board Package**:
   ```
   File → Preferences → Additional Board Manager URLs:
   https://dl.espressif.com/dl/package_esp32_index.json
   ```

2. **Install Required Libraries**:
   ```
   Tools → Manage Libraries → Install:
   - PubSubClient (MQTT)
   - ArduinoJson
   - OneWire
   - DallasTemperature
   ```

3. **Board Settings**:
   ```
   Board: "ESP32 Dev Module"
   Upload Speed: "921600"
   CPU Frequency: "240MHz"
   Flash Size: "4MB"
   Partition Scheme: "Default 4MB"
   ```

### ESP32 Code Configuration

Edit the following in `coolbot_esp32.ino`:

```cpp
// WiFi Configuration
const char* ssid = "YOUR_WIFI_NETWORK";
const char* password = "YOUR_WIFI_PASSWORD";

// MQTT Broker Configuration  
const char* mqtt_server = "192.168.1.100"; // Your MQTT broker IP
const int mqtt_port = 1883;
const char* mqtt_user = "";                // Username if required
const char* mqtt_password = "";            // Password if required
```

## MQTT Broker Setup

### Option 1: Mosquitto on Raspberry Pi

1. **Install Mosquitto**:
   ```bash
   sudo apt update
   sudo apt install mosquitto mosquitto-clients
   ```

2. **Configure Mosquitto**:
   ```bash
   sudo nano /etc/mosquitto/mosquitto.conf
   ```
   Add:
   ```
   listener 1883
   allow_anonymous true
   persistence true
   persistence_location /var/lib/mosquitto/
   log_dest file /var/log/mosquitto/mosquitto.log
   ```

3. **Start Mosquitto**:
   ```bash
   sudo systemctl enable mosquitto
   sudo systemctl start mosquitto
   ```

### Option 2: Docker MQTT Broker

```bash
docker run -it -p 1883:1883 -v $(pwd)/mosquitto.conf:/mosquitto/config/mosquitto.conf eclipse-mosquitto
```

### Testing MQTT Connection

```bash
# Subscribe to CoolBot topics
mosquitto_sub -h localhost -t "coolbot/#" -v

# Publish test message
mosquitto_pub -h localhost -t "coolbot/test" -m "Hello CoolBot"
```

## Node-RED MQTT Setup

### Install MQTT Nodes

```bash
cd ~/.node-red
npm install node-red-contrib-mqtt-broker
```

### Configure MQTT Broker in Node-RED

1. **Add MQTT Broker Configuration**:
   - Server: `localhost` (or broker IP)
   - Port: `1883`
   - Client ID: `coolbot_nodered`

2. **Import MQTT Flows**:
   - `coolbot-mqtt-flow.json` - Main MQTT automation
   - `coolbot-mqtt-dashboard.json` - MQTT dashboard

## Heating Diode Installation

### Physical Installation

1. **Location**: Place near AC's internal thermostat sensor
2. **Mounting**: Use thermal adhesive or small bracket
3. **Insulation**: Ensure proper heat transfer to thermostat
4. **Safety**: Avoid blocking airflow or overheating

### Calibration Process

1. **Initial Testing**:
   ```
   Set heating diode to 50% (127/255)
   Monitor AC internal temperature reading
   Adjust intensity until AC thinks it's ~80°F
   ```

2. **Fine Tuning**:
   ```
   Test different intensities
   Verify AC runs continuously
   Ensure no overheating
   Document optimal settings
   ```

### Safety Considerations

- **Temperature Monitoring**: Monitor heating element temperature
- **Current Limiting**: Use appropriate MOSFET/transistor
- **Thermal Protection**: Include thermal fuse if possible
- **Regular Inspection**: Check for overheating or damage

## System Testing

### Pre-Deployment Tests

1. **ESP32 Connectivity**:
   ```bash
   # Check ESP32 heartbeat
   mosquitto_sub -h localhost -t "coolbot/esp32/heartbeat"
   
   # Monitor temperature readings
   mosquitto_sub -h localhost -t "coolbot/sensors/+"
   ```

2. **Relay Control**:
   ```bash
   # Test AC relay
   mosquitto_pub -h localhost -t "coolbot/controls/ac_plug" -m '{"command":"on"}'
   mosquitto_pub -h localhost -t "coolbot/controls/ac_plug" -m '{"command":"off"}'
   ```

3. **Heating Diode Control**:
   ```bash
   # Test heating diode
   mosquitto_pub -h localhost -t "coolbot/controls/heating_diode" -m '{"enabled":true,"intensity":200}'
   mosquitto_pub -h localhost -t "coolbot/controls/heating_diode" -m '{"enabled":false,"intensity":0}'
   ```

### Operational Testing

1. **Temperature Response**:
   - Verify room temperature readings
   - Check coil temperature accuracy
   - Test freeze protection triggers

2. **Automation Logic**:
   - Set target temperature above room temp
   - Verify AC turns on with heating diode
   - Test freeze protection shutdown

3. **Dashboard Functionality**:
   - Access: `http://localhost:1880/ui`
   - Test all controls and displays
   - Verify emergency stop works

## Troubleshooting

### Common ESP32 Issues

**WiFi Connection Problems**:
```cpp
// Add to setup() for debugging
WiFi.setHostname("coolbot-esp32");
WiFi.begin(ssid, password);
Serial.print("Connecting to WiFi");
while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
}
```

**MQTT Connection Issues**:
- Check broker IP and port
- Verify network connectivity
- Check broker logs: `sudo tail -f /var/log/mosquitto/mosquitto.log`

**Temperature Sensor Issues**:
- Verify wiring and pull-up resistors
- Check sensor addresses: `roomTempSensor.getAddress()`
- Test with simple OneWire scan

### Heating Diode Issues

**Not Heating**:
- Check PWM output with multimeter
- Verify MOSFET/transistor operation
- Test heating element resistance

**Overheating**:
- Reduce PWM intensity
- Improve heat dissipation
- Check for short circuits

**AC Not Responding**:
- Verify placement near thermostat
- Increase heating intensity gradually
- Check AC internal settings

### Node-RED MQTT Issues

**No Data Received**:
- Check MQTT broker status
- Verify topic names match
- Test with mosquitto_sub

**Dashboard Not Updating**:
- Check flow connections
- Verify MQTT broker configuration
- Look for JavaScript errors in browser

## Maintenance

### Regular Checks
- **Weekly**: Monitor temperature accuracy
- **Monthly**: Check heating element condition
- **Seasonally**: Clean sensors and connections

### Monitoring
- **ESP32 Status**: Check uptime and WiFi signal
- **Temperature Trends**: Log data for analysis
- **Heating Element**: Monitor power consumption

### Updates
- **ESP32 Firmware**: Update when needed
- **Node-RED Flows**: Backup before changes
- **MQTT Broker**: Keep updated for security

## Advanced Configuration

### Custom Heating Control

```cpp
// Add PID control for heating diode
float targetTemp = 80.0; // Target spoofing temperature
float currentTemp = getACInternalTemp();
float error = targetTemp - currentTemp;
int pwmOutput = constrain(previousPWM + (error * kP), 0, 255);
```

### Data Logging

```javascript
// Add to Node-RED flow for data logging
const data = {
    timestamp: Date.now(),
    room_temp: msg.payload.room_temp,
    coil_temp: msg.payload.coil_temp,
    ac_status: msg.payload.ac_status
};
```

### Remote Monitoring

- Set up VPN for remote access
- Configure MQTT over SSL/TLS
- Add email/SMS alerts for critical events

## Safety Reminders

⚠️ **Critical Safety Points**:
- Always maintain manual AC shutoff capability
- Monitor heating element temperature
- Test all safety systems regularly
- Have emergency procedures documented
- Never leave system unattended during initial testing

This system controls critical cooling equipment. Prioritize safety and have multiple fail-safes in place.