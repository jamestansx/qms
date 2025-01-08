#include <LiquidCrystal.h>
#include <Wire.h>

// Pin configuration
const int rs = 12, en = 11, d4 = 5, d5 = 4, d6 = 3, d7 = 2, ct = 9; 
LiquidCrystal mylcd(rs, en, d4, d5, d6, d7);

void setup() {
  // Adjust contrast using PWM
  analogWrite(ct, 160); // Adjust value (0-255) for optimal contrast

  Wire.begin(4);        // Initialize I2C with
  Wire.onReceive(receiveEvent); // Register event
  Serial.begin(9600);        // Start serial for debugging

  // Initialize the LCD for 16x4
  mylcd.begin(16, 4);

  // Delay for LCD initialization
  delay(1000);

  // Display welcome message
  Serial.println("START");
    mylcd.setCursor(0, 0); // Column 0, Row 0
  mylcd.print("---QMS System---");
  mylcd.setCursor(0, 1); // Column 0, Row 0
  mylcd.print("Hello,welcome to");
  mylcd.setCursor(0, 2); // Column 0, Row 0
  mylcd.print("UTeM Hospital.");
}

void receiveEvent(int howMany) {
  Serial.print("Scanning......");
  String buf;
  Serial.println("-------------------");
  Serial.println("Bytes received: " + String(howMany));
  Serial.println("-------------------");
  while (Wire.available()) {
    int c = Wire.read(); // Receive byte as a character
    Serial.println("Received: " + String(c)); // Print the character to Serial Monitor
    buf += (char)c; // Add character to string buffer
  }

  // Clear the LCD to remove any old text
  mylcd.clear(); 

    // Display the message on the LCD line by line
  int start = 0; // Start index of the substring
  int line = 0;  // Current LCD line (0 to 3 for a 16x4 LCD)
  while (start < buf.length() && line < 4) {
    mylcd.setCursor(0, line); // Set cursor to the beginning of the current line
    mylcd.print(buf.substring(start, start + 16)); // Print 16 characters at a time
    start += 16; // Move to the next 16 characters
    line++; // Move to the next line
  }
//  // Display the received data (e.g., QR code link)
//  mylcd.setCursor(0, 0); // Start at the top-left
//  mylcd.print(buf); // Print the new message
}

void loop() {
  // Nothing here for now
}
