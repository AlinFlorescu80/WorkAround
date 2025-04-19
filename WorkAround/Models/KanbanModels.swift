import Foundation
import FirebaseFirestore

struct KanbanCard: Identifiable, Codable {
        /// Firestore document ID (populated after syncing).
    @DocumentID var firestoreId: String? = nil
    
        /// Locally‑generated UUID so every card is unique before it’s saved.
    var localId: String = UUID().uuidString
    var title: String
    var details: String
    
    
        /// SwiftUI uses this as the stable identifier.
    var id: String { firestoreId ?? localId }
}

struct KanbanColumn: Identifiable, Codable {
        /// Firestore document ID (populated after syncing).
    @DocumentID var firestoreId: String? = nil
    
        /// Locally‑generated UUID so every column is unique before it’s saved.
    var localId: String = UUID().uuidString

    var title: String
    var cards: [KanbanCard]
    
        /// SwiftUI uses this as the stable identifier.
    var id: String { firestoreId ?? localId }
}
