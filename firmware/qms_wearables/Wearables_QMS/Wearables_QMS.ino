#include <BLEDevice.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <PulseSensorPlayground.h>
#include <Wire.h>
#include <MPU6050.h>
#include <math.h>

// Set up low-level interrupts for accurate BPM math.
#define USE_ARDUINO_INTERRUPTS true

#define SIZEOF(a) (sizeof(a) / sizeof(*a))

// NOTE: update the device uuid if changed
#define DEVICE_UUID "8e1ec0d3-3792-479a-be5d-4deadcb06f3f"
#define SAMPLE_INTERVAL_MS 100
#define SAMPLE_INTERVAL_HEART_MS 100
#define MQTT_PORT 1883

// NOTE: define the corresponding wifi
#define WEILE
#ifdef JAMESTANSX
#define SSID "jamestansx"
#define PASSWORD "james123456"
#define MQTT_SERVER "192.168.125.181"
#elif defined(WEIHAN)
#define SSID "Michael NG"
#define PASSWORD "weihan123456"
#define MQTT_SERVER "172.20.10.3"
#elif defined(UTEM)
#define SSID "UTeM-Net"
#define PASSWORD "1UTeM@PPPK"
#define MQTT_SERVER "10.131.133.70"
#elif defined(WEILE)
#define SSID "ijbol "
#define PASSWORD "09060511"
#define MQTT_SERVER "192.168.247.181"
#else
#define SSID "DT105_2.4GHz@unifi"
#define PASSWORD "112233DT"
#define MQTT_SERVER "192.168.0.2"
#endif

const char* mqtt_topic_location= "location/RSSI";
const char* mqtt_topic_heart= "heartRate/BPM";                // Topic to publish heart rate data.
const char* mqtt_topic_heartAlert = "heartRate/heartAlert";
const char* mqtt_topic_amplitude = "accelerometer/amplitude";
const char* mqtt_topic_angular = "accelerometer/ang";
const char* mqtt_topic_fallAlert = "accelerometer/fall";      // Topic for fall detection.
const char* mqtt_sub_queue = "queue/status";                  //Topic for queue status update
const char* mqtt_sub_ack = "accelerometer/ack";

WiFiClient espClient;
PubSubClient mqttClient(espClient);

// BLE
struct BleBeacon {
  BLEUUID uuid;
  int rssi;
};

const BLEUUID known_beacons[] = {
  BLEUUID("4fafc201-1fb5-459e-8fcc-c5c9c331914b"),
  BLEUUID("4fafc201-1fb5-459e-8fcc-c5c9c331914c")
};
BLEScan* pBLEScan;
BleBeacon bleBeacons[SIZEOF(known_beacons)] = {};

// Heart rate
const int PulseWire = 34;       // PulseSensor PURPLE WIRE connected to GPIO36 (ADC1_CH0).
const int LED = 2;      // Onboard LED on ESP32 (usually GPIO2).
int Threshold = 685;            // Threshold value to detect beats.
bool recordingStarted = false;       // Flag to track when measurement starts
PulseSensorPlayground pulseSensor;  // Creates an instance of the PulseSensorPlayground object.


// MPU6050 Configuration
enum FallState { safe, initial, suspect, triggered };
FallState fstate = FallState::safe;


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

// non-blocking delay
unsigned long prev_time_acce, prev_time_heart;

// Vibration DC motor
#define vibrationdc 23
static bool motorActive = false;
static unsigned long motorStartTime = 0;
const unsigned long motorVibrationDuration = 5000;

// Buzzer
#define BUZZER_PIN 25

void connectToMQTT() {
  while (!mqttClient.connected()) {
    if (mqttClient.connect("ESP32_Client")) {
      mqttClient.subscribe(mqtt_sub_queue);
      mqttClient.subscribe(mqtt_sub_ack);

    } else {
      Serial.print(F("Failed to connect to MQTT with status code: "));
      Serial.println(mqttClient.state());

      delay(5000);
    }
  }
}

