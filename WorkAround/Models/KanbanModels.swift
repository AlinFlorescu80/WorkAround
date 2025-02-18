//
//  KanbanModels.swift
//  WorkAround
//
//  Created by Alin Florescu on 18.02.2025.
//

import SwiftUI

struct KanbanColumn: Identifiable {
    let id = UUID()
    var title: String
    var cards: [KanbanCard]
}

struct KanbanCard: Identifiable, Equatable {
    let id: UUID = UUID()
    var title: String
    var details: String
}
