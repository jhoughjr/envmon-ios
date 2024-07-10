//
//  Item.swift
//  envmon-ios
//
//  Created by Jimmy Hough Jr on 6/28/24.
//

import Foundation
import SwiftData

@Model
final class Server {
    var timestamp: Date
    var name: String
    var address: String
    
    init(timestamp: Date? = Date(), name: String, addr: String) {
        self.name = name
        self.timestamp = timestamp ?? Date()
        self.address = addr
    }
}
