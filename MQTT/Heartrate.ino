#define USE_ARDUINO_INTERRUPTS true    // Set up low-level interrupts for accurate BPM math.
#include <PulseSensorPlayground.h>     // Includes the PulseSensorPlayground Library.
#include <WiFi.h>                      // Includes the Wi-Fi library.
#include <PubSubClient.h>              // Includes the PubSubClient library for MQTT.

// Wi-Fi Configuration
const char* ssid = "DT105_2.4GHz@unifi";       // Replace with your Wi-Fi SSID.
const char* password = "112233DT"; // Replace with your Wi-Fi password.

// MQTT Configuration
const char* mqtt_server = "192.168.0.7"; // Public Eclipse Mosquitto broker.
const int mqtt_port = 1883;                    // Default MQTT port.
const char* mqtt_topic = "heartRate/BPM";      // Topic to publish heart rate data.

WiFiClient espClient;
PubSubClient client(espClient);

// Variables
const int PulseWire = 34;       // PulseSensor PURPLE WIRE connected to GPIO36 (ADC1_CH0).
const int LED = 2;      // Onboard LED on ESP32 (usually GPIO2).
int Threshold = 550;            // Threshold value to detect beats.

PulseSensorPlayground pulseSensor;  // Creates an instance of the PulseSensorPlayground object.

void setup() {
  Serial.begin(115200);         // Use 115200 baud for Serial Monitor for ESP32.

  // Configure the PulseSensor object.
  pulseSensor.analogInput(PulseWire);   
  pulseSensor.blinkOnPulse(LED);  // Blink the onboard LED with a heartbeat.
  pulseSensor.setThreshold(Threshold);   

  // Initialize the PulseSensor object.
  if (pulseSensor.begin()) {
    Serial.println("PulseSensor object created!");
  } else {
    Serial.println("Failed to initialize PulseSensor.");
  }

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

  // Get BPM from the pulse sensor
  int myBPM = pulseSensor.getBeatsPerMinute();

  // Check if a beat is detected
  if (pulseSensor.sawStartOfBeat()) {
    Serial.println("♥ A HeartBeat Happened!");
    Serial.print("BPM: ");
    Serial.println(myBPM);

    // Publish BPM to MQTT broker
    char payload[50];
    snprintf(payload, 50, "{\"BPM\": %d}", myBPM); // Format data as JSON
    client.publish(mqtt_topic, payload);

    Serial.println("BPM data sent to MQTT broker.");
  }

  delay(20); // Delay for stability
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
    if (client.connect("ESP32_HeartRateMonitor")) { // Set a unique client ID
      Serial.println("Connected to MQTT broker.");
    } else {
      Serial.print("Failed, rc=");
      Serial.print(client.state());
      Serial.println(" -> Retrying in 5 seconds.");
      delay(5000);
    }
  }
}

///*  PulseSensor Starter Project and Signal Tester
// *  The Best Way to Get Started  With, or See the Raw Signal of, your PulseSensor.com™ & Arduino.
// *
// *  Here is a link to the tutorial
// *  https://pulsesensor.com/pages/code-and-guide
// *
// *  WATCH ME (Tutorial Video):
// *  https://www.youtube.com/watch?v=RbB8NSRa5X4
// *
// *
//-------------------------------------------------------------
//1) This shows a live human Heartbeat Pulse.
//2) Live visualization in Arduino's Cool "Serial Plotter".
//3) Blink an LED on each Heartbeat.
//4) This is the direct Pulse Sensor's Signal.
//5) A great first-step in troubleshooting your circuit and connections.
//6) "Human-readable" code that is newbie friendly."
//
//*/
//
//
////  Variables
//int PulseSensorPurplePin = 34;        // Pulse Sensor PURPLE WIRE connected to ANALOG PIN 0
//int LED13 = 2;   //  The on-board Arduion LED
//
//
//int Signal;                // holds the incoming raw data. Signal value can range from 0-1024
//int Threshold = 2000;       // Determine which Signal to "count as a beat", and which to ingore.
//
//
//// The SetUp Function:
//void setup() {
//  pinMode(LED13,OUTPUT);         // pin that will blink to your heartbeat!
//   Serial.begin(9600);       // Set's up Serial Communication at certain speed.
//
//}
//
//// The Main Loop Function
//void loop() {
//
//  Signal = analogRead(PulseSensorPurplePin);  // Read the PulseSensor's value.
//                                              // Assign this value to the "Signal" variable.
//
//   Serial.println("Signal " + String(Signal)); // Send "reading " followed by the Signal value to Serial Plotter.
//
//
//   if(Signal > Threshold){                          // If the signal is above "550", then "turn-on" Arduino's on-Board LED.
//     digitalWrite(LED13,HIGH);
//   } else {
//     digitalWrite(LED13,LOW);                //  Else, the sigal must be below "550", so "turn-off" this LED.
//   }
//
//
//delay(20);
//
//
//}