String printAndSendRSSI() {
  String uuid = "";
  int rssi = 0;
  for (int i = 0; i < SIZEOF(bleBeacons); i++) {
    if (uuid.isEmpty() && bleBeacons[i].rssi < 0) {
      rssi = bleBeacons[i].rssi;
      uuid = bleBeacons[i].uuid.toString();
      continue;
    }

    if (bleBeacons[i].rssi < 0 && bleBeacons[i].rssi > rssi) {
      rssi = bleBeacons[i].rssi;
      uuid = bleBeacons[i].uuid.toString();
    }
  }

  mqttClient.publish(mqtt_topic_location, uuid.c_str());

  return uuid;
}


class MyAdvertisedDeviceCallbacks : public BLEAdvertisedDeviceCallbacks {
  void onResult(BLEAdvertisedDevice advertisedDevice) {
    BLEUUID service = advertisedDevice.getServiceUUID();

    for (int i = 0; i < SIZEOF(known_beacons); i++) {
      if (service.equals(known_beacons[i])) {
        bleBeacons[i].uuid = service.toString();
        bleBeacons[i].rssi = advertisedDevice.getRSSI();
      }
    }
  }
};

void connectWifi(){
  WiFi.begin(SSID, PASSWORD);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
  }
  Serial.print("Connected to Wi-Fi. IP address: ");
  Serial.println(WiFi.localIP());

}

void onMqttMessage(char* topic, byte* payload, unsigned int length) {
  String messageTemp;
  for (int i = 0; i < length; i++){
    messageTemp += (char)payload[i];
  }
//  Serial.println(topic);
//  Serial.print("size topic: ");
//  Serial.println(SIZEOF(topic));
//  Serial.println(mqtt_sub_ack);
//  Serial.print("size ack: ");
//  Serial.println(SIZEOF(mqtt_sub_ack));
  if (strncmp(topic, mqtt_sub_ack, SIZEOF(mqtt_sub_ack)) == 0) {
    digitalWrite(BUZZER_PIN, LOW);
    return;
  }

  Serial.println("Receive mqtt");
  if (strncmp(DEVICE_UUID, messageTemp.c_str(), length) == 0) {
    Serial.println("TRUE");
    digitalWrite(vibrationdc, HIGH);
    motorActive = true;
    motorStartTime = millis();
  } else {
    Serial.println("FALSE");
    digitalWrite(vibrationdc, LOW);
  }

}

void heartrate() {
  if (pulseSensor.sawStartOfBeat()) {
    int myBPM = pulseSensor.getBeatsPerMinute();
    Serial.print(" | Heart Rate: ");
    Serial.println(myBPM);
    String payload_heart = String("{\"uuid\": \"");
    payload_heart.concat(DEVICE_UUID);
    payload_heart.concat("\", \"data\": { \"BPM\": \"");
    payload_heart.concat(String(myBPM));
    payload_heart.concat("\"}}");
    mqttClient.publish(mqtt_topic_heart, payload_heart.c_str());
  }
}

/*
 * TODO: Falling detection algorithm description goes here.
 */
