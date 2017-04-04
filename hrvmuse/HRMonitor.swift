//
//  HRMonitor.swift
//  hrvmuse
//
//  Created by René van Mil on 31-03-17.
//

import UIKit
import CoreBluetooth

protocol HRMonitorDelegate {
    func hrMonitorIsReady()
    func hrMonitorDidReceiveRRInterval(rr: UInt16)
}

class HRMonitor: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let sharedMonitor = HRMonitor()
    
    var delegate: HRMonitorDelegate?
    
    var centralManager: CBCentralManager!
    var hrMeter: CBPeripheral?
    var hrCharacteristic: CBCharacteristic?
    
    var ready = false
    
    func setup() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        let services = [CBUUID(string: AppConstants.uuidHeartRate)]
        // HR meter may already be connected by the user
        let hrMeters = centralManager.retrieveConnectedPeripherals(withServices: services)
        if hrMeters.count > 0 {
            hrMeter = hrMeters.first
            hrMeter?.delegate = self
        }
    }
    
    func scan() {
        if hrMeter == nil {
            let services: [CBUUID] = [CBUUID(string: AppConstants.uuidHeartRate)]
            centralManager.scanForPeripherals(withServices: services, options: nil)
        } else {
            connect()
        }
    }
    
    func connect() {
        centralManager.connect(hrMeter!, options: nil)
    }
    
    func run() {
        if ready {
            hrMeter?.setNotifyValue(true, for: hrCharacteristic!)
            print("Enabled notifications for characteristic \(hrCharacteristic!.uuid):")
        } else {
            print("HR not ready")
        }
    }
    
    func stop() {
        hrMeter?.setNotifyValue(false, for: hrCharacteristic!)
    }
    
    func processHRCharacteristic(characteristic: CBCharacteristic) {
        let rxData = characteristic.value
        if let rxData = rxData {
            var flags = UInt8()
            var bpm = UInt8()
            let bpmRange = NSRange.init(location: 1, length: 1)
            let rrByteCount = rxData.count - 2
            var rrArray = [UInt16](repeating: 0, count: rrByteCount)
            let rrRange = NSRange.init(location: 2, length: rrByteCount)
            (rxData as NSData).getBytes(&flags, length: 1)
            (rxData as NSData).getBytes(&bpm, range: bpmRange)
            (rxData as NSData).getBytes(&rrArray, range: rrRange)
            for rr in rrArray {
                if rr != 0 {
                    delegate?.hrMonitorDidReceiveRRInterval(rr: rr)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: AppNotifications.rrIntervalDidUpdate), object: self, userInfo: ["rr": rr])
                }
            }
        }
    }

    // MARK: CBCentralManagerDelegate
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("Found device \(localName)")
            centralManager.stopScan()
            hrMeter = peripheral
            hrMeter!.delegate = self
            connect()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected")
        hrMeter!.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Connect failed")
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOff {
            print("Powered Off")
        } else if central.state == .poweredOn {
            print("Powered On")
            scan()
        } else if central.state == .resetting {
            print("Resetting")
        } else if central.state == .unauthorized {
            print("Unauthorized")
        } else if central.state == .unknown {
            print("Unknown")
        } else if central.state == .unsupported {
            print("Unsupported")
        }
    }
    
    
    // MARK: CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Discovered services:")
        for service in hrMeter!.services! {
            print("    \(service.uuid)")
            hrMeter!.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Discovered characteristics for service \(service.uuid):")
        for characteristic in service.characteristics! {
            print("    \(characteristic.uuid)")
            // Request heart rate notifications
            if service.uuid == CBUUID(string: AppConstants.uuidHeartRate) {
                if characteristic.uuid == CBUUID(string: AppConstants.uuidHeartRateMeasurement) {
                    hrCharacteristic = characteristic
                    ready = true
                    delegate?.hrMonitorIsReady()
                }
            }
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == CBUUID(string: AppConstants.uuidHeartRateMeasurement) {
            processHRCharacteristic(characteristic: characteristic)
        }
    }

}
