#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>

BLECharacteristic *pCharacteristic;
bool deviceConnected = false;

// Define the service and characteristic UUIDs
#define SERVICE_UUID "12345678-1234-5678-1234-56789abcdef0"
#define CHARACTERISTIC_UUID "12345678-1234-5678-1234-56789abcdef1"

// Callback class for handling device connection and disconnection
class MyServerCallbacks : public BLEServerCallbacks
{
    void onConnect(BLEServer *pServer)
    {
        deviceConnected = true;
        Serial.println("Client connected!");
    }

    void onDisconnect(BLEServer *pServer)
    {
        deviceConnected = false;
        Serial.println("Client disconnected!");
    }
};

class MyCharacteristicCallbacks : public BLECharacteristicCallbacks
{
    void onWrite(BLECharacteristic *pCharacteristic)
    {
        // Read the value written by the client as a String
        String value = pCharacteristic->getValue().c_str();
        Serial.print("Received data: ");
        Serial.println(value);

        // Optionally, you can process the data further or send a response back
    }
};

void setup()
{
    // Start the serial communication for debugging
    Serial.begin(115200);

    // Initialize BLE
    BLEDevice::init("ESPARDUINO"); // Device Name

    // Create the BLE Server
    BLEServer *pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks()); // Attach server callbacks

    // Set up the service
    BLEService *pService = pServer->createService(SERVICE_UUID);

    // Create the characteristic with read, notify, and write permissions
    pCharacteristic = pService->createCharacteristic(
        CHARACTERISTIC_UUID,
        BLECharacteristic::PROPERTY_READ |
            BLECharacteristic::PROPERTY_NOTIFY |
            BLECharacteristic::PROPERTY_WRITE // Enable write
    );

    // Set the value for the characteristic (initial value)
    pCharacteristic->setValue("Hello from ESP32");

    // Attach the write callback to the characteristic
    pCharacteristic->setCallbacks(new MyCharacteristicCallbacks());

    // Start the service
    pService->start();

    // Start advertising
    BLEAdvertising *pAdvertising = pServer->getAdvertising();
    pAdvertising->start();

    Serial.println("Waiting for a client to connect...");
}

void loop()
{
    if (deviceConnected)
    {
        // If a device is connected, print the data
        Serial.println("Device Connected");
        Serial.print("Characteristic Value: ");
        Serial.println(pCharacteristic->getValue().c_str());

        // Optionally, update the characteristic value
        pCharacteristic->setValue("Updated Value");
        pCharacteristic->notify(); // Notify the client with updated data
    }

    // Add a small delay to avoid spamming the serial monitor
    delay(1000);
}
