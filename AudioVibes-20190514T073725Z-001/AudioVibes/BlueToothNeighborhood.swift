//
// BlueToothNeighbourHood.swift
// AudioVibes
//

import CoreBluetooth

class BlueToothNeighborhood: NSObject, CBCentralManagerDelegate  {
    
    var centralManager : CBCentralManager!
    var audioVibes = [AudioVibes]()
    private var blueToothReady = false
    
    // MARK: - Function to control the central manager
    
    func startUpCentralManager() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func discoverDevices() {
        centralManager.scanForPeripheralsWithServices([BLEParameters.vibesService], options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
    }
    
    func connectToDevice(peripheral: CBPeripheral)
    {
        centralManager.connectPeripheral(peripheral, options: nil)
    }
    
    func disconnectDevice(peripheral : CBPeripheral)
    {
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    
    // MARK: - CBCentralManager Delegate Functions

    // called when you see an advertising packet
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber)
    {
        if searchDevices(peripheral) == nil {
            print("Found a new Periphal advertising vibesService")
            let newVibe = AudioVibes(connection: BleConnection(peripheral: peripheral))
            audioVibes.append(newVibe)
            NSNotificationCenter.defaultCenter().postNotificationName(AVNotifications.FoundDevice, object: nil)
        }
    }
    
    // disconnected a device
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("Disconnected \(peripheral)")
        NSNotificationCenter.defaultCenter().postNotificationName(AVNotifications.DisconnectedDevice, object: nil)

    }
    
    // a device connection is complete
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("Connection complete")
        peripheral.discoverServices(nil)
     }
    
    func searchDevices(peripheral : CBPeripheral) -> Int?
    {
        for i in 0..<audioVibes.count {
            if audioVibes[i].connection.peripheral == peripheral {
                return i
            }
        }
        return nil
    }
    
    @objc func centralManagerDidUpdateState(central: CBCentralManager) {
        switch (central.state) {
        case .PoweredOff: break
        case .PoweredOn: blueToothReady = true
        case .Resetting: break
        case .Unauthorized: break
        case .Unknown:break
        case .Unsupported:break
            
        }
        if blueToothReady {
            discoverDevices()
        }
    }
}

