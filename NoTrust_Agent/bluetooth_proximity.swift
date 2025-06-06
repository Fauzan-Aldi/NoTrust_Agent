import CoreBluetooth
import Foundation

class BluetoothProximityManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager?
    var targetPeripheral: CBPeripheral?
    let targetDeviceName = "Kenzie’s iPhone"
    let rssiThreshold = -70
    var stop = true
    var lock = locking_module()
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            if(stop){
                print("auto locknya mati bang")
                return
            }
            print("auto locknya nyala bang")
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
      
        peripheral.readRSSI()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if !stop {
            print("Disconnected from \(peripheral.name ?? "Unknown Device"). Attempting to reconnect...")
            centralManager?.connect(peripheral, options: nil)
        }
        
    }


    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        if stop{
            if let targetPeripheral = targetPeripheral {
                centralManager?.cancelPeripheralConnection(targetPeripheral)
            }
            return
        }
        
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

   
    func checkProximityAndLockIfNecessary(_ RSSI: NSNumber) {
        if RSSI.intValue < rssiThreshold {

            lock.lockScreen()

        } else if RSSI.intValue <= -30 && RSSI.intValue >= -50 && lock.isScreenLocked(){

            lock.openScreen()
        } else {

        }
        

    }
}


