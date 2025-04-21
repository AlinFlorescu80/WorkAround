//
//  KanbanDropDelegates.swift
//  WorkAround
//
//  Created by Alin Florescu on 18.02.2025.
//

import SwiftUI

struct CardDropDelegate: DropDelegate {
    let targetCard: KanbanCard
    @Binding var targetColumn: KanbanColumn
    @Binding var allColumns: [KanbanColumn]
    
    func performDrop(info: DropInfo) -> Bool {
        handleDrop(info: info)
    }
    
    private func handleDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }
        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
            DispatchQueue.main.async {
                if let data = data as? Data,
                   let idString = String(data: data, encoding: .utf8),
                   let draggedCardID = UUID(uuidString: idString) {
                    moveCard(with: draggedCardID)
                }
            }
        }
        return true
    }
    
    private func moveCard(with draggedCardID: UUID) {
        for i in allColumns.indices {
            if let removeIndex = allColumns[i].cards.firstIndex(where: { UUID(uuidString: $0.id ?? "") == draggedCardID }) {
                let movingCard = allColumns[i].cards.remove(at: removeIndex)
                if let targetIndex = targetColumn.cards.firstIndex(where: { $0.id == targetCard.id }) {
                    targetColumn.cards.insert(movingCard, at: targetIndex)
                } else {
                    targetColumn.cards.append(movingCard)
                }
                break
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

struct ColumnDropDelegate: DropDelegate {
    @Binding var targetColumn: KanbanColumn
    @Binding var allColumns: [KanbanColumn]
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }
        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
            DispatchQueue.main.async {
                if let data = data as? Data,
                   let idString = String(data: data, encoding: .utf8),
                   let draggedCardID = UUID(uuidString: idString) {
                    moveCard(with: draggedCardID)
                }
            }
        }
        return true
    }
    
    private func moveCard(with draggedCardID: UUID) {
        for i in allColumns.indices {
            if let removeIndex = allColumns[i].cards.firstIndex(where: {UUID(uuidString: $0.id ?? "" ) == draggedCardID}) {
                let movingCard = allColumns[i].cards.remove(at: removeIndex)
                targetColumn.cards.append(movingCard)
                break
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
