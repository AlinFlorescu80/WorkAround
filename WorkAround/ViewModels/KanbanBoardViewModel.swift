    // =============================================================
    //  KanbanBoardViewModel.swift — updated for AI task classification
    // =============================================================

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import CoreML   // ← new
import SwiftUI

class KanbanBoardViewModel: ObservableObject {
    
        // MARK: – Published state
    @Published var columns: [KanbanColumn] = []
    @Published var predictions: [String: String] = [:]      // card-id → importance label
    @Published var invitedUsers: [String] = []              // owner + invited
    @Published var boardTitle: String = ""
    
        // MARK: – Private members
    private let db = Firestore.firestore()
    let boardID: String
    
        // MARK: – Core ML model
    private let classifier: TaskImportanceClassifier = {
        do {
            return try TaskImportanceClassifier(configuration: MLModelConfiguration())
        } catch {
            fatalError("Failed to load TaskImportanceClassifier: \(error)")
        }
    }()
    
        // MARK: – Lifecycle
    init(boardID: String) {
        self.boardID = boardID
        fetchInvitedUsers()
        fetchColumns()
        fetchBoardTitle()
    }
    
        // MARK: – Board metadata
    private func fetchBoardTitle() {
        db.collection("boards").document(boardID).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let title = data["title"] as? String {
                DispatchQueue.main.async { self.boardTitle = title }
            } else if let error = error {
                print("Error fetching board title: \(error.localizedDescription)")
            }
        }
    }
    
        // MARK: – Column CRUD
    func fetchColumns() {
        db.collection("boards")
            .document(boardID)
            .collection("columns")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching columns: \(error?.localizedDescription ?? "unknown error")")
                    return
                }
                self.columns = documents
                    .compactMap { try? $0.data(as: KanbanColumn.self) }
                    .sorted { $0.order < $1.order }
            }
    }
    
    func saveColumn(_ column: KanbanColumn) {
        var columnToSave = column
            // Assign a Firestore ID if it doesn’t have one yet
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
            if let idx = columns.firstIndex(where: { $0.id == column.id }) {
                columns[idx] = columnToSave
            }
        } catch {
            print("Error saving column: \(error.localizedDescription)")
        }
    }
    
    func deleteColumn(_ column: KanbanColumn) {
        guard let columnID = column.firestoreId else { return }
        db.collection("boards")
            .document(boardID)
            .collection("columns")
            .document(columnID)
            .delete { error in
                if let error = error {
                    print("Error deleting column: \(error.localizedDescription)")
                }
            }
    }
    
        // MARK: – Core ML helpers
    func classifyAllTasks() {
        DispatchQueue.global(qos: .userInitiated).async {
            var newPredictions: [String: String] = [:]
            for column in self.columns {
                for card in column.cards {
                    do {
                        let result = try self.classifier.prediction(text: card.title)
                        newPredictions[card.id] = result.label
                        print("Classified “\(card.title)” → \(result.label)")
                    } catch {
                        print("Prediction failed for \(card.title): \(error)")
                    }
                }
            }
            DispatchQueue.main.async {
                withAnimation { self.predictions = newPredictions }
            }
        }
    }
    
    func descriptiveText(for label: String) -> String {
        switch label {
            case "DataValue(6)": return "High Importance"
            case "DataValue(5)": return "Medium Importance"
            case "DataValue(4)": return "Moderate Importance"
            case "DataValue(3)": return "Low Importance"
            case "DataValue(2)": return "Very Low Importance"
            case "DataValue(1)": return "Negligible Importance"
            default:             return "Unknown Importance"
        }
    }
    
        // MARK: – Invited users
    private func fetchInvitedUsers() {
        db.collection("boards").document(boardID)
            .addSnapshotListener { snapshot, _ in
                guard let data = snapshot?.data(),
                      let invited = data["invited"] as? [String] else { return }
                let ownerEmail = Auth.auth().currentUser?.email
                let all = invited + [ownerEmail].compactMap { $0 }
                DispatchQueue.main.async {
                    self.invitedUsers = Array(Set(all))
                }
            }
    }
    
        // MARK: – Assignee helpers
    func addAssignee(_ userEmail: String, toCardID cardID: String) {
        for index in columns.indices {
            if let cardIndex = columns[index].cards.firstIndex(where: { $0.id == cardID }) {
                columns[index].cards[cardIndex].assignees.append(userEmail)
                break
            }
        }
    }
    
    func removeAssignee(_ userEmail: String, fromCardID cardID: String) {
        for index in columns.indices {
            if let cardIndex = columns[index].cards.firstIndex(where: { $0.id == cardID }) {
                columns[index].cards[cardIndex].assignees.removeAll { $0 == userEmail }
                break
            }
        }
    }
}
