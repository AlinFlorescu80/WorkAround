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
        fetchColumns()
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
                        // ── Update each card title with its classification result ──
                    for colIndex in self.columns.indices {
                        for cardIndex in self.columns[colIndex].cards.indices {
                            let cardID = self.columns[colIndex].cards[cardIndex].id
                            guard let label = newPredictions[cardID] else { continue }
                            
                            let naturalLabel = self.descriptiveText(for: label)
                            
                                // Strip any previous classification suffix like " [DataValue(6)]"
                            var baseTitle = self.columns[colIndex].cards[cardIndex].title
                            if let range = baseTitle.range(of: #" \[[^\]]+\]$"#, options: .regularExpression) {
                                baseTitle.removeSubrange(range)
                            }
                            
                                // Append the latest classification
                            self.columns[colIndex].cards[cardIndex].title = "\(baseTitle) [\(naturalLabel)]"
                        }
                    }
                }
            }
        }
    }
}
