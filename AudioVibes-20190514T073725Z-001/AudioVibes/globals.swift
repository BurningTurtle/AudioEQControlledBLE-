//
//  globals.swift
//  AudioVibes
//

import CoreBluetooth

//  Identify the NSNotification Messages
struct AVNotifications {
    static let FoundDevice = "com.cypress.audiovibes.founddevice"
    static let ConnectionComplete = "com.cypress.audiovibes.connectioncomplete"
    static let DisconnectedDevice = "com.cypress.audiovibes.disconnecteddevice"
}

// Identify the UUIDs of the services and characteristics for AudioVibes
struct BLEParameters {
    static let vibesService = CBUUID(string: "00000000-0000-1000-8000-00805F9B34F0")
    static let magnitudeArray = CBUUID(string: "00000000-0000-1000-8000-00805F9B34F1")
}
