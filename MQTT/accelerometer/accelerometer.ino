#include <WiFi.h>                      // Includes the Wi-Fi library.
#include <PubSubClient.h>              // Includes the PubSubClient library for MQTT.
#include <Wire.h>
#include <MPU6050.h>                   // Ensure the MPU6050 library is compatible with ESP32.
MPU6050 mpu;

// Wi-Fi Configuration
const char* ssid = "DT105_2.4GHz@unifi"; // Replace with your Wi-Fi SSID.
const char* password = "112233DT";       // Replace with your Wi-Fi password.

// MQTT Configuration
const char* mqtt_server = "192.168.0.7"; // Replace with your MQTT broker IP address.
const int mqtt_port = 1883;              // Default MQTT port.
const char* mqtt_topic_accMag = "accelerometer/accMag";
const char* mqtt_topic_angular = "accelerometer/ang";
const char* mqtt_topic_fall = "accelerometer/fall";      // Topic for fall detection.

WiFiClient espClient;
PubSubClient mqttClient(espClient);

// MPU6050 Configuration
#define SDA_PIN 21
#define SCL_PIN 22

bool fallDetected = false;

// Variables for accelerometer and gyroscope readings
int16_t ax, ay, az;
int16_t gx, gy, gz;

// Thresholds for fall detection (adjust based on real-world tests)
const float LFT_ACC = 1.4;  // Lower fall threshold for acceleration (g)
const float UFT_ACC = 1.8;  // Upper fall threshold for acceleration (g)
const float UFT_W = 170.0;  // Upper fall threshold for angular velocity (deg/s)
unsigned long prev_time = 0;

// Sampling interval (adjust for your setup)
const int SAMPLE_INTERVAL = 500; // milliseconds

// Variables to store calculated values
float accMagnitude, angularVelocity;

// Helper function to compute magnitude of a 3D vector
float computeMagnitude(int16_t x, int16_t y, int16_t z) {
  return sqrt(sq(x) + sq(y) + sq(z));
}

void setup() {
  // Start I2C interface
  Wire.begin(SDA_PIN, SCL_PIN);

  // Initialize Serial
  Serial.begin(115200);

  // Initialize MPU6050 and check connection
  Serial.println("Initializing MPU...");
  mpu.initialize();
  Serial.println("Testing MPU6050 connection...");
  if (!mpu.testConnection()) {
    Serial.println("MPU6050 connection failed!");
    while (true); // Stop execution
  } else {
    Serial.println("MPU6050 connection successful!");
  }

  // Connect to Wi-Fi
  Serial.print("Connecting to Wi-Fi...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.println("Wi-Fi connected.");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());

  // Configure MQTT server
  mqttClient.setServer(mqtt_server, mqtt_port);
}

void loop() {
  unsigned long curr_time = millis();
  
  // Ensure MQTT connection
  if (!mqttClient.connected()) {
    reconnectMQTT();
  }
  mqttClient.loop();

  // Read raw accelerometer and gyroscope data
  mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
  
  accMagnitude = computeMagnitude(ax, ay, az) / 16384.0;  // Calculate acceleration magnitude in g (assuming 1 unit = 16384 LSB for MPU6050)
  angularVelocity = computeMagnitude(gx, gy, gz) / 131.0;  // Calculate angular velocity magnitude in deg/s (assuming 1 unit = 131 LSB for MPU6050)
  
  // Check upper thresholds
    Serial.print("ACC: ");
    Serial.print(accMagnitude);
    Serial.print("          ");
    Serial.print("ang: ");
    Serial.print(angularVelocity);
    
    
    char payload_fall_data_acc [50];
    snprintf(payload_fall_data_acc, 50, "{\"accMagnitude\": %f}", accMagnitude); // Format data as JSON
    mqttClient.publish(mqtt_topic_accMag, payload_fall_data_acc);

    char payload_fall_data_angular [50];
    snprintf(payload_fall_data_angular, 50, "{\"angularVelocity\": %f}", angularVelocity); // Format data as JSON
    mqttClient.publish(mqtt_topic_angular, payload_fall_data_angular);
  
  // Apply fall detection algorithm
  
  if (accMagnitude > LFT_ACC) { // Check lower fall threshold
    Serial.println("Potential fall detected! Verifying...");

    if (curr_time - prev_time >= 500){
      prev_time = curr_time;
    }
    mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
    accMagnitude = computeMagnitude(ax, ay, az) / 16384.0;
    angularVelocity = computeMagnitude(gx, gy, gz) / 131.0;

    if (accMagnitude > UFT_ACC && angularVelocity > UFT_W) {
      Serial.println("Fall detected!");
      // Additional logic for alerts (e.g., buzzer, SMS, LED)
       // Publish fall detection event to MQTT
      char fallPayload[50];
      snprintf(fallPayload, 50, "{\"event\": \"Fall detected\"}");
      mqttClient.publish(mqtt_topic_fall, fallPayload);
      Serial.println(fallPayload);
    }else {
      Serial.println("No fall confirmed.");
    }
   
    } else {
    Serial.println("No fall detected.");
  }
  
  // Wait for the next sample
  delay(SAMPLE_INTERVAL);
}


// Function to reconnect to MQTT broker
void reconnectMQTT() {
  while (!mqttClient.connected()) {
    Serial.print("Connecting to MQTT broker...");
    if (mqttClient.connect("ESP32_Accelerometer")) { // Set a unique client ID
      Serial.println("Connected to MQTT broker.");
    } else {
      Serial.print("Failed, rc=");
      Serial.print(mqttClient.state());
      Serial.println(" -> Retrying in 5 seconds.");
      delay(5000);
    }
  }
}
