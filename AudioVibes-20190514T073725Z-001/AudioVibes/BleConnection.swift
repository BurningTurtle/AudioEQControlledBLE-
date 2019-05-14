//
//  BleConnection.swift
//  AudioVibes
//

import CoreBluetooth

class BleConnection: NSObject, CBPeripheralDelegate {
    
    
    var peripheral : CBPeripheral
    var audioVibe : AudioVibes!
    
    var bands : CBCharacteristic?
    var magnitudeArray : CBCharacteristic?
    
    init(peripheral: CBPeripheral)
    {
        self.peripheral = peripheral
        super.init()
        peripheral.delegate = self
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        
        for service in peripheral.services! {
            print("Found service \(service)")
            if service.UUID == BLEParameters.vibesService {
                peripheral.discoverCharacteristics(nil, forService: service )
            }
        }
    }
    
    func returnPeripheral() -> CBPeripheral{
        return peripheral
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        for i in service.characteristics!
        {
      
                print("Found characteristic \(i)")
                switch i.UUID {
                case BLEParameters.magnitudeArray: magnitudeArray = i
                default: break
                }
        }
       
        NSNotificationCenter.defaultCenter().postNotificationName(AVNotifications.ConnectionComplete, object: nil)
    }
    
    
    private func bleWriteMagnitudeArray(var val: [UInt16], char: CBCharacteristic)
    {
        let ns = NSData(bytes: &val, length: 14)
        peripheral.writeValue(ns, forCharacteristic: char, type: CBCharacteristicWriteType.WithoutResponse)
    }
    
    
    // Triggers the write function if the value != nil.
    func writeMagnitudeArray(val : [UInt16])
    {
        if (magnitudeArray != nil) {
            bleWriteMagnitudeArray(val, char: magnitudeArray!)
        }
        return
    }
}