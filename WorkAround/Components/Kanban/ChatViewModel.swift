import Foundation
import SwiftUI
import FirebaseFirestore
import UserNotifications

    /// View‑model that handles chat logic *and* local notification scheduling.
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var newMessage: String = ""
    
    private let db = Firestore.firestore()
    private let boardID: String
    private var listener: ListenerRegistration?
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init(boardID: String) {
        self.boardID = boardID
        listenForMessages()
        requestNotificationAuthorization()
    }
    
        // MARK: ‑ Notifications
    
    private func requestNotificationAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permission granted: \(granted)")
            }
        }
    }
    
    private func scheduleLocalNotification(for message: ChatMessage) {
        let content = UNMutableNotificationContent()
        content.title = message.sender
        content.body  = message.text
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // deliver immediately
        )
        notificationCenter.add(request, withCompletionHandler: nil)
    }
    
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
                
                snapshot?.documentChanges.forEach { change in
                    if change.type == .added,
                       let newChatMessage = try? change.document.data(as: ChatMessage.self) {
                        self.scheduleLocalNotification(for: newChatMessage)
                    }
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
