/*
 * CoolBot ESP32 Hub
 * Controls AC relay, heating diode, and temperature sensors via MQTT
 * 
 * Hardware:
 * - ESP32 Dev Board
 * - 2x DS18B20 temperature sensors (room and coil)
 * - Relay module for AC control
 * - High-power resistor/heating element (heating diode)
 * - Optional: IR transmitter/receiver
 */

#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <esp_wifi.h>

// WiFi and MQTT Configuration
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
const char* mqtt_server = "YOUR_MQTT_BROKER_IP";
const int mqtt_port = 1883;
const char* mqtt_user = "";
const char* mqtt_password = "";
const char* client_id = "coolbot_esp32";

// Pin Definitions
#define ROOM_TEMP_PIN     4    // DS18B20 room temperature sensor
#define COIL_TEMP_PIN     5    // DS18B20 coil temperature sensor
#define AC_RELAY_PIN      12   // Relay to control AC smart plug
#define HEATING_DIODE_PIN 25   // PWM pin for heating diode
#define STATUS_LED_PIN    2    // Built-in LED for status
#define IR_SEND_PIN       14   // IR transmitter (optional)
#define IR_RECV_PIN       15   // IR receiver (optional)

// PWM Configuration for Heating Diode
#define PWM_CHANNEL       0
#define PWM_FREQUENCY     1000
#define PWM_RESOLUTION    8    // 8-bit (0-255)

// Temperature sensor setup
OneWire roomTempWire(ROOM_TEMP_PIN);
OneWire coilTempWire(COIL_TEMP_PIN);
DallasTemperature roomTempSensor(&roomTempWire);
DallasTemperature coilTempSensor(&coilTempWire);

// Global variables
WiFiClient espClient;
PubSubClient client(espClient);

// System state
bool acRelayState = false;
bool heatingDiodeEnabled = false;
int heatingDiodeIntensity = 0;
float roomTemperature = -999;
float coilTemperature = -999;
unsigned long lastTempReading = 0;
unsigned long lastStatusUpdate = 0;
unsigned long lastHeartbeat = 0;

// Timing intervals (milliseconds)
const unsigned long TEMP_INTERVAL = 30000;     // 30 seconds
const unsigned long STATUS_INTERVAL = 60000;   // 1 minute
const unsigned long HEARTBEAT_INTERVAL = 30000; // 30 seconds

// MQTT Topics
const char* TOPIC_ROOM_TEMP = "coolbot/sensors/room_temp";
const char* TOPIC_COIL_TEMP = "coolbot/sensors/coil_temp";
const char* TOPIC_ESP32_STATUS = "coolbot/esp32/status";
const char* TOPIC_ESP32_HEARTBEAT = "coolbot/esp32/heartbeat";
const char* TOPIC_AC_CONTROL = "coolbot/controls/ac_plug";
const char* TOPIC_HEATING_CONTROL = "coolbot/controls/heating_diode";
const char* TOPIC_SETTINGS = "coolbot/settings/+";

void setup() {
  Serial.begin(115200);
  Serial.println("CoolBot ESP32 Hub Starting...");
  
  // Initialize pins
  pinMode(AC_RELAY_PIN, OUTPUT);
  pinMode(STATUS_LED_PIN, OUTPUT);
  digitalWrite(AC_RELAY_PIN, LOW);  // AC off by default
  digitalWrite(STATUS_LED_PIN, LOW);
  
  // Initialize PWM for heating diode
  ledcSetup(PWM_CHANNEL, PWM_FREQUENCY, PWM_RESOLUTION);
  ledcAttachPin(HEATING_DIODE_PIN, PWM_CHANNEL);
  ledcWrite(PWM_CHANNEL, 0); // Start with heating diode off
  
  // Initialize temperature sensors
  roomTempSensor.begin();
  coilTempSensor.begin();
  
  Serial.println("Temperature sensors initialized");
  Serial.printf("Room sensor count: %d\n", roomTempSensor.getDeviceCount());
  Serial.printf("Coil sensor count: %d\n", coilTempSensor.getDeviceCount());
  
  // Connect to WiFi
  setupWiFi();
  
  // Setup MQTT
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(mqttCallback);
  
  Serial.println("Setup complete!");
}

