#include <BluetoothSerial.h> // Include BluetoothSerial library for ESP32

BluetoothSerial SerialBT; // Create BluetoothSerial object

String incomingText = ""; // String to store incoming data

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
        char incomingByte = SerialBT.read(); // Read a byte from Bluetooth
        incomingText += incomingByte;        // Append the byte to the incomingText string
    }

    // If the incomingText has data, print it all at once
    if (incomingText.length() > 0)
    {
        Serial.print("Received: ");
        Serial.println(incomingText); // Print the entire string
        incomingText = "";            // Clear the string after printing
    }

    // Send data to Bluetooth device
    SerialBT.println("Hello from ESP32!"); // Send message over Bluetooth

    delay(1000); // Delay to control how often data is sent
}
