import Foundation
import SwiftUI
import FirebaseFirestore

    /// View‑model that handles chat logic *and* local notification scheduling.
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var newMessage: String = ""
    
    private let db = Firestore.firestore()
    private let boardID: String
    private var listener: ListenerRegistration?
    
    init(boardID: String) {
        self.boardID = boardID
        listenForMessages()
    }
    
        // Notification logic removed; now handled by ChatNotificationService.
    
        // MARK: ‑ Firestore
    
    private func listenForMessages() {
        listener = db.collection("boards")
            .document(boardID)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error fetching messages: \(error)")
                    return
                }
                
                guard let docs = snapshot?.documents else { return }
                self.messages = docs.compactMap { try? $0.data(as: ChatMessage.self) }
            }
    }
    
    func sendMessage(sender: String) {
        let message = ChatMessage(sender: sender, text: newMessage, timestamp: Date())
        do {
            _ = try db.collection("boards")
                .document(boardID)
                .collection("messages")
                .addDocument(from: message)
            newMessage = ""
        } catch {
            print("Error sending message: \(error)")
        }
    }
    
    deinit {
        listener?.remove()
    }
}
