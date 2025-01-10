import asyncio
import aioble
import bluetooth

SERVICE_UUID = bluetooth.UUID("12345678-1234-5678-1234-56789abcdef0")
CHARACTERISTIC_UUID = bluetooth.UUID("12345678-1234-5678-1234-56789abcdef1")

# GATT Service and Characteristic
service = aioble.Service(SERVICE_UUID)
characteristic = aioble.Characteristic(
    service,
    CHARACTERISTIC_UUID,
    notify=True,
    write=True,
)
aioble.register_services(service)

async def advertise_and_wait():
    print("Advertising...")
    connection = await aioble.advertise(
        250000,
        name="MyBLEPeripheral",
        services=[SERVICE_UUID],
    )
    print(f"Connected to {connection.device}")
    return connection

async def handle_client(connection):
    try:
        while True:
            await characteristic.written()
            data = characteristic.read()
            print(f"Received data: {data.decode('utf-8')}")
    except aioble.DeviceDisconnectedError:
        print("Client disconnected.")

async def main():
    while True:
        connection = await advertise_and_wait()
        await handle_client(connection)

asyncio.run(main())

