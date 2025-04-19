    //
    //  KanbanBoardViewModel.swift
    //  WorkAround
    //
    //  Created by Alin Florescu on 05.04.2025.
    //

import Foundation
import Firebase
import FirebaseAuth

class KanbanBoardViewModel: ObservableObject {
    @Published var columns: [KanbanColumn] = []
    
    private let db = Firestore.firestore()
    private let boardID = "sharedBoard1" // Later, you can make this dynamic
    
    init() {
        fetchColumns()
    }
    
    func fetchColumns() {
        db.collection("boards").document(boardID).collection("columns")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching columns: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                self.columns = documents.compactMap { try? $0.data(as: KanbanColumn.self) }
            }
    }
    
    func saveColumn(_ column: KanbanColumn) {
        print("📝 Attempting to save column titled: \(column.title)")
        
        var columnToSave = column
        
            // If column has no ID, generate a new document ID and assign it
        if columnToSave.firestoreId == nil {
            let newDocRef = db.collection("boards").document(boardID).collection("columns").document()
            columnToSave.firestoreId = newDocRef.documentID
        }
        
        guard let columnID = columnToSave.firestoreId else { return }
        
        do {
            try db.collection("boards").document(boardID)
                .collection("columns").document(columnID)
                .setData(from: columnToSave)
            
                // Update the column in the local array with the assigned ID
            if let index = columns.firstIndex(where: { $0.id == column.id }) {
                columns[index] = columnToSave
            }
            print("📦 Cards count: \(column.cards.count)")
            print("👤 Current user UID: \(Auth.auth().currentUser?.uid ?? "nil")")
            
        } catch {
            print("Error saving column: \(error.localizedDescription)")
        }
    }
}