void falldown() {
  mpu_read();
  ax = (AcX - 2050) / 16384.00;
  ay = (AcY - 77) / 16384.00;
  az = (AcZ - 1947) / 16384.00;
  gx = (GyX + 270) / 131.07;
  gy = (GyY - 351) / 131.07;
  gz = (GyZ + 136) / 131.07;
  // Calculating Amplitude Vector for 3-axis
  float raw_amplitude = pow(pow(ax, 2) + pow(ay, 2) + pow(az, 2), 0.5);
  float amplitude = raw_amplitude * 10;  // Multiplied by 10 because values are between 0 to 1 m/s^2 normal = 1g

  Serial.print(" | Amplitude: ");
  Serial.println(amplitude);

  // Publish acceleration magnitude to MQTT
  char payload_amplitude[50];
  snprintf(payload_amplitude, 50, "{\"Amplitude\": %.2f}", amplitude);
  mqttClient.publish(mqtt_topic_amplitude, payload_amplitude);

  if (amplitude <= 2 && trigger2 == false) { // If AM breaks lower threshold (0.4g)
    trigger1 = true;
  }
  if (trigger1 == true) {     // Detects initial potential fall
    trigger1count++;
    if (amplitude >= 12) { // If AM breaks upper threshold (3g)
      trigger2 = true;
      trigger1 = false;
      trigger1count = 0;
    }
  }
  if (trigger2 == true) {   // Detects high amplitude (impact)
    trigger2count++;
    angleChange = pow(pow(gx, 2) + pow(gy, 2) + pow(gz, 2), 0.5);
    if (angleChange >= 30 && angleChange <= 400) { // If orientation changes by between 80-100 degrees
      trigger3 = true;
      trigger2 = false;
      trigger2count = 0;
    }
  }
  if (trigger3 == true) {   // Monitors orientation changes (e.g. lying on the ground)
    trigger3count++;

    if (trigger3count >= 10) {
      angleChange = pow(pow(gx, 2) + pow(gy, 2) + pow(gz, 2), 0.5);
      if ((angleChange >= 0) && (angleChange <= 10)) { // If orientation changes remain between 0-10 degrees
        fall = true; trigger3 = false; trigger3count = 0;
      } else { // User regained normal orientation
        trigger3 = false;
        trigger3count = 0;
      }
    }
  }

  if (fall == true) { // In the event of a fall detection
    digitalWrite(BUZZER_PIN, HIGH);
    memset(bleBeacons, 0, sizeof(bleBeacons));
    pBLEScan->start(3, false);

    String location = printAndSendRSSI();
    String fallAlert = String("{\"uuid\": \"");
    fallAlert.concat(DEVICE_UUID);
    fallAlert.concat("\", \"data\": { \"location\": \"");
    fallAlert.concat(location);
    fallAlert.concat("\"}}");
    mqttClient.publish(mqtt_topic_fallAlert, fallAlert.c_str());

    fall = false;
  }

  if (trigger2count >= 6) { // Allow 0.5s for orientation change
    trigger2 = false;
    trigger2count = 0;
  }
  if (trigger1count >= 6) { // Allow 0.5s for AM to break upper threshold
    trigger1 = false;
    trigger1count = 0;
  }
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

void setup() {
  Serial.begin(115200);

  //configure for ble
  BLEDevice::init("");

  pBLEScan = BLEDevice::getScan();
  pBLEScan->setAdvertisedDeviceCallbacks(new MyAdvertisedDeviceCallbacks());
  pBLEScan->setInterval(1349);
  pBLEScan->setWindow(449);
  pBLEScan->setActiveScan(true);
  pBLEScan->start(5, false);

  // Configure for heartrate
  // NOTE: ESP32 ADC resolution defaults to 12 bits.
  // PulseSensor rquires 10 bits
  analogReadResolution(10);
  pulseSensor.analogInput(PulseWire);
  pulseSensor.blinkOnPulse(LED);  // Blink the onboard LED with a heartbeat.
  pulseSensor.setSerial(Serial);
  pulseSensor.setThreshold(Threshold);
  while (!pulseSensor.begin());

  //configure for falldown
  Wire.begin();
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x6B);  // PWR_MGMT_1 register
  Wire.write(0);     // Set to zero (wakes up the MPU-6050)
  Wire.endTransmission(true);

  connectWifi();

  mqttClient.setServer(MQTT_SERVER, MQTT_PORT);
  mqttClient.setCallback(onMqttMessage);

  pinMode(vibrationdc, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(vibrationdc, LOW);
}

void loop() {
  if (!mqttClient.connected()) {
    connectToMQTT();
  }
  mqttClient.loop();

  heartrate();
  nb_delay(falldown, prev_time_acce, SAMPLE_INTERVAL_MS);

  //Turn off motor after the set duration
//  if(motorActive && (millis() - motorStartTime >= motorVibrationDuration)){
//    digitalWrite(vibrationdc, LOW);
//    motorActive = false;
//  }

  // clear BLEScan buffer to release memory
  pBLEScan->clearResults();
}

void nb_delay(void (*func)(), unsigned long &prev_sampled_time, unsigned long sampling_interval) {
  unsigned long curr_time = millis();
  if (curr_time - prev_sampled_time >= sampling_interval) {
    prev_sampled_time = curr_time;
    func();
  }
}
