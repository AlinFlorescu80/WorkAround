//
//  ChatViewModel.swift
//  WorkAround
//
//  Created by Alin Florescu on 21.04.2025.
//
import Foundation
import FirebaseFirestore

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var newMessage = ""
    
    private var db = Firestore.firestore()
    private var boardID: String
    private var listener: ListenerRegistration?
    
    init(boardID: String) {
        self.boardID = boardID
        listenForMessages()
    }
    
    func listenForMessages() {
        listener = db.collection("boards")
            .document(boardID)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                self.messages = documents.compactMap {
                    try? $0.data(as: ChatMessage.self)
                }
            }
    }
    
    func sendMessage(sender: String) {
        let message = ChatMessage(sender: sender, text: newMessage, timestamp: Date())
        
        do {
            try db.collection("boards")
                .document(boardID)
                .collection("messages")
                .addDocument(from: message) // 🔥 use addDocument instead of .document(id)
            newMessage = ""
        } catch {
            print("Error sending message: \(error)")
        }
    }
    
    deinit {
        listener?.remove()
    }
}
