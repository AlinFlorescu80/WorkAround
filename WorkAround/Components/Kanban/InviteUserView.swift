

import SwiftUI
import Firebase
import FirebaseFirestore

struct InviteUserView: View {
    @Environment(\.dismiss) private var dismiss
    let boardID: String                 // passed in from KanbanBoardView
    
    @State private var email = ""
    @State private var status: String?
    @State private var sending = false
    
    private var isEmailValid: Bool {
            // quick & simple check
        email.contains("@") && email.contains(".")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("User e‑mail") {
                    TextField("email@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                if let msg = status {
                    Section {
                        Text(msg)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Invite user")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") { invite() }
                        .disabled(!isEmailValid || sending)
                }
            }
        }
    }
    
    private func invite() {
        sending = true
        let db = Firestore.firestore()
        db.collection("boards").document(boardID)
            .updateData([ "invited": FieldValue.arrayUnion([email.lowercased()]) ]) { error in
                sending = false
                if let error {
                    status = "Error: \(error.localizedDescription)"
                } else {
                    status = "Invitation sent!"
                    email  = ""
                }
            }
    }
}
#Preview {
    InviteUserView(boardID: "TEST")
}
