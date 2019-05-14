//
//  AudioVibes.swift
//  AudioVibes
//


class AudioVibes {
    var connection : BleConnection
    
    init (connection : BleConnection)
    {
        self.connection = connection
        connection.audioVibe = self
    }
    
    var magnitudeArray : [UInt16] = [0, 0, 0, 0, 0, 0, 0] {
        didSet {
            connection.writeMagnitudeArray(magnitudeArray)
        }
    }
}
