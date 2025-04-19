    //
    //  KanbanBoardViewModel.swift
    //  WorkAround
    //
    //  Created by Alin Florescu on 05.04.2025.
    //

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore

class KanbanBoardViewModel: ObservableObject {
    @Published var columns: [KanbanColumn] = []
    
    private let db      = Firestore.firestore()
    private let boardID = "sharedBoard1"   // Later, you can make this dynamic
    
        // MARK: – Lifecycle -------------------------------------------------------
    
    init() {
        fetchColumns()
    }
    
        // MARK: – Networking ------------------------------------------------------
    
        /// Live‑updates `columns` from Firestore and keeps them sorted by `order`.
    func fetchColumns() {
        db.collection("boards")
            .document(boardID)
            .collection("columns")
            .addSnapshotListener { snapshot, error in
                
                guard let documents = snapshot?.documents else {
                    print("Error fetching columns: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.columns = documents
                    .compactMap { try? $0.data(as: KanbanColumn.self) }
                    .sorted { $0.order < $1.order }          // 👈 maintain manual order
            }
    }
    
        /// Saves (or updates) a column document in Firestore and patches the local array.
    func saveColumn(_ column: KanbanColumn) {
        print("📝 Attempting to save column titled: \(column.title)")
        
        var columnToSave = column
        
            // If the column hasn’t been pushed yet, give it a Firestore ID.
        if columnToSave.firestoreId == nil {
            let newDocRef = db.collection("boards")
                .document(boardID)
                .collection("columns")
                .document()
            columnToSave.firestoreId = newDocRef.documentID
        }
        
        guard let columnID = columnToSave.firestoreId else { return }
        
        do {
            try db.collection("boards")
                .document(boardID)
                .collection("columns")
                .document(columnID)
                .setData(from: columnToSave)
            
                // Keep local state in sync with any new ID or field changes.
            if let idx = columns.firstIndex(where: { $0.id == column.id }) {
                columns[idx] = columnToSave
            }
            
            print("📦 Cards count: \(column.cards.count)")
            print("👤 Current user UID: \(Auth.auth().currentUser?.uid ?? "nil")")
            
        } catch {
            print("Error saving column: \(error.localizedDescription)")
        }
    }
}
