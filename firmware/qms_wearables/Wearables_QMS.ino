
#define USE_ARDUINO_INTERRUPTS true    // Set up low-level interrupts for accurate BPM math.
#include <BLEDevice.h>
#include <WiFi.h>

#include <PubSubClient.h>
#include <PulseSensorPlayground.h>     // Includes the PulseSensorPlayground Library.

#include <Wire.h>
#include <MPU6050.h>                   // Ensure the MPU6050 library is compatible with ESP32.
#include <math.h>

//In the DT house
const char* ssid = "DT105_2.4GHz@unifi";
const char* password = "112233DT";
const char* mqtt_server = "192.168.0.7";

//UTeM
//const char* ssid = "UTeM-Net";
//const char* password = "1UTeM@PPPK";
//const char* mqtt_server = "10.131.129.57";

////Ng
//const char* ssid = "Michael NG";
//const char* password = "weihan123456";
//const char* mqtt_server = "172.20.10.3";

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
static BLEUUID serviceUUID("4fafc201-1fb5-459e-8fcc-c5c9c331914b");
static BLEUUID charUUID("beb5483e-36e1-4688-b7f5-ea07361b26a8");
static boolean doConnect = false;
static boolean connected = false;
static boolean doScan = false;
static BLERemoteCharacteristic* pRemoteCharacteristic;
static BLEAdvertisedDevice* myDevice;
static BLEClient* pClient = nullptr;
int previousRSSI = 0;

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
unsigned long prev_time_acce, prev_time_queue;
const int SAMPLE_INTERVAL = 100; // milliseconds


unsigned long prev_time_heart;
const int SAMPLE_INTERVAL_HEART = 100; // milliseconds


//Vibration DC motor
#define vibrationdc 23
static bool motorActive = false;
static unsigned long motorStartTime = 0;
const unsigned long motorVibrationDuration = 500;


class MyClientCallback : public BLEClientCallbacks {
  void onConnect(BLEClient* pclient) {}

  void onDisconnect(BLEClient* pclient) {
    connected = false;
//    Serial.println(F("Disconnected from server"));
  }
};


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


bool connectToServer() {

  pClient = BLEDevice::createClient();
  pClient->setClientCallbacks(new MyClientCallback());
  pClient->connect(myDevice);
  Serial.println(F(" - Connected to server"));

  BLERemoteService* pRemoteService = pClient->getService(serviceUUID);
  if (pRemoteService == nullptr) {
  Serial.println(F("Failed to find our service UUID"));
    pClient->disconnect();
    return false;
  }

  pRemoteCharacteristic = pRemoteService->getCharacteristic(charUUID);
  if (pRemoteCharacteristic == nullptr) {
    Serial.println(F("Failed to find our characteristic UUID"));
    pClient->disconnect();
    return false;
  }

  connected = true;
  return true;
}

const char* printAndSendRSSI() {
  static char locationMessage[10];
  if (connected && pClient) {
    int rssi = pClient->getRssi();
    
    if (rssi > -50) {
      strcpy(locationMessage, "UUID: 1");
    } else if (rssi <= -50 && rssi > -70) {
      strcpy(locationMessage, "UUID: 2");
    } else if (rssi <= -70) {
      strcpy(locationMessage, "UUID: 3");
    }

    Serial.print(locationMessage);

    if (abs(rssi - previousRSSI) > 5) { // Update only if RSSI varies by 5 dBm or more
      mqttClient.publish(mqtt_topic_location, locationMessage);
      previousRSSI = rssi;
    }
  }else{
    strcpy(locationMessage, "N/A");
  }

  return locationMessage;
}

//server/queue  onMqttMessage() is responsible for obtaining MQTT message from the subscribed topic and controlling the (outside exp: LED). The string variable 'messageTemp' holds the MQTT message.
void onMqttMessage(char* topic, byte* payload, unsigned int length) {
  unsigned long currTime_queue = millis();
      if (currTime_queue - prev_time_queue >= SAMPLE_INTERVAL){
          prev_time_queue = currTime_queue;
          Serial.println("\n Publish received.");
          Serial.print("Topic: ");
          Serial.println(topic);
          String messageTemp;
          for (int i = 0; i < length; i++){
            messageTemp += (char)payload[i];
          }
          Serial.print("Message: ");
          Serial.println(messageTemp);
   }
}
      
