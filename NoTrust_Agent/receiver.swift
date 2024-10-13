//
//  receiver.swift
//  NoTrust_Agent
//
//  Created by Kenzie Nabeel on 24/09/24.
//

import CoreBluetooth
import Foundation

class receiver: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager?
    var discoveredPeripheral: CBPeripheral?
    var lockCharacteristic: CBCharacteristic?
    var lockingModule = locking_module()
    
    override init(){
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn{
            startScanning()
        }
    }
    
    func startScanning() {
        let serviceUUID = CBUUID(string: "522d268a-d7eb-441b-84f1-5f4e465ceedb")
        centralManager?.scanForPeripherals(withServices: [serviceUUID], options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber){
        discoveredPeripheral = peripheral
        centralManager?.stopScan()
        centralManager?.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral){
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: "522d268a-d7eb-441b-84f1-5f4e465ceedb")])
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        if let services = peripheral.services {
            for service in services {
                peripheral.discoverCharacteristics([CBUUID(string: "59e87c5e-4b70-4631-bc6c-a0d069f421c7")], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]){
        for service in invalidatedServices{
            print("Invalidated service: \(service.uuid)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == CBUUID(string: "59e87c5e-4b70-4631-bc6c-a0d069f421c7") {
                    lockCharacteristic = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                    print("Connected to iPhone")
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value, let command = String(data: data, encoding: .utf8) {
            if command == "LOCK" {
                lockingModule.lockScreen()
            } else if command == "UNLOCK" {
                lockingModule.openScreen()
            } else if command == "AUTOLOCK ON"{
                print("autolock nyala")
                bluetoothProximity.stop = false
            } else if command == "AUTOLOCK OFF"{
                print("autolock mati")
                bluetoothProximity.stop = true
            }
        }
    }

    
}