void loop() {
  // Maintain MQTT connection
  if (!client.connected()) {
    reconnectMQTT();
  }
  client.loop();
  
  unsigned long now = millis();
  
  // Read temperatures periodically
  if (now - lastTempReading > TEMP_INTERVAL) {
    readTemperatures();
    publishTemperatures();
    lastTempReading = now;
  }
  
  // Send status update
  if (now - lastStatusUpdate > STATUS_INTERVAL) {
    publishStatus();
    lastStatusUpdate = now;
  }
  
  // Send heartbeat
  if (now - lastHeartbeat > HEARTBEAT_INTERVAL) {
    publishHeartbeat();
    lastHeartbeat = now;
  }
  
  // Status LED blink pattern
  blinkStatusLED();
  
  delay(100);
}

void setupWiFi() {
  delay(10);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println("");
  Serial.println("WiFi connected");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}

void reconnectMQTT() {
  while (!client.connected()) {
    Serial.print("Attempting MQTT connection...");
    
    if (client.connect(client_id, mqtt_user, mqtt_password,
                      "coolbot/esp32/status", 1, true, "offline")) {
      Serial.println("connected");
      
      // Subscribe to control topics
      client.subscribe(TOPIC_AC_CONTROL);
      client.subscribe(TOPIC_HEATING_CONTROL);
      client.subscribe(TOPIC_SETTINGS);
      
      // Publish online status
      publishOnlineStatus();
      
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" try again in 5 seconds");
      delay(5000);
    }
  }
}

void mqttCallback(char* topic, byte* payload, unsigned int length) {
  // Convert payload to string
  char message[length + 1];
  memcpy(message, payload, length);
  message[length] = '\0';
  
  Serial.printf("Message arrived [%s]: %s\n", topic, message);
  
  // Parse JSON payload
  DynamicJsonDocument doc(1024);
  DeserializationError error = deserializeJson(doc, message);
  
  if (error) {
    Serial.print("JSON parsing failed: ");
    Serial.println(error.c_str());
    return;
  }
  
  // Handle AC control
  if (strcmp(topic, TOPIC_AC_CONTROL) == 0) {
    handleACControl(doc);
  }
  // Handle heating diode control
  else if (strcmp(topic, TOPIC_HEATING_CONTROL) == 0) {
    handleHeatingControl(doc);
  }
  // Handle settings updates
  else if (strncmp(topic, "coolbot/settings/", 17) == 0) {
    handleSettingsUpdate(doc);
  }
}

void handleACControl(DynamicJsonDocument& doc) {
  if (doc.containsKey("command")) {
    String command = doc["command"];
    String reason = doc["reason"] | "unknown";
    String source = doc["source"] | "unknown";
    
    Serial.printf("AC Control: %s (reason: %s, source: %s)\n", 
                  command.c_str(), reason.c_str(), source.c_str());
    
    if (command == "on") {
      digitalWrite(AC_RELAY_PIN, HIGH);
      acRelayState = true;
      Serial.println("AC turned ON");
    } else if (command == "off") {
      digitalWrite(AC_RELAY_PIN, LOW);
      acRelayState = false;
      Serial.println("AC turned OFF");
    }
  }
}

void handleHeatingControl(DynamicJsonDocument& doc) {
  if (doc.containsKey("enabled")) {
    heatingDiodeEnabled = doc["enabled"];
  }
  
  if (doc.containsKey("intensity")) {
    heatingDiodeIntensity = doc["intensity"];
    // Clamp to valid PWM range
    heatingDiodeIntensity = constrain(heatingDiodeIntensity, 0, 255);
  }
  
  String mode = doc["mode"] | "auto";
  
  Serial.printf("Heating Diode: enabled=%s, intensity=%d, mode=%s\n",
                heatingDiodeEnabled ? "true" : "false",
                heatingDiodeIntensity,
                mode.c_str());
  
  // Update PWM output
  if (heatingDiodeEnabled) {
    ledcWrite(PWM_CHANNEL, heatingDiodeIntensity);
  } else {
    ledcWrite(PWM_CHANNEL, 0);
  }
}

void handleSettingsUpdate(DynamicJsonDocument& doc) {
  Serial.println("Settings update received");
  // Handle any ESP32-specific settings here
  // Most settings are handled by Node-RED
}

