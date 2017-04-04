//
//  Muse.swift
//  hrvmuse
//
//  Created by René van Mil on 01-04-17.
//

import UIKit
import CoreBluetooth

protocol MuseDelegate {
    func museIsReady()
    func museDidReceiveValues(leftear: Double, leftforehead: Double, rightforehead: Double, rightear: Double)
}

class Muse: NSObject, CBCentralManagerDelegate, IXNMuseConnectionListener, IXNMuseDataListener, IXNMuseListener {

    static let sharedMuse = Muse()

    var delegate: MuseDelegate?

    var manager: IXNMuseManagerIos!
    var muse: IXNMuse?
    var museValues: [[NSNumber]] = []
    
    var centralManager: CBCentralManager!

    var ready = false

    func setup() {
        if AppConstants.ignoreMuse {
            ready = true
            delegate?.museIsReady()
        } else {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
    }
    
    func scan() {
        manager = IXNMuseManagerIos.sharedManager()
        manager.museListener = self
        manager.startListening()
    }
    
    func connect() {
        muse!.register(self)
        muse!.register(self, type: .alphaRelative)
        ready = true
        delegate?.museIsReady()
    }
    
    func run() {
        if AppConstants.ignoreMuse {
            return
        } else {
            if ready {
                muse!.runAsynchronously()
            }
        }
    }
    
    func stop() {
        if AppConstants.ignoreMuse {
            return
        } else {
            muse!.disconnect()
        }
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
    
    func receive(_ packet: IXNMuseConnectionPacket, muse: IXNMuse?) {
        switch packet.currentConnectionState {
        case .disconnected:
            print("disconnected state")
        case .connected:
            print("connected state")
        case .connecting:
            print("connecting state")
        case .needsUpdate:
            print("needsUpdate state")
        case .unknown:
            print("unknown state")
        }
    }
    
    func receive(_ packet: IXNMuseDataPacket?, muse: IXNMuse?) {
        if packet?.packetType() == .alphaRelative {
            let values = packet!.values()
            if museValues.count == 20 {
                // Calculate average and notify
                var leftear = 0.0
                var leftforehead = 0.0
                var rightforehead = 0.0
                var rightear = 0.0
                for values in museValues {
                    let le = (values[0].doubleValue.isNaN) ? 0.0 : values[0].doubleValue
                    leftear = leftear + le
                    let lf = (values[1].doubleValue.isNaN) ? 0.0 : values[1].doubleValue
                    leftforehead = leftforehead + lf
                    let rf = (values[2].doubleValue.isNaN) ? 0.0 : values[2].doubleValue
                    rightforehead = rightforehead + rf
                    let re = (values[3].doubleValue.isNaN) ? 0.0 : values[3].doubleValue
                    rightear = rightear + re
                }
                leftear = leftear / 20.0
                leftforehead = leftforehead / 20.0
                rightforehead = rightforehead / 20.0
                rightear = rightear / 20.0
                delegate?.museDidReceiveValues(leftear: leftear, leftforehead: leftforehead, rightforehead: rightforehead, rightear: rightear)
                NotificationCenter.default.post(name: Notification.Name(rawValue: AppNotifications.museValuesDidUpdate), object: self, userInfo: [
                    "leftear": leftear,
                    "leftforehead": leftforehead,
                    "rightforehead": rightforehead,
                    "rightear": rightear
                    ])
                museValues = []
            } else {
                // Collect
                museValues.append(values)
            }
        }
    }
    
    func receive(_ packet: IXNMuseArtifactPacket, muse: IXNMuse?) {
        // Not used
    }
    
    func museListChanged() {
        let muses = manager.getMuses()
        if muses.count > 0 {
            for muse in manager.getMuses() {
                if muse.getMacAddress() == AppConstants.macMuse {
                    manager.stopListening()
                    self.muse = muse
                    connect()
                }
            }
        }
    }
    
}
