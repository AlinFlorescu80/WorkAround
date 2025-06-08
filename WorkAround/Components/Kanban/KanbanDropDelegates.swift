    //
    //  KanbanDropDelegates.swift
    //  WorkAround
    //
    //  Created by Alin Florescu on 18.02.2025.
    //

import SwiftUI

struct ColumnDropDelegate: DropDelegate {
    @Binding var targetColumn: KanbanColumn
    @Binding var allColumns: [KanbanColumn]
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }
        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
            DispatchQueue.main.async {
                if let data = data as? Data,
                   let idString = String(data: data, encoding: .utf8) {
                    for i in allColumns.indices {
                        if let idx = allColumns[i].cards.firstIndex(where: { $0.id == idString }) {
                            let card = allColumns[i].cards.remove(at: idx)
                                // Directly move the card into the target column
                            if !targetColumn.cards.contains(where: { $0.id == card.id }) {
                                targetColumn.cards.append(card)
                            }
                            break
                        }
                    }
                }
            }
        }
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}
