# 58brr - CoolBot-Style AC Automation

A Node-RED based automation system that replicates CoolBot functionality to safely cool a room down to ~30°F using a standard window AC unit that normally cannot go below 60°F.

## Overview

This system uses smart plugs, external temperature sensors, and optional IR control to override the AC unit's built-in thermostat limitations while protecting the evaporator coil from freezing damage.

## Features

- **Smart Plug Control**: Turn AC unit ON/OFF via smart plug
- **Dual Temperature Monitoring**: 
  - Room temperature sensor for target control
  - Coil temperature sensor for freeze protection
- **Freeze Protection**: Automatically stops cooling when coil temperature drops below 33°F
- **Hysteresis Logic**: Prevents short cycling with configurable temperature ranges
- **Minimum Off Time**: Enforces 5-10 minute compressor rest periods
- **Optional Heating Pad**: Control heating pad to spoof AC internal thermostat
- **IR Control**: Optional IR commands to set AC to optimal settings
- **Web Dashboard**: Real-time monitoring and control interface
- **Safety Fail-safes**: Protection against sensor failures and equipment damage

## Target Temperature

Default: 30°F (configurable via dashboard)

## Safety Logic

- Coil temp < 33°F → Turn OFF AC (freeze protection)
- Coil temp > 36°F → Resume cooling if room needs it
- Minimum 5-10 minutes OFF time between cycles
- Sensor failure detection and safe mode operation

## Quick Start

1. Install Node-RED and required nodes
2. Import the provided flows
3. Configure Home Assistant entities
4. Deploy and monitor via dashboard

See `docs/` folder for detailed setup instructions. 
