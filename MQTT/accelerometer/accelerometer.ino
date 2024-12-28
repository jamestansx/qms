#include <Wire.h>
#include <WiFi.h>

const int MPU_addr = 0x68; // I2C address of the MPU-6050
int16_t AcX, AcY, AcZ, Tmp, GyX, GyY, GyZ;
float ax = 0, ay = 0, az = 0, gx = 0, gy = 0, gz = 0;
boolean fall = false; // Stores if a fall has occurred
boolean trigger1 = false; // Stores if first trigger (lower threshold) has occurred
boolean trigger2 = false; // Stores if second trigger (upper threshold) has occurred
boolean trigger3 = false; // Stores if third trigger (orientation change) has occurred
byte trigger1count = 0; // Stores the counts past since trigger 1 was set true
byte trigger2count = 0; // Stores the counts past since trigger 2 was set true
byte trigger3count = 0; // Stores the counts past since trigger 3 was set true
int angleChange = 0;

void setup() {
  Serial.begin(115200);
  Wire.begin();
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x6B);  // PWR_MGMT_1 register
  Wire.write(0);     // Set to zero (wakes up the MPU-6050)
  Wire.endTransmission(true);
}

void loop() {
  mpu_read();
  ax = (AcX - 2050) / 16384.00;
  ay = (AcY - 77) / 16384.00;
  az = (AcZ - 1947) / 16384.00;
  gx = (GyX + 270) / 131.07;
  gy = (GyY - 351) / 131.07;
  gz = (GyZ + 136) / 131.07;
  // Calculating Amplitude Vector for 3-axis
  float raw_amplitude = pow(pow(ax, 2) + pow(ay, 2) + pow(az, 2), 0.5);
  int amplitude = raw_amplitude * 10;  // Multiplied by 10 because values are between 0 to 1
  Serial.println(amplitude);

  if (amplitude <= 2 && trigger2 == false) { // If AM breaks lower threshold (0.4g)
    trigger1 = true;
    Serial.println("TRIGGER 1 ACTIVATED");
  }
  if (trigger1 == true) {
    trigger1count++;
    if (amplitude >= 12) { // If AM breaks upper threshold (3g)
      trigger2 = true;
      Serial.println("TRIGGER 2 ACTIVATED");
      trigger1 = false; trigger1count = 0;
    }
  }
  if (trigger2 == true) {
    trigger2count++;
    angleChange = pow(pow(gx, 2) + pow(gy, 2) + pow(gz, 2), 0.5);
    Serial.println(angleChange);
    if (angleChange >= 30 && angleChange <= 400) { // If orientation changes by between 80-100 degrees
      trigger3 = true; trigger2 = false; trigger2count = 0;
      Serial.println(angleChange);
      Serial.println("TRIGGER 3 ACTIVATED");
    }
  }
  if (trigger3 == true) {
    trigger3count++;
    if (trigger3count >= 10) {
      angleChange = pow(pow(gx, 2) + pow(gy, 2) + pow(gz, 2), 0.5);
      Serial.println(angleChange);
      if ((angleChange >= 0) && (angleChange <= 10)) { // If orientation changes remain between 0-10 degrees
        fall = true; trigger3 = false; trigger3count = 0;
        Serial.println(angleChange);
      } else { // User regained normal orientation
        trigger3 = false; trigger3count = 0;
        Serial.println("TRIGGER 3 DEACTIVATED");
      }
    }
  }
  if (fall == true) { // In the event of a fall detection
    Serial.println("FALL DETECTED");
    fall = false;
  }
  if (trigger2count >= 6) { // Allow 0.5s for orientation change
    trigger2 = false; trigger2count = 0;
    Serial.println("TRIGGER 2 DEACTIVATED");
  }
  if (trigger1count >= 6) { // Allow 0.5s for AM to break upper threshold
    trigger1 = false; trigger1count = 0;
    Serial.println("TRIGGER 1 DEACTIVATED");
  }
  delay(100);
}

void mpu_read() {
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x3B);  // Starting with register 0x3B (ACCEL_XOUT_H)
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_addr, 14, true);  // Request a total of 14 registers
  AcX = Wire.read() << 8 | Wire.read();  // 0x3B (ACCEL_XOUT_H) & 0x3C (ACCEL_XOUT_L)    
  AcY = Wire.read() << 8 | Wire.read();  // 0x3D (ACCEL_YOUT_H) & 0x3E (ACCEL_YOUT_L)
  AcZ = Wire.read() << 8 | Wire.read();  // 0x3F (ACCEL_ZOUT_H) & 0x40 (ACCEL_ZOUT_L)
  Tmp = Wire.read() << 8 | Wire.read();  // 0x41 (TEMP_OUT_H) & 0x42 (TEMP_OUT_L)
  GyX = Wire.read() << 8 | Wire.read();  // 0x43 (GYRO_XOUT_H) & 0x44 (GYRO_XOUT_L)
  GyY = Wire.read() << 8 | Wire.read();  // 0x45 (GYRO_YOUT_H) & 0x46 (GYRO_YOUT_L)
  GyZ = Wire.read() << 8 | Wire.read();  // 0x47 (GYRO_ZOUT_H) & 0x48 (GYRO_ZOUT_L)
}


