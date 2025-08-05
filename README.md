# 58brr - CoolBot-Style AC Automation

A Node-RED based automation system that replicates CoolBot functionality to safely cool a room down to ~30°F using a standard window AC unit that normally cannot go below 60°F.

## 🚀 Quick Start (Easy Setup!)

**Want to get started fast?** → **[📖 Read the QUICK-START Guide](QUICK-START.md)**

The quick start guide walks you through:
1. Getting the code (5 minutes)
2. One-command installation (15 minutes) 
3. Node-RED setup with clear screenshots
4. Hardware wiring and ESP32 configuration
5. Testing and troubleshooting

## 🏗️ System Architecture

**ESP32 Hub** → **MQTT** → **Node-RED** → **Web Dashboard**

- **ESP32**: Controls temperature sensors, AC relay, and heating diode
- **MQTT**: Reliable communication between components
- **Node-RED**: Automation logic with safety systems
- **Dashboard**: Real-time monitoring and control interface

## ✨ Key Features

### Core Functionality
- ✅ **Smart AC Control**: Turns standard AC on/off via relay
- ✅ **Dual Temperature Monitoring**: Room + coil sensors with DS18B20
- ✅ **Freeze Protection**: Automatic shutdown at 33°F coil temperature
- ✅ **Heating Diode**: PWM-controlled element spoofs AC thermostat
- ✅ **Target Control**: Cool to 30°F (or any temperature 25-45°F)

### Safety & Reliability  
- ✅ **Hysteresis Logic**: Prevents short cycling damage
- ✅ **Minimum Off Time**: 8-minute compressor protection
- ✅ **Runtime Limits**: 4-hour maximum with warnings
- ✅ **ESP32 Monitoring**: Online/offline detection with auto-recovery
- ✅ **Emergency Stop**: Immediate shutdown via dashboard
- ✅ **Sensor Validation**: Range checking and error handling

### User Interface
- ✅ **Web Dashboard**: Works on desktop, tablet, mobile
- ✅ **Real-time Gauges**: Temperature monitoring with color coding
- ✅ **Manual Controls**: Target temp, hysteresis, heating intensity
- ✅ **Status Indicators**: System state, WiFi strength, device health
- ✅ **Helper Scripts**: Easy start/stop commands

## 📦 What's Included

```
📁 Complete CoolBot System
├── 🤖 ESP32 Arduino Code (ready to upload)
├── 🔄 Node-RED Flows (automation + dashboard)  
├── 📡 MQTT Configuration (topic structure)
├── 🛠️ Installation Scripts (one-command setup)
├── 📚 Documentation (step-by-step guides)
└── 🆘 Troubleshooting (common issues + solutions)
```

## 🎯 How It Works

### The CoolBot Method
1. **Bypass AC Limits**: Standard ACs stop cooling at ~60°F
2. **Heating Diode Trick**: Small heater near AC's internal thermostat makes it think it's warm
3. **External Control**: ESP32 monitors actual room temperature and controls AC power
4. **Freeze Protection**: Monitors evaporator coil to prevent ice damage
5. **Result**: Room cools to 30°F safely with any standard AC unit

### Automation Logic
```
IF room_temp > (target + hysteresis) AND coil_temp > 36°F:
    → Turn ON AC + heating diode
    
IF coil_temp ≤ 33°F OR room_temp ≤ target:
    → Turn OFF AC + heating diode
    
ALWAYS: Monitor for ESP32 offline, sensor errors, runtime limits
```

## 💡 Why This Approach?

### Advantages Over Original CoolBot
- **Open Source**: Modify and customize as needed
- **Modern Tech**: ESP32 + MQTT + Node-RED stack
- **Web Dashboard**: Monitor from anywhere on your network
- **Integrated Safety**: Multiple fail-safes built in
- **Cost Effective**: ~$30 in parts vs $300+ commercial units
- **Learning Platform**: Understand how it works

### Hardware Requirements
- **ESP32 Dev Board** (~$10)
- **2x DS18B20 Temperature Sensors** (~$5 each)
- **Relay Module** (~$3)
- **Heating Element/Resistor** (~$5)
- **Misc Components** (resistors, wires, etc.)

## 📋 Installation Overview

### Super Simple Process
1. **Download/clone** this repository
2. **Run the installer**: `./scripts/install-mqtt.sh`
3. **Import flows** into Node-RED (3 clicks)
4. **Configure ESP32** with your WiFi
5. **Wire hardware** following the diagrams
6. **Test system** before connecting real AC

**Total time: ~1 hour including hardware setup**

## 🌡️ Safety Features

This system includes multiple safety layers:

### Critical Protection
- **Coil Freeze Monitor**: Shuts down at 33°F
- **Sensor Validation**: Checks for reasonable values
- **Communication Watchdog**: Stops if ESP32 goes offline
- **Emergency Stop**: Manual override always available
- **Runtime Limits**: Prevents compressor damage

### User Safety
- **Clear Documentation**: Step-by-step safety procedures
- **Testing Protocols**: Verify all systems before AC connection
- **Status Monitoring**: Real-time system health display
- **Alert System**: Warnings for potential issues

## 📖 Documentation

- **[🚀 QUICK-START Guide](QUICK-START.md)** - Get up and running fast
- **[🔧 ESP32 Setup](docs/esp32-mqtt-setup.md)** - Hardware and MQTT details  
- **[⚙️ Technical Details](docs/technical-details.md)** - System architecture
- **[🆘 Troubleshooting](docs/esp32-mqtt-setup.md#troubleshooting)** - Common issues

## 🎛️ Dashboard Preview

The web dashboard provides:
- **Temperature Gauges**: Room, coil, heating diode
- **Control Sliders**: Target temp, hysteresis, heating intensity
- **Status LEDs**: AC running, ESP32 online, heating active
- **WiFi Monitor**: Signal strength and connectivity
- **Emergency Controls**: Stop button and system reset

Access at: `http://localhost:1880/ui`

## ⚠️ Important Safety Notes

**This system controls AC equipment. Always:**
- Test thoroughly before connecting to real AC
- Maintain manual shutoff capability
- Monitor system during initial operation
- Follow all local electrical codes
- Have emergency procedures documented

**Not recommended for:**
- Critical applications (food storage, etc.)
- Unattended operation (until proven reliable)
- Systems without manual overrides

## 🤝 Support & Community

- **Issues**: Use GitHub issues for bugs/questions
- **Documentation**: All guides included in `docs/`
- **Examples**: Working configurations in `node-red/`
- **Updates**: Watch repository for improvements

---

**🎉 Ready to build your CoolBot? Start with the [Quick Start Guide](QUICK-START.md)!** 
