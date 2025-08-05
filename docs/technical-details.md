# CoolBot Technical Documentation

## System Architecture

The CoolBot automation system consists of three main components:

1. **Node-RED Flows** - Core automation logic
2. **Home Assistant** - Device integration and state management  
3. **Physical Hardware** - Sensors, smart plugs, and AC unit

## Automation Logic

### Core Decision Algorithm

The system uses a state machine approach with the following logic:

```
IF AC_STATUS == 'off':
    IF room_temp > (target + hysteresis) AND 
       coil_temp > coil_resume_threshold AND
       time_since_off > min_off_time:
        TURN_ON_AC()
        
IF AC_STATUS == 'on':
    IF coil_temp <= coil_freeze_threshold OR
       room_temp <= target OR
       runtime > max_runtime:
        TURN_OFF_AC()
```

### Temperature Thresholds

| Parameter | Default | Purpose |
|-----------|---------|---------|
| Target Temperature | 30°F | Desired room temperature |
| Hysteresis | 2°F | Prevents short cycling |
| Coil Freeze Threshold | 33°F | Emergency freeze protection |
| Coil Resume Threshold | 36°F | Safe restart temperature |

### Timing Controls

| Parameter | Default | Purpose |
|-----------|---------|---------|
| Minimum Off Time | 8 minutes | Compressor protection |
| Maximum Runtime | 4 hours | Safety limit |
| Sensor Check Interval | 5 minutes | Health monitoring |

## Flow Architecture

### Main Flow (`coolbot-main-flow.json`)

**Input Nodes:**
- `room-temp-in`: Monitors `sensor.room_temp`
- `coil-temp-in`: Monitors `sensor.coil_temp`
- `init-flow`: System initialization

**Processing Nodes:**
- `decision-logic`: Core automation algorithm
- `ac-control`: Smart plug control logic
- `status-display`: Status formatting for dashboard

**Output Nodes:**
- `call-service-ac`: Controls AC smart plug
- `call-service-heating`: Controls heating pad
- `call-service-ir`: Optional IR commands

### Dashboard Flow (`coolbot-dashboard.json`)

**UI Elements:**
- Temperature gauges (room and coil)
- Target temperature slider
- Hysteresis control
- System status indicators
- Emergency controls
- Settings toggles

**Control Nodes:**
- Setting update functions
- Emergency stop handler
- System reset logic

### Safety Flow (`coolbot-safety.json`)

**Monitoring Systems:**
- Sensor watchdog (every 5 minutes)
- Runtime monitor (every 10 minutes)  
- Temperature safety check (every 2 minutes)

**Safety Actions:**
- Automatic AC shutoff on sensor failure
- Runtime limit enforcement
- Critical temperature protection
- Alert notifications

## Data Flow

### Temperature Data Path
```
Sensor → Home Assistant → Node-RED → Decision Logic → Smart Plug
```

### Safety Monitoring Path
```
Sensors → Safety Checks → Alerts → Emergency Actions
```

### Dashboard Updates
```
Decision Logic → Status Format → Dashboard Display
```

## State Management

### Flow Variables

| Variable | Type | Purpose |
|----------|------|---------|
| `ac_status` | string | Current AC state ('on'/'off') |
| `room_temp` | number | Latest room temperature |
| `coil_temp` | number | Latest coil temperature |
| `target_temp` | number | User-set target temperature |
| `last_off_time` | timestamp | When AC was last turned off |
| `ac_start_time` | timestamp | When current cycle started |
| `emergency_mode` | boolean | Emergency stop activated |

### System States

1. **Initializing** - System starting up
2. **Monitoring** - Normal operation, AC off
3. **Cooling** - AC running normally
4. **Freeze Protection** - AC off due to low coil temp
5. **Target Reached** - AC off, room at target
6. **Emergency** - Manual emergency stop
7. **Sensor Error** - Sensor failure detected

## Safety Systems

### Primary Safety Features

1. **Freeze Protection**
   - Monitors coil temperature continuously
   - Emergency shutoff at 30°F (critical)
   - Normal shutoff at 33°F
   - Resume at 36°F

2. **Sensor Monitoring**
   - Watchdog checks every 5 minutes
   - Automatic shutoff if sensors offline >10 minutes
   - Range validation (reasonable temperature values)