class MyAdvertisedDeviceCallbacks : public BLEAdvertisedDeviceCallbacks {
  void onResult(BLEAdvertisedDevice advertisedDevice) {
    Serial.print(F("BLE Advertised Device found: "));
    Serial.println(advertisedDevice.toString().c_str());

    if (advertisedDevice.haveServiceUUID() && advertisedDevice.isAdvertisingService(serviceUUID)) {
      BLEDevice::getScan()->stop();
      myDevice = new BLEAdvertisedDevice(advertisedDevice);
      doConnect = true;
      doScan = true;
    }
  }
};

void setup() {
  Serial.begin(115200);

  //configure for ble 
  BLEDevice::init("");

  BLEScan* pBLEScan = BLEDevice::getScan();
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
  mqttClient.setServer(mqtt_server, mqtt_port);

  pinMode(vibrationdc, OUTPUT);
  digitalWrite(vibrationdc, LOW);
}

void loop() {

  if (!mqttClient.connected()) {
    connectToMQTT();
  }
  mqttClient.loop();
  
  if (doConnect) {
    if (connectToServer()) {
      Serial.println(F("We are now connected to the BLE Server."));
    } else {
      Serial.println(F("Failed to connect to the server."));
    }
    doConnect = false;
  }

  const char* locationMessage = nullptr; // Store the location message
  
  if (connected) {
    locationMessage = printAndSendRSSI();
  } else if (doScan) {
    BLEDevice::getScan()->start(0);
  }

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
     
//Serial.print(" | Amplitude: ");
//  Serial.print(ax, 2);
//  Serial.print(",");
//  Serial.print(ay, 2);
//  Serial.print(",");
//  Serial.print(az, 2);
//  Serial.print(" | Trigger1: ");
//  Serial.print(trigger1);
//  Serial.print(" | Trigger2: ");
//  Serial.print(trigger2);
//  Serial.print(" | Trigger3: ");
//  Serial.println(trigger3);

  delay(200);
}



void heartrate(){

  static unsigned long startTime = 0;    // To track the start time of measurement
  static unsigned long lastBeatTime = 0; // Tracks the last time data was sent
  const unsigned long interval = 500;   // Delay interval in milliseconds (adjust as needed)
  int myBPM = pulseSensor.getBeatsPerMinute();
  
  if (pulseSensor.sawStartOfBeat()) {
    if (!recordingStarted){
      if(startTime == 0){
      startTime = millis(); 
      }
     if (millis() - startTime >= 7000) {
          Serial.print(" | Heart Rate: N/A");
          recordingStarted = true; // Enable recording after 7 secondsM
          Serial.println("Recording started. Data will now be sent to the MQTT server.");
      }
    } else if (millis() - lastBeatTime >= interval) {
        lastBeatTime = millis(); // Update the last beat time
        Serial.print(" | Heart Rate: ");
        Serial.println(myBPM);
        char payload_heart[50];
        snprintf(payload_heart, 50, "{\"BPM\": %d}", myBPM); // Format data as JSON
        mqttClient.publish(mqtt_topic_heart, payload_heart);
   
      //Check BPM threshold
      if (myBPM < 30 || myBPM > 140 && !motorActive){
        digitalWrite(vibrationdc, HIGH);
        motorActive = true;
        motorStartTime = millis();
  
        const char* location = printAndSendRSSI();
        
        char heartAlert[60];       // array that hold a maximum of 50 Characters
        snprintf(heartAlert, 60, "{\"Warning\": \"Abnormal heart BPM\", \"Location\": \"%s\"}", location);
        mqttClient.publish(mqtt_topic_heartAlert, heartAlert);
        Serial.println(heartAlert);
      }
    }
  }
    //Turn off motor after the set duration
    if(motorActive && (millis() - motorStartTime >= motorVibrationDuration)){
      digitalWrite(vibrationdc, LOW);
      motorActive = false;
  }
}


void falldown(){
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

      Serial.println("Fall detected!");
      // Additional logic for alerts (e.g., buzzer, SMS, LED)
       // Publish fall detection event to MQTT
      digitalWrite(vibrationdc, HIGH);
      motorActive = true;
      motorStartTime = millis();

      const char* location = printAndSendRSSI();
      char fallAlert[60];
      snprintf(fallAlert, 60, "{\"falling_event\": true, \"location\": \"%s\"}", location);
      mqttClient.publish(mqtt_topic_fallAlert, fallAlert);
      Serial.println(fallAlert);
      fall = false;
    }

        //Turn off motor after the set duration
    if(motorActive && (millis() - motorStartTime >= motorVibrationDuration)){
      digitalWrite(vibrationdc, LOW);
      motorActive = false;
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


void connectWifi(){
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
  }
  Serial.println("Connected to Wi-Fi");
  //Serial.print("IP address: ");
  //Serial.println(WiFi.localIP());

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