//#include <WiFi.h>                      // Includes the Wi-Fi library.
//#include <PubSubClient.h>              // Includes the PubSubClient library for MQTT.
//#include <Wire.h>
//#include <MPU6050.h>                   // Ensure the MPU6050 library is compatible with ESP32.
//MPU6050 mpu;
//
//// Wi-Fi Configuration
//const char* ssid = "DT105_2.4GHz@unifi"; // Replace with your Wi-Fi SSID.
//const char* password = "112233DT";       // Replace with your Wi-Fi password.
//
//// MQTT Configuration
//const char* mqtt_server = "192.168.0.7"; // Replace with your MQTT broker IP address.
//const int mqtt_port = 1883;              // Default MQTT port.
//const char* mqtt_topic_accMag = "accelerometer/accMag";
//const char* mqtt_topic_angular = "accelerometer/ang";
//const char* mqtt_topic_fall = "accelerometer/fall";      // Topic for fall detection.
//
//WiFiClient espClient;
//PubSubClient mqttClient(espClient);
//
//// MPU6050 Configuration
//#define SDA_PIN 21
//#define SCL_PIN 22
//
//bool fallDetected = false;
//
//// Variables for accelerometer and gyroscope readings
//int16_t ax, ay, az;
//int16_t gx, gy, gz;
//
//// Thresholds for fall detection (adjust based on real-world tests)
//const float LFT_ACC = 1.4;  // Lower fall threshold for acceleration (g)
//const float UFT_ACC = 1.8;  // Upper fall threshold for acceleration (g)
//const float UFT_W = 170.0;  // Upper fall threshold for angular velocity (deg/s)
//unsigned long prev_time = 0;
//
//// Sampling interval (adjust for your setup)
//const int SAMPLE_INTERVAL = 500; // milliseconds
//
//// Variables to store calculated values
//float accMagnitude, angularVelocity;
//
//// Helper function to compute magnitude of a 3D vector
//float computeMagnitude(int16_t x, int16_t y, int16_t z) {
//  return sqrt(sq(x) + sq(y) + sq(z));
//}
//
//void setup() {
//  // Start I2C interface
//  Wire.begin(SDA_PIN, SCL_PIN);
//
//  // Initialize Serial
//  Serial.begin(115200);
//
//  // Initialize MPU6050 and check connection
//  Serial.println("Initializing MPU...");
//  mpu.initialize();
//  Serial.println("Testing MPU6050 connection...");
//  if (!mpu.testConnection()) {
//    Serial.println("MPU6050 connection failed!");
//    while (true); // Stop execution
//  } else {
//    Serial.println("MPU6050 connection successful!");
//  }
//
//  // Connect to Wi-Fi
//  Serial.print("Connecting to Wi-Fi...");
//  WiFi.begin(ssid, password);
//  while (WiFi.status() != WL_CONNECTED) {
//    delay(500);
//    Serial.print(".");
//  }
//  Serial.println();
//  Serial.println("Wi-Fi connected.");
//  Serial.print("IP address: ");
//  Serial.println(WiFi.localIP());
//
//  // Configure MQTT server
//  mqttClient.setServer(mqtt_server, mqtt_port);
//}
//
//void loop() {
//  unsigned long curr_time = millis();
//  
//  // Ensure MQTT connection
//  if (!mqttClient.connected()) {
//    reconnectMQTT();
//  }
//  mqttClient.loop();
//
//  // Read raw accelerometer and gyroscope data
//  mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
//  
//  accMagnitude = computeMagnitude(ax, ay, az) / 16384.0;  // Calculate acceleration magnitude in g (assuming 1 unit = 16384 LSB for MPU6050)
//  angularVelocity = computeMagnitude(gx, gy, gz) / 131.0;  // Calculate angular velocity magnitude in deg/s (assuming 1 unit = 131 LSB for MPU6050)
//  
//  // Check upper thresholds
//    Serial.print("ACC: ");
//    Serial.print(accMagnitude);
//    Serial.print("          ");
//    Serial.print("ang: ");
//    Serial.print(angularVelocity);
//    
//    
//    char payload_fall_data_acc [50];
//    snprintf(payload_fall_data_acc, 50, "{\"accMagnitude\": %f}", accMagnitude); // Format data as JSON
//    mqttClient.publish(mqtt_topic_accMag, payload_fall_data_acc);
//
//    char payload_fall_data_angular [50];
//    snprintf(payload_fall_data_angular, 50, "{\"angularVelocity\": %f}", angularVelocity); // Format data as JSON
//    mqttClient.publish(mqtt_topic_angular, payload_fall_data_angular);
//  
//  // Apply fall detection algorithm
//  
//  if (accMagnitude > LFT_ACC) { // Check lower fall threshold
//    Serial.println("Potential fall detected! Verifying...");
//
//    if (curr_time - prev_time >= 500){
//      prev_time = curr_time;
//    }
//    mpu.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
//    accMagnitude = computeMagnitude(ax, ay, az) / 16384.0;
//    angularVelocity = computeMagnitude(gx, gy, gz) / 131.0;
//
//    if (accMagnitude > UFT_ACC && angularVelocity > UFT_W) {
//      Serial.println("Fall detected!");
//      // Additional logic for alerts (e.g., buzzer, SMS, LED)
//       // Publish fall detection event to MQTT
//      char fallPayload[50];
//      snprintf(fallPayload, 50, "{\"event\": \"Fall detected\"}");
//      mqttClient.publish(mqtt_topic_fall, fallPayload);
//      Serial.println(fallPayload);
//    }else {
//      Serial.println("No fall confirmed.");
//    }
//   
//    } else {
//    Serial.println("No fall detected.");
//  }
//  
//  // Wait for the next sample
//  delay(SAMPLE_INTERVAL);
//}
//
//
//// Function to reconnect to MQTT broker
//void reconnectMQTT() {
//  while (!mqttClient.connected()) {
//    Serial.print("Connecting to MQTT broker...");
//    if (mqttClient.connect("ESP32_Accelerometer")) { // Set a unique client ID
//      Serial.println("Connected to MQTT broker.");
//    } else {
//      Serial.print("Failed, rc=");
//      Serial.print(mqttClient.state());
//      Serial.println(" -> Retrying in 5 seconds.");
//      delay(5000);
//    }
//  }
//}
