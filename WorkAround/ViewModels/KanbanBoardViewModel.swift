    // =============================================================
    //  KanbanBoardViewModel.swift — updated for AI task classification
    // =============================================================

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import CoreML // ← new
import SwiftUI

class KanbanBoardViewModel: ObservableObject {
    @Published var columns: [KanbanColumn] = []
    @Published var predictions: [String: String] = [:]   // card-id → importance label
    
        /// All users who can be assigned to tasks (owner + invited)
    @Published var invitedUsers: [String] = []
    @Published var boardTitle: String = ""
    
    private let db = Firestore.firestore()
    let boardID: String
    
        //  MARK: – Core ML model
    private let classifier: TaskImportanceClassifier = {
        do {
            return try TaskImportanceClassifier(configuration: MLModelConfiguration())
        } catch {
            fatalError("Failed to load TaskImportanceClassifier: \(error)")
        }
    }()
    
        //  MARK: – Lifecycle
    init(boardID: String) {
        self.boardID = boardID
        fetchInvitedUsers()
        fetchColumns()
        fetchBoardTitle()
    }
        /// Fetches the board title from Firestore and stores it in `boardTitle`
    private func fetchBoardTitle() {
        db.collection("boards").document(boardID).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let title = data["title"] as? String {
                DispatchQueue.main.async {
                    self.boardTitle = title
                }
            } else if let error = error {
                print("Error fetching board title: \(error.localizedDescription)")
            }
        }
    }
    
        //  MARK: – Networking / data
    func fetchColumns() {
        db.collection("boards")
            .document(boardID)
            .collection("columns")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching columns: \(error?.localizedDescription ?? "alt fel de eroare la fetch")")
                    return
                }
                self.columns = documents
                    .compactMap { try? $0.data(as: KanbanColumn.self) }
                    .sorted { $0.order < $1.order }
            }
    }
    
    func saveColumn(_ column: KanbanColumn) {
        var columnToSave = column
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
    
        /// Deletes a column document from Firestore
    func deleteColumn(_ column: KanbanColumn) {
        guard let columnID = column.firestoreId else { return }
        db
            .collection("boards")
            .document(boardID)
            .collection("columns")
            .document(columnID)
            .delete { error in
                if let error = error {
                    print("Error deleting column: \(error.localizedDescription)")
                }
            }
    }
    
    func descriptiveText(for label: String) -> String {
        switch label {
            case "DataValue(6)":
                return "High Importance"
            case "DataValue(5)":
                return "Medium Importance"
            case "DataValue(4)":
                return "Moderate Importance"
            case "DataValue(3)":
                return "Low Importance"
            case "DataValue(2)":
                return "Very Low Importance"
            case "DataValue(1)":
                return "Negligible Importance"
            default:
                return "Unknown Importance"
        }
    }
    
        //  MARK: – AI helpers
        /// Classifies every card’s `title` using the Core ML model and stores the prediction in `predictions`.
    func classifyAllTasks() {
        DispatchQueue.global(qos: .userInitiated).async {
            var newPredictions: [String: String] = [:]
            for column in self.columns {
                for card in column.cards {
                    do {
                        let result = try self.classifier.prediction(text: card.title)
                        newPredictions[card.id] = result.label
                        print("S-a clasificat cu AI \(result.label)")  // pentru testing
                    } catch {
                        print("Prediction failed for \(card.title): \(error)")
                    }
                }
            }
            DispatchQueue.main.async {
                withAnimation {
                    self.predictions = newPredictions
                }
            }
        }
    }
    
        /// Fetch the list of invited users (including owner) from the board document
    func fetchInvitedUsers() {
        db.collection("boards").document(boardID)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data(),
                      let invited = data["invited"] as? [String] else { return }
                    // Include the owner’s email
                let ownerEmail = Auth.auth().currentUser?.email
                let all = invited + [ownerEmail].compactMap { $0 }
                DispatchQueue.main.async {
                    self.invitedUsers = Array(Set(all))
                }
            }
    }
    
        /// Add an assignee to a specific card and save the containing column
    func addAssignee(_ userEmail: String, toCardID cardID: String) {
        for index in columns.indices {
            if let cardIndex = columns[index].cards.firstIndex(where: { $0.id == cardID }) {
                columns[index].cards[cardIndex].assignees.append(userEmail)
                saveColumn(columns[index])
                break
            }
        }
    }
    
        /// Remove an assignee from a specific card and save the containing column
    func removeAssignee(_ userEmail: String, fromCardID cardID: String) {
        for index in columns.indices {
            if let cardIndex = columns[index].cards.firstIndex(where: { $0.id == cardID }) {
                columns[index].cards[cardIndex].assignees.removeAll(where: { $0 == userEmail })
                saveColumn(columns[index])
                break
            }
        }
    }
}
