#define USE_ARDUINO_INTERRUPTS true    // Set up low-level interrupts for accurate BPM math.
#include <BLEDevice.h>
#include <WiFi.h>

#include <PubSubClient.h>
#include <PulseSensorPlayground.h>     // Includes the PulseSensorPlayground Library.

#include <Wire.h>
#include <MPU6050.h>                   // Ensure the MPU6050 library is compatible with ESP32.
#include <math.h>

#define SIZEOF(a) (sizeof(a) / sizeof(*a))

#define DEVICE_UUID "da3db7d9-e7f7-4411-a1d4-747569a76711"

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

const int mqtt_port = 1883;
const char* mqtt_topic_location= "location/RSSI";
const char* mqtt_topic_heart= "heartRate/BPM";                // Topic to publish heart rate data.
const char* mqtt_topic_heartAlert = "heartRate/heartAlert";
const char* mqtt_topic_amplitude = "accelerometer/amplitude";
const char* mqtt_topic_angular = "accelerometer/ang";
const char* mqtt_topic_fallAlert = "accelerometer/fall";      // Topic for fall detection.
const char* mqtt_sub_queue = "queue/status";                  //Topic for queue status update
WiFiClient espClient;
PubSubClient mqttClient(espClient);

//Variables: BLE
const BLEUUID known_beacons[] = {
  BLEUUID("4fafc201-1fb5-459e-8fcc-c5c9c331914b"),
  BLEUUID("4fafc201-1fb5-459e-8fcc-c5c9c331914c")
};
static boolean doScan = false;
static BLERemoteCharacteristic* pRemoteCharacteristic;
static BLEAdvertisedDevice* myDevice;
static BLEClient* pClient = nullptr;
int previousRSSI = 0;
BLEScan* pBLEScan;

struct BleBeacon {
  BLEUUID uuid;
  int rssi;
};
BleBeacon bleBeacons[SIZEOF(known_beacons)] = {};

//Variables: heartrate
const int PulseWire =34;       // PulseSensor PURPLE WIRE connected to GPIO36 (ADC1_CH0).
const int LED = 2;      // Onboard LED on ESP32 (usually GPIO2).
int Threshold = 550;            // Threshold value to detect beats.

bool recordingStarted = false;       // Flag to track when measurement starts
PulseSensorPlayground pulseSensor;  // Creates an instance of the PulseSensorPlayground object.


//variables: falldown
// MPU6050 Configuration
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

//Time intervals for each operation
unsigned long prev_time_acce, prev_time_scan;
const int SAMPLE_INTERVAL = 100; // milliseconds

unsigned long prev_time_heart;
const int SAMPLE_INTERVAL_HEART = 100; // milliseconds

//Vibration DC motor
#define vibrationdc 23
static bool motorActive = false;
static unsigned long motorStartTime = 0;
const unsigned long motorVibrationDuration = 500;

