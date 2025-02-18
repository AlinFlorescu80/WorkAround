//
//  Item.swift
//  WorkAround
//
//  Created by Alin Florescu on 18.02.2025.
//


import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    var title: String
    var details: String  
    
    init(timestamp: Date, title: String, details: String) {
        self.timestamp = timestamp
        self.title = title
        self.details = details
    }
}
