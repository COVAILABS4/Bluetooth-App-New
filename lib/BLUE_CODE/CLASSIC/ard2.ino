#include <BluetoothSerial.h> // Include BluetoothSerial library for ESP32

BluetoothSerial SerialBT; // Create BluetoothSerial object

String receivedData = ""; // Buffer to store received data

void setup()
{
  // Initialize Serial Monitor for debugging
  Serial.begin(115200);

  // Initialize Bluetooth
  SerialBT.begin("ESP32_BT"); // Start Bluetooth with the name "ESP32_BT"
  Serial.println("Bluetooth Started! You can pair with ESP32 using 'ESP32_BT' name");
}

void loop()
{
  // Check if data is received from Bluetooth device
  while (SerialBT.available())
  {
    char incomingChar = SerialBT.read(); // Read a character from Bluetooth
    if (incomingChar == '~')
    { // Check for the end of the message (newline)
      Serial.print("Received: ");
      Serial.println(receivedData); // Print the complete received data
      receivedData = "";            // Clear the buffer for the next message
    }
    else
    {
      receivedData += incomingChar; // Append character to buffer
    }
  }

  // Send data to Bluetooth device
  SerialBT.println("Hello from ESP32!"); // Send message over Bluetooth

  delay(1000); // Delay to control how often data is sent
}