void readTemperatures() {
  // Request temperature readings
  roomTempSensor.requestTemperatures();
  coilTempSensor.requestTemperatures();
  
  // Read temperatures in Fahrenheit
  float roomTempC = roomTempSensor.getTempCByIndex(0);
  float coilTempC = coilTempSensor.getTempCByIndex(0);
  
  if (roomTempC != DEVICE_DISCONNECTED_C) {
    roomTemperature = roomTempC * 9.0 / 5.0 + 32.0; // Convert to Fahrenheit
  } else {
    roomTemperature = -999; // Error value
    Serial.println("Error reading room temperature sensor");
  }
  
  if (coilTempC != DEVICE_DISCONNECTED_C) {
    coilTemperature = coilTempC * 9.0 / 5.0 + 32.0; // Convert to Fahrenheit
  } else {
    coilTemperature = -999; // Error value
    Serial.println("Error reading coil temperature sensor");
  }
  
  Serial.printf("Temperatures - Room: %.1f°F, Coil: %.1f°F\n", 
                roomTemperature, coilTemperature);
}

void publishTemperatures() {
  DynamicJsonDocument doc(200);
  
  // Publish room temperature
  doc.clear();
  doc["temperature"] = roomTemperature;
  doc["timestamp"] = millis();
  doc["sensor_id"] = "room_ds18b20";
  
  char buffer[256];
  serializeJson(doc, buffer);
  client.publish(TOPIC_ROOM_TEMP, buffer, true);
  
  // Publish coil temperature
  doc.clear();
  doc["temperature"] = coilTemperature;
  doc["timestamp"] = millis();
  doc["sensor_id"] = "coil_ds18b20";
  
  serializeJson(doc, buffer);
  client.publish(TOPIC_COIL_TEMP, buffer, true);
}

void publishStatus() {
  DynamicJsonDocument doc(512);
  
  doc["online"] = true;
  doc["uptime"] = millis() / 1000;
  doc["wifi_rssi"] = WiFi.RSSI();
  doc["free_heap"] = ESP.getFreeHeap();
  doc["ac_relay_state"] = acRelayState;
  doc["heating_diode_enabled"] = heatingDiodeEnabled;
  doc["heating_diode_intensity"] = heatingDiodeIntensity;
  doc["heating_diode_temp"] = getHeatingDiodeTemp();
  
  JsonArray sensors = doc.createNestedArray("sensors_online");
  if (roomTemperature > -999) sensors.add("room_ds18b20");
  if (coilTemperature > -999) sensors.add("coil_ds18b20");
  
  char buffer[512];
  serializeJson(doc, buffer);
  client.publish(TOPIC_ESP32_STATUS, buffer, true);
}

void publishHeartbeat() {
  DynamicJsonDocument doc(100);
  doc["timestamp"] = millis();
  doc["uptime"] = millis() / 1000;
  
  char buffer[128];
  serializeJson(doc, buffer);
  client.publish(TOPIC_ESP32_HEARTBEAT, buffer);
}

void publishOnlineStatus() {
  DynamicJsonDocument doc(100);
  doc["online"] = true;
  doc["startup_time"] = millis();
  
  char buffer[128];
  serializeJson(doc, buffer);
  client.publish(TOPIC_ESP32_STATUS, buffer, true);
}

float getHeatingDiodeTemp() {
  // If you have a temperature sensor on the heating diode, read it here
  // For now, estimate based on PWM duty cycle and ambient temperature
  float ambientTemp = (roomTemperature > -999) ? roomTemperature : 70.0;
  float tempRise = (heatingDiodeIntensity / 255.0) * 50.0; // Estimate 50°F max rise
  return ambientTemp + tempRise;
}

void blinkStatusLED() {
  static unsigned long lastBlink = 0;
  static bool ledState = false;
  unsigned long interval = 1000; // Default 1 second
  
  // Different blink patterns for different states
  if (WiFi.status() != WL_CONNECTED) {
    interval = 200; // Fast blink for no WiFi
  } else if (!client.connected()) {
    interval = 500; // Medium blink for no MQTT
  } else if (acRelayState) {
    interval = 100; // Very fast when AC is on
  }
  
  if (millis() - lastBlink > interval) {
    ledState = !ledState;
    digitalWrite(STATUS_LED_PIN, ledState);
    lastBlink = millis();
  }
}