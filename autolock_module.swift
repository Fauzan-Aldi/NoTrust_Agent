import CoreBluetooth
import Foundation
import Cocoa
import Quartz

class BluetoothProximityManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager?
    var targetPeripheral: CBPeripheral?
    let targetDeviceName = "Kenzie’s iPhone"
    let rssiThreshold = -70
    var passwordEntered = false
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - CBCentralManagerDelegate Methods
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth is powered on. Scanning for devices...")
            centralManager?.scanForPeripherals(withServices: nil, options: nil)
        } else {
            print("Bluetooth is not available. State: \(central.state.rawValue)")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let deviceName = peripheral.name, deviceName == targetDeviceName {
            print("Discovered \(deviceName). Stopping scan and connecting...")
            centralManager?.stopScan()
            targetPeripheral = peripheral
            targetPeripheral?.delegate = self
            centralManager?.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unknown Device").")
        // Start monitoring RSSI after connection
        peripheral.readRSSI()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "Unknown Device"). Attempting to reconnect...")
        centralManager?.connect(peripheral, options: nil)
    }

    // MARK: - CBPeripheralDelegate Methods
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if let error = error {
            print("Error reading RSSI: \(error)")
            return
        }

        print("RSSI: \(RSSI)")
        checkProximityAndLockIfNecessary(RSSI)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.targetPeripheral?.readRSSI()
        }
    }

    // Monitor characteristics or services if necessary
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        // Handle received data if needed
    }

    // MARK: - Proximity Check and Screen Lock
    
    func checkProximityAndLockIfNecessary(_ RSSI: NSNumber) {
        if RSSI.intValue < rssiThreshold {
            print("iPhone is out of range. Locking the screen...")
            lockScreen()
//            passwordEntered = false
        } else if RSSI.intValue <= -30 && RSSI.intValue >= -50 && isScreenLocked(){
            // cek lg apakah macbooknya udh nyala screen ato belom
            print("iPhone is near. Unlocking screen...")
            openScreen()
        } else {
            print("iPhone is within range.")
        }
        

    }

    func lockScreen() {
        // Call a system command to lock the screen
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", "tell application \"System Events\" to keystroke \"q\" using {control down, command down}"]
        task.launch()
    }
    
    func openScreen(){
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", """
            tell application "System Events"
                keystroke "<password>"
                delay 1
                keystroke return
            end tell
            """]
        task.launch()
        
//        passwordEntered = true
    }
    
    func isScreenLocked() -> Bool{
        if let status = Quartz.CGSessionCopyCurrentDictionary() as? [String : Any],
           let isLocked = status["CGSSessionScreenIsLocked"] as? Bool{
            return isLocked
        } else {
            return false
        }
    }
}

// Initialize the BluetoothProximityManager
let bluetoothProximityManager = BluetoothProximityManager()

// Keep the app running to monitor the connection
RunLoop.main.run()




