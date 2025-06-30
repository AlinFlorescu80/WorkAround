import Foundation
import FirebaseFirestore

struct KanbanCard: Identifiable, Codable {
    
    var id: String = UUID().uuidString
    
    var title: String
    var details: String
    var drawingURL: String?
    var assignees: [String] = []
    
    init(
        id: String = UUID().uuidString,
        title: String,
        details: String,
        drawingURL: String? = nil,
        assignees: [String] = []
    ) {
        self.id = id
        self.title = title
        self.details = details
        self.drawingURL = drawingURL
        self.assignees = assignees
    }
}

struct KanbanColumn: Identifiable, Codable {
    @DocumentID var firestoreId: String? = nil
    var localId: String = UUID().uuidString
    
    var title: String
    var cards: [KanbanCard]
    var order: Int
    
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
