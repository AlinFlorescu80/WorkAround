import Foundation
import FirebaseFirestore

struct KanbanCard: Identifiable, Codable {
    @DocumentID var id: String? = nil
    var title: String
    var details: String
}

struct KanbanColumn: Identifiable, Codable {
    @DocumentID var id: String? = nil
    var title: String
    var cards: [KanbanCard]
}
