#define USE_ARDUINO_INTERRUPTS true    // Set up low-level interrupts for accurate BPM math.
#include <WiFi.h>                      // Includes the Wi-Fi library.
#include <PubSubClient.h>              // Includes the PubSubClient library for MQTT.
#include <Wire.h>
#include <MPU6050.h>                   // Ensure the MPU6050 library is compatible with ESP32.

// Wi-Fi Configuration
const char* ssid = "DT105_2.4GHz@unifi"; // Replace with your Wi-Fi SSID.
const char* password = "112233DT";       // Replace with your Wi-Fi password.

// MQTT Configuration
const char* mqtt_server = "192.168.0.7"; // Replace with your MQTT broker IP address.
const int mqtt_port = 1883;              // Default MQTT port.
const char* topic_fall = "accelerometer/fall";      // Topic for fall detection.
const char* topic_jerk = "accelerometer/jerk";      // Topic for jerk magnitude.

WiFiClient espClient;
PubSubClient client(espClient);

// MPU6050 Configuration
MPU6050 mpu;
#define SDA_PIN 21
#define SCL_PIN 22

// Variables for fall detection
int16_t ax, ay, az;
float prevAccX = 0.0, prevAccY = 0.0, prevAccZ = 0.0;
const int sampleInterval = 10;    // Interval in milliseconds between readings
const float fallThreshold = 700; // Adjust this value based on testing (in m/s^3)

// Define onboard LED pin
#define LED_PIN 2

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

  // Configure onboard LED pin
  pinMode(LED_PIN, OUTPUT);

  // Connect to Wi-Fi
  connectToWiFi();

  // Configure MQTT server
  client.setServer(mqtt_server, mqtt_port);
}

void loop() {
  // Ensure MQTT connection
  if (!client.connected()) {
    reconnectMQTT();
  }
  client.loop();

  // Read accelerometer data
  mpu.getAcceleration(&ax, &ay, &az);

  // Convert accelerometer readings to m/s^2 (1 g = 9.8 m/s^2)
  float accelerationX = ax / 16384.0 * 9.8; // Assuming default full-scale range ±2g
  float accelerationY = ay / 16384.0 * 9.8;
  float accelerationZ = az / 16384.0 * 9.8;

  // Calculate jerk (rate of change of acceleration)
  float jerkX = (accelerationX - prevAccX) / (sampleInterval / 1000.0);
  float jerkY = (accelerationY - prevAccY) / (sampleInterval / 1000.0);
  float jerkZ = (accelerationZ - prevAccZ) / (sampleInterval / 1000.0);

  // Update previous acceleration values
  prevAccX = accelerationX;
  prevAccY = accelerationY;
  prevAccZ = accelerationZ;

  // Calculate magnitude of jerk
  float jerkMagnitude = sqrt(jerkX * jerkX + jerkY * jerkY + jerkZ * jerkZ);

  // Publish jerk magnitude to MQTT
  char jerkPayload[50];
  snprintf(jerkPayload, 50, "{\"jerk\": %.2f}", jerkMagnitude);
  client.publish(topic_jerk, jerkPayload);
  Serial.println(jerkPayload);

  // Check for fall detection
  if (jerkMagnitude > fallThreshold) {
    Serial.println("Fall detected!");
    digitalWrite(LED_PIN, HIGH); // Turn on LED to indicate fall

    // Publish fall detection event to MQTT
    char fallPayload[50];
    snprintf(fallPayload, 50, "{\"event\": \"Fall detected\"}");
    client.publish(topic_fall, fallPayload);
    Serial.println(fallPayload);

    delay(1000);                 // Keep LED on for 1 second
    digitalWrite(LED_PIN, LOW);  // Turn off LED
  } else {
    Serial.println("No fall detected.");
    delay(500);
  }

  // Wait for the next sample
  delay(sampleInterval);
}

// Function to connect to Wi-Fi
void connectToWiFi() {
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
}

// Function to reconnect to MQTT broker
void reconnectMQTT() {
  while (!client.connected()) {
    Serial.print("Connecting to MQTT broker...");
    if (client.connect("ESP32_Accelerometer")) { // Set a unique client ID
      Serial.println("Connected to MQTT broker.");
    } else {
      Serial.print("Failed, rc=");
      Serial.print(client.state());
      Serial.println(" -> Retrying in 5 seconds.");
      delay(5000);
    }
  }
}