void connectToMQTT() {
  while (!mqttClient.connected()) {
    Serial.print(F("Connecting to MQTT..."));
    if (mqttClient.connect("ESP32_Client")) {
      Serial.println(F("connected"));
      uint16_t packetIdSub = mqttClient.subscribe(mqtt_sub_queue, 2);
      Serial.print("Subscribing at QUEUE, packetId: ");
      Serial.println(packetIdSub);
      delay(3000);
    } else {
      Serial.print(F("failed, rc="));
      Serial.print(mqttClient.state());

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
    Serial.print(F("BLE Advertised Device found: "));
    Serial.println(advertisedDevice.toString().c_str());
    Serial.println(service.toString());

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
  Serial.println("Connected to Wi-Fi");
  //Serial.print("IP address: ");
  //Serial.println(WiFi.localIP());

}

//server/queue  onMqttMessage() is responsible for obtaining MQTT message from the subscribed topic
//and controlling the (outside exp: LED). The string variable 'messageTemp' holds the MQTT message.
void onMqttMessage(char* topic, byte* payload, unsigned int length) {
  Serial.println("\n Publish received.");
  Serial.print("Topic: ");
  Serial.println(topic);
  String messageTemp;
  for (int i = 0; i < length; i++){
    messageTemp += (char)payload[i];
  }
  Serial.print("Message: ");
  Serial.println(messageTemp);

  if (strncmp(DEVICE_UUID, messageTemp.c_str(), length) == 0) {
    digitalWrite(vibrationdc, HIGH);
    motorActive = true;
    motorStartTime = millis();
  }

  //Turn off motor after the set duration
  if(motorActive && (millis() - motorStartTime >= motorVibrationDuration)){
    digitalWrite(vibrationdc, LOW);
    motorActive = false;
  }
}

void heartrate() {
  static unsigned long startTime = 0;    // To track the start time of measurement
  static unsigned long lastBeatTime = 0; // Tracks the last time data was sent
  const unsigned long interval = 500;   // Delay interval in milliseconds (adjust as needed)
  int myBPM = pulseSensor.getBeatsPerMinute();

  if (pulseSensor.sawStartOfBeat()) {
    if (!recordingStarted){
      if(startTime == 0){
        startTime = millis();
      }
      if (millis() - startTime >= 4000) {
        Serial.print(" | Heart Rate: N/A");
        recordingStarted = true; // Enable recording after 7 secondsM
        Serial.println("Recording started. Data will now be sent to the MQTT server.");
      }
    } else if (millis() - lastBeatTime >= interval) {
      lastBeatTime = millis(); // Update the last beat time
      Serial.print(" | Heart Rate: ");
      Serial.println(myBPM);
      String payload_heart = String("{\"uuid\": \"");
      payload_heart.concat(DEVICE_UUID);
      payload_heart.concat("\", \"data\": { \"BPM\": \"");
      payload_heart.concat(String(myBPM));
      payload_heart.concat("\"}}");
      Serial.print("Publish data: ");
      Serial.println(payload_heart);
      mqttClient.publish(mqtt_topic_heart, payload_heart.c_str());
    }
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
  float amplitude = raw_amplitude * 10;  // Multiplied by 10 because values are between 0 to 1

  Serial.print(" | Amplitude: ");
  Serial.println(amplitude);
  // Publish acceleration magnitude to MQTT
  char payload_amplitude[50];
  snprintf(payload_amplitude, 50, "{\"Amplitude\": %.2f}", amplitude);
  mqttClient.publish(mqtt_topic_amplitude, payload_amplitude);

  if (amplitude <= 2 && trigger2 == false) { // If AM breaks lower threshold (0.4g)
    trigger1 = true;
    //Serial.println("TRIGGER 1 ACTIVATED");
  }
  if (trigger1 == true) {     // Detects initial potential fall
    trigger1count++;
    if (amplitude >= 12) { // If AM breaks upper threshold (3g)
      trigger2 = true;
      //    Serial.println("TRIGGER 2 ACTIVATED");
      trigger1 = false; trigger1count = 0;
    }
  }
  if (trigger2 == true) {   // Detects high amplitude (impact)
    trigger2count++;
    angleChange = pow(pow(gx, 2) + pow(gy, 2) + pow(gz, 2), 0.5);
    Serial.println(angleChange);
    if (angleChange >= 30 && angleChange <= 400) { // If orientation changes by between 80-100 degrees
      trigger3 = true; trigger2 = false; trigger2count = 0;
      //    Serial.println(angleChange);
      //    Serial.println("TRIGGER 3 ACTIVATED");
    }
  }
  if (trigger3 == true) {   // Monitors orientation changes (e.g. lying on the ground)
    trigger3count++;

    if (trigger3count >= 10) {
      angleChange = pow(pow(gx, 2) + pow(gy, 2) + pow(gz, 2), 0.5);
      //     Serial.println(angleChange);
      if ((angleChange >= 0) && (angleChange <= 10)) { // If orientation changes remain between 0-10 degrees
        fall = true; trigger3 = false; trigger3count = 0;
        //       Serial.println(angleChange);
      }

      else { // User regained normal orientation
        trigger3 = false; trigger3count = 0;
        //       Serial.println("TRIGGER 3 DEACTIVATED");
      }
    }
  }

  if (fall == true && !motorActive) { // In the event of a fall detection
    memset(bleBeacons, 0, sizeof(bleBeacons));
    pBLEScan->start(5, false);
    Serial.println("Fall detected!");
    // Additional logic for alerts (e.g., buzzer, SMS, LED)
    // Publish fall detection event to MQTT
    Serial.print("size: ");
    Serial.println(SIZEOF(bleBeacons));
    for (int i = 0; i < SIZEOF(bleBeacons); i++) {
            Serial.print("uuid: ");
            Serial.println(bleBeacons[i].uuid.toString());
            Serial.print("rssi: ");
            Serial.println(bleBeacons[i].rssi);
    }
    String location = printAndSendRSSI();
    String fallAlert = String("{\"uuid\": \"");
    fallAlert.concat(DEVICE_UUID);
    fallAlert.concat("\", \"data\": { \"location\": \"");
    fallAlert.concat(location);
    fallAlert.concat("\"}}");
    mqttClient.publish(mqtt_topic_fallAlert, fallAlert.c_str());
    Serial.println(fallAlert);
    fall = false;
    memset(bleBeacons, 0, sizeof(bleBeacons));
    pBLEScan->start(5, false);
  }

  if (trigger2count >= 6) { // Allow 0.5s for orientation change
    trigger2 = false; trigger2count = 0;
    //   Serial.println("TRIGGER 2 DEACTIVATED");
  }
  if (trigger1count >= 6) { // Allow 0.5s for AM to break upper threshold
    trigger1 = false; trigger1count = 0;
    //    Serial.println("TRIGGER 1 DEACTIVATED");
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
  
  //Configure for heartrate
  pulseSensor.analogInput(PulseWire);
  pulseSensor.blinkOnPulse(LED);  // Blink the onboard LED with a heartbeat.
  pulseSensor.setThreshold(Threshold);
  pulseSensor.begin();

  //configure for falldown
  Wire.begin();
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x6B);  // PWR_MGMT_1 register
  Wire.write(0);     // Set to zero (wakes up the MPU-6050)
  Wire.endTransmission(true);

  connectWifi();

  mqttClient.setCallback(onMqttMessage);
  mqttClient.setServer(MQTT_SERVER, mqtt_port);

  pinMode(vibrationdc, OUTPUT);
  digitalWrite(vibrationdc, LOW);
}

void loop() {

  unsigned long currTime_scan = millis();
  if (currTime_scan - prev_time_scan >= 5000){
    prev_time_scan = currTime_scan;
    
}

  if (!mqttClient.connected()) {
    connectToMQTT();
  }
  mqttClient.loop();

  // if (doConnect) {
  //   if (connectToServer()) {
  //     Serial.println(F("We are now connected to the BLE Server."));
  //   } else {
  //     Serial.println(F("Failed to connect to the server."));
  //   }
  //   doConnect = false;
  // }

  // if (connected) {
  //   locationMessage = printAndSendRSSI();
  // } else if (doScan) {
  //   BLEDevice::getScan()->start(0);
  // }

  unsigned long currTime_acce = millis();
  if (currTime_acce - prev_time_acce >= SAMPLE_INTERVAL){
    prev_time_acce = currTime_acce;
    falldown();
  }

  unsigned long currTime_heart = millis();
  if (currTime_heart - prev_time_heart >= SAMPLE_INTERVAL_HEART){    //100ms
    prev_time_heart = currTime_heart;
    heartrate();
  }

  // NOTE: clear BLEScan buffer to release memory
  pBLEScan->clearResults();

  // TODO: do we need delay here?
  // delay(200);
}
