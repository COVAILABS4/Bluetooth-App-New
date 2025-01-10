import bts  # Import Bluetooth Slave module for SPP

# Initialize the ESP32 as a Bluetooth Slave
device_name = "SLV-1"  # Name of the Bluetooth device
pairing_pin = "0000"  # Empty string to bypass pairing

# Initialize the Bluetooth slave
if bts.init(device_name, pairing_pin):
    print(f"Bluetooth device '{device_name}' initialized and open for connections.")
else:
    print("Failed to initialize Bluetooth.")
    raise SystemExit

# Bring up the Bluetooth interface
if bts.up():
    print("Bluetooth is ready and waiting for connections.")
else:
    print("Failed to bring up Bluetooth.")
    raise SystemExit

# Main loop for sending and receiving data
try:
    while True:
        # Check if the device is ready for communication
        if bts.ready():
            # Check if there is data in the buffer
            data_length = bts.data()
            if data_length > 0:
                # Read the data as a string
                received_data = bts.get_str(data_length)
                print(f"Received from Bluetooth: {received_data}")

                # Echo the received data back to the sender
                bts.send_str(f"Echo: {received_data}")

                # Print the data to the console
                print(f"Serial Output: {received_data}")
except KeyboardInterrupt:
    print("Program interrupted. Closing Bluetooth.")

# Clean up Bluetooth before exiting
finally:
    bts.close()  # Close the current connection
    bts.deinit()  # Deinitialize the Bluetooth module
    print("Bluetooth shut down.")