3. **Runtime Protection**
   - Maximum runtime limit (default 4 hours)
   - Warning at 90% of limit
   - Forced shutdown at limit

4. **Manual Overrides**
   - Emergency stop button
   - System reset capability
   - Manual smart plug control always available

### Fail-Safe Modes

**Sensor Failure:**
- Turn off AC immediately
- Set emergency mode
- Require manual reset

**Communication Loss:**
- Rely on Home Assistant automations as backup
- Smart plugs maintain last state
- Manual intervention required

**Power Loss:**
- System restarts in safe mode
- AC starts off by default
- User must manually restart automation

## Integration Points

### Home Assistant Entities

**Required:**
- `sensor.room_temp` - Room temperature sensor
- `sensor.coil_temp` - Coil temperature sensor  
- `switch.ac_plug` - AC unit smart plug

**Optional:**
- `switch.heating_pad` - Heating pad smart plug
- `remote.ac_ir_blaster` - IR remote control

### MQTT Topics (if using MQTT sensors)

```
coolbot/sensors/room_temp
coolbot/sensors/coil_temp
coolbot/status/ac_state
coolbot/alerts/notifications
```

### REST APIs

Node-RED exposes endpoints for:
- Current system status
- Temperature readings
- Manual control override
- Configuration updates

## Customization Guide

### Adjusting Temperature Logic

To modify temperature thresholds:

1. **Via Dashboard** (temporary):
   - Use sliders in the dashboard
   - Changes lost on restart

2. **Via Flow Variables** (persistent):
   - Modify initialization function
   - Update default values in `init-settings`

3. **Via Configuration File**:
   - Edit `node-red/config/settings.json`
   - Import settings on startup

### Adding New Sensors

To add additional temperature sensors:

1. Create new input node in main flow
2. Add sensor to decision logic function
3. Update safety monitoring
4. Add to dashboard display

### Custom Alerts

To add new alert types:

1. Create detection logic in safety flow
2. Add to notification formatter
3. Configure Home Assistant notifications
4. Update dashboard alerts section

### IR Command Customization

To modify IR commands:

1. Learn commands using Broadlink/ESPHome
2. Update command codes in IR function
3. Test commands manually first
4. Add new command types as needed

## Performance Considerations

### Resource Usage
- Node-RED: ~50MB RAM typical
- CPU usage: <5% on Raspberry Pi 4
- Network: Minimal (local LAN only)

### Scalability
- System designed for single AC unit
- Can be replicated for multiple zones
- Shared dashboard possible with modifications

### Reliability
- No single point of failure (except sensors)
- Manual overrides always available
- Graceful degradation on component failure

## Troubleshooting Tools

### Built-in Diagnostics

1. **Debug Output**
   - All flows include debug nodes
   - Safety alerts logged
   - Decision logic traced

2. **Dashboard Status**
   - Real-time system state
   - Sensor health indicators
   - Runtime information

3. **Home Assistant Integration**
   - Entity state monitoring
   - Historical data
   - Automation traces

### Log Analysis

**Node-RED Logs:**
```bash
sudo journalctl -u node-red -f
```

**Home Assistant Logs:**
- Check sensor entity history
- Review automation triggers
- Monitor device connectivity

### Testing Procedures

1. **Sensor Testing**
   - Verify readings in HA
   - Check Node-RED debug output
   - Test sensor offline scenarios

2. **Control Testing**
   - Manual smart plug operation
   - Emergency stop functionality
   - System reset procedure

3. **Safety Testing**
   - Simulate sensor failures
   - Test freeze protection
   - Verify runtime limits

## Security Considerations

### Network Security
- Keep Node-RED on local network only
- Use HTTPS for remote access
- Secure Home Assistant instance

### Physical Security  
- Protect sensor wiring
- Secure smart plug connections
- Label emergency shutoffs

### Access Control
- Limit dashboard access
- Use strong passwords
- Monitor system logs

## Maintenance Schedule

### Daily (During Initial Setup)
- Check temperature readings
- Verify AC operation
- Monitor freeze protection triggers

### Weekly
- Review system logs
- Check sensor calibration
- Test emergency stops

### Monthly  
- Clean AC filters
- Inspect sensor mounting
- Update software if needed

### Seasonally
- Full system test
- Backup configurations
- Review and update thresholds