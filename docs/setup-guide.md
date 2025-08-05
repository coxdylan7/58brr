# CoolBot Setup Guide

## Overview

This guide will help you set up the CoolBot-style AC automation system using Node-RED, Home Assistant, and your existing hardware.

## Prerequisites

### Required Hardware
- Standard window AC unit (any size)
- Two temperature sensors:
  - Room temperature sensor
  - AC evaporator coil temperature sensor (critical for freeze protection)
- Smart plug for AC power control
- Home Assistant installation
- Node-RED installation

### Optional Hardware
- Second smart plug for heating pad (to spoof AC thermostat)
- IR blaster (Broadlink or ESPHome) for AC mode control
- Heating pad (small ceramic or silicone pad)

## Installation Steps

### 1. Hardware Setup

#### Temperature Sensors
1. **Room Sensor**: Place in the center of the room, away from direct airflow
2. **Coil Sensor**: Mount on the AC evaporator coil (inside the unit)
   - This is CRITICAL for freeze protection
   - Use a waterproof sensor (DS18B20 recommended)
   - Secure with thermal tape or zip ties
   - Insulate sensor wire entry point

#### Smart Plugs
1. Connect AC unit to smart plug
2. Connect heating pad to second smart plug (if using)
3. Ensure smart plugs are added to Home Assistant

#### Optional: Heating Pad Setup
- Small heating pad placed near AC's internal thermostat
- Used to "trick" the AC into thinking it's warmer than it is
- Allows AC to run even when internal temp sensor reads cold

### 2. Home Assistant Configuration

1. Add the entities from `home-assistant/coolbot-entities.yaml` to your HA configuration
2. Update IP addresses and entity names to match your setup
3. Restart Home Assistant
4. Verify all entities are working:
   - `sensor.room_temp`
   - `sensor.coil_temp`
   - `switch.ac_plug`
   - `switch.heating_pad` (if using)

### 3. Node-RED Installation

1. Install Node-RED if not already installed:
   ```bash
   npm install -g node-red
   ```

2. Install required Node-RED nodes:
   ```bash
   npm install node-red-contrib-home-assistant-websocket
   npm install node-red-dashboard
   ```

3. Start Node-RED:
   ```bash
   node-red
   ```

### 4. Import Node-RED Flows

1. Open Node-RED interface (usually http://localhost:1880)
2. Import the flow files:
   - `node-red/flows/coolbot-main-flow.json` - Main automation logic
   - `node-red/flows/coolbot-dashboard.json` - Web dashboard
   - `node-red/flows/coolbot-safety.json` - Safety monitoring

3. Configure Home Assistant connection:
   - Add your Home Assistant server details
   - Generate a long-lived access token in HA
   - Update the "home-assistant" server configuration in Node-RED

4. Deploy the flows

### 5. Configuration

#### Entity Mapping
Update the entity IDs in the flows to match your Home Assistant setup:
- Room temperature sensor: `sensor.room_temp`
- Coil temperature sensor: `sensor.coil_temp`
- AC smart plug: `switch.ac_plug`
- Heating pad: `switch.heating_pad`
- IR blaster: `remote.ac_ir_blaster`

#### Temperature Settings
Default settings (can be changed via dashboard):
- Target temperature: 30°F
- Hysteresis: 2°F (AC starts at 32°F, stops at 30°F)
- Coil freeze threshold: 33°F
- Coil resume threshold: 36°F
- Minimum off time: 8 minutes
- Maximum runtime: 4 hours

## Operation

### Normal Operation
1. System monitors room and coil temperatures continuously
2. When room temperature > (target + hysteresis) AND coil temperature > 36°F:
   - Turn ON AC via smart plug
   - Optional: Turn ON heating pad
   - Optional: Send IR command to set AC mode
3. When coil temperature ≤ 33°F OR room temperature ≤ target:
   - Turn OFF AC
   - Wait minimum off time before allowing restart

### Safety Features
- **Freeze Protection**: Automatically shuts off AC if coil drops below 33°F
- **Sensor Monitoring**: Shuts off AC if sensors go offline
- **Runtime Limits**: Forces AC off after maximum runtime
- **Emergency Stop**: Manual emergency stop button in dashboard
- **Temperature Validation**: Checks for reasonable sensor values

### Dashboard Access
- Main dashboard: http://localhost:1880/ui
- Monitor temperatures, system status, and runtime
- Adjust target temperature and hysteresis
- Emergency controls and system reset

## Safety Considerations

### Critical Safety Points
1. **Coil Sensor Placement**: Must be properly secured to evaporator coil
2. **Sensor Redundancy**: Monitor sensor status - system shuts down if sensors fail
3. **Manual Override**: Always maintain ability to manually shut off AC
4. **Regular Monitoring**: Check system operation daily during initial setup

### Warning Signs
- Coil temperature dropping rapidly
- Ice formation on evaporator coil
- Unusual AC sounds or vibration
- Sensor readings that seem incorrect

### Emergency Procedures
1. Use emergency stop button in dashboard
2. Manually turn off AC power if needed
3. Check coil sensor placement if freeze protection activates frequently
4. Verify sensor readings make sense

## Troubleshooting

### Common Issues

#### AC Won't Start
- Check smart plug connectivity
- Verify sensor readings are valid
- Ensure minimum off time has passed
- Check emergency mode is not active

#### Frequent Freeze Protection
- Verify coil sensor placement
- Check coil sensor readings
- Consider adjusting freeze thresholds
- Ensure adequate airflow across coil

#### Sensor Errors
- Check sensor wiring and connections
- Verify sensors appear in Home Assistant
- Check MQTT topics if using MQTT sensors
- Restart sensors/ESP devices if needed

#### Dashboard Not Loading
- Verify Node-RED is running
- Check dashboard URL: http://localhost:1880/ui
- Ensure node-red-dashboard is installed
- Check browser console for errors

### Logs and Monitoring
- Node-RED debug tab shows system messages
- Home Assistant logs show sensor and device activity
- Safety monitoring flow logs all alerts
- Check system status in dashboard

## Customization

### Adjusting Thresholds
Temperature thresholds can be adjusted in:
1. Dashboard sliders (real-time changes)
2. Node-RED flow settings (permanent changes)
3. Configuration file values

### Adding Features
- Email/SMS notifications for alerts
- Data logging and charts
- Integration with other home automation
- Custom sensor types

### IR Control Setup
If using IR control:
1. Learn AC remote commands using Broadlink or ESPHome
2. Update IR command codes in the flows
3. Test IR commands manually first
4. Enable IR control in dashboard settings

## Maintenance

### Regular Checks
- Weekly: Verify sensor readings and system operation
- Monthly: Clean AC filters and check coil sensor
- Seasonally: Test all safety features and emergency stops

### Updates
- Keep Node-RED and plugins updated
- Monitor for Home Assistant updates
- Update sensor firmware if using ESP devices
- Backup flow configurations before changes

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review Node-RED and Home Assistant logs
3. Verify all hardware connections
4. Test individual components separately

Remember: This system controls critical cooling equipment. Always prioritize safety and have manual overrides available.