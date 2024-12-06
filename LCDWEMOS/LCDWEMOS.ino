#include <LiquidCrystal.h>

// Initialize the library with the numbers of the interface pins
// RS, E, D4, D5, D6, D7
const int rs = D8, en = D9, db4 = D5, db5 =D6, db6 =D7, db7 =D2, ct=D11;
//const int rs = 0, en = 2, db4 = 14, db5 = 12, db6 = 13, db7 = 15;
LiquidCrystal lcd(rs, en, db4, db5, db6, db7);

void setup() {
  analogWrite(ct,160);
  // Set up the LCD's number of columns and rows:
  lcd.begin(16, 4);

}

void loop() {
  // Move cursor to the second line
    // Print a message to the LCD.
  lcd.setCursor(0,0);
  lcd.print("Hello, Wemos!");
  lcd.setCursor(0, 1);

  lcd.print("ESP8266 Board");
}
