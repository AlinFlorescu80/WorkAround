//
//  Item.swift
//  WorkAround
//
//  Created by Alin Florescu on 06.10.2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    var title: String
    var details: String  // Renamed from 'description' to 'details'
    
    init(timestamp: Date, title: String, details: String) {
        self.timestamp = timestamp
        self.title = title
        self.details = details
    }
}
