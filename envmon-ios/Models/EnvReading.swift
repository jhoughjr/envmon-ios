//
//  EnvReading.swift
//  envmon-ios
//
//  Created by Jimmy Hough Jr on 6/28/24.
//


import Foundation
import SwiftData

@Model
final class EnvReading {
    
    var timestamp: Date
    var co2ppm: Int16
    var percentRH: Float
    var degreesC: Float
    
    init(timestamp: Date, co2: Int16, hum: Float, tmp: Float) {
        self.timestamp = timestamp
        self.degreesC = tmp
        self.percentRH = hum
        self.co2ppm = co2
    }
}
