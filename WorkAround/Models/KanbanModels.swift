import Foundation
import FirebaseFirestore

    /// Model representing a single kanban card, including an optional PencilKit drawing URL
struct KanbanCard: Identifiable, Codable {
        /// Firestore document ID (populated after syncing).
    @DocumentID var firestoreId: String? = nil
    
        /// Locally-generated UUID so every card is unique before it’s saved.
    var localId: String = UUID().uuidString
    
    var title: String
    var details: String
    
        /// URL of the saved PencilKit drawing
    var drawingURL: String?
    
        /// Users assigned to this card
    var assignees: [String] = []
    
        /// SwiftUI uses this as the stable identifier.
    var id: String { firestoreId ?? localId }
    
    init(
        firestoreId: String? = nil,
        localId: String = UUID().uuidString,
        title: String,
        details: String,
        drawingURL: String? = nil,
        assignees: [String] = []
    ) {
        self.firestoreId = firestoreId
        self.localId = localId
        self.title = title
        self.details = details
        self.drawingURL = drawingURL
        self.assignees = assignees
    }
}

    /// Represents a column in the Kanban board, holding multiple cards
struct KanbanColumn: Identifiable, Codable {
        /// Firestore document ID (populated after syncing).
    @DocumentID var firestoreId: String? = nil
    
        /// Locally-generated UUID so every column is unique before it’s saved.
    var localId: String = UUID().uuidString
    
    var title: String
    var cards: [KanbanCard]
    
        /// Position of the column in the board (lower = further left).
    var order: Int
    
        /// SwiftUI uses this as the stable identifier.
    var id: String { firestoreId ?? localId }
    
    init(
        firestoreId: String? = nil,
        localId: String = UUID().uuidString,
        title: String,
        cards: [KanbanCard],
        order: Int
    ) {
        self.firestoreId = firestoreId
        self.localId = localId
        self.title = title
        self.cards = cards
        self.order = order
    }
}
