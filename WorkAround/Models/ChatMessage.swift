//
//  ChatMessage.swift
//  WorkAround
//
//  Created by Alin Florescu on 21.04.2025.
//

import Foundation
import FirebaseFirestore

struct ChatMessage: Identifiable, Codable {
    @DocumentID var id: String?
    var sender: String
    var text: String
    var timestamp: Date
}
