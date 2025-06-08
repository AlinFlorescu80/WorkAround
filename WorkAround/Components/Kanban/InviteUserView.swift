import SwiftUI
import Firebase
import FirebaseFirestore

struct InviteUserView: View {
    @Environment(\.dismiss) private var dismiss
    let boardID: String                 // passed in from KanbanBoardView
    
    @State private var email = ""
    @State private var status: String?
    @State private var sending = false
    @State private var invitedUsers: [String] = []
    
    private var isEmailValid: Bool {
            // quick & simple check
        email.contains("@") && email.contains(".")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("User e‑mail") {
                    TextField("", text: $email)
                        .placeholder(when: email.isEmpty) {
                            Text("Enter email to invite")
                                .foregroundColor(.secondary)
                        }
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                Section("Invited Users") {
                    if invitedUsers.isEmpty {
                        Text("No users invited yet.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(invitedUsers, id: \.self) { user in
                            Text(user)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        removeInvite(user)
                                    } label: {
                                        Label("Remove Invitation", systemImage: "trash")
                                    }
                                }
                        }
                    }
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
            .onAppear {
                fetchInvitedUsers()
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
    
    private func removeInvite(_ email: String) {
        sending = true
        let db = Firestore.firestore()
        db.collection("boards").document(boardID)
            .updateData([
                "invited": FieldValue.arrayRemove([email.lowercased()])
            ]) { error in
                sending = false
                if let error = error {
                    status = "Error removing invitation: \(error.localizedDescription)"
                } else {
                    status = "Invitation removed."
                }
            }
    }
    
        /// Fetches the list of invited users from Firestore
    private func fetchInvitedUsers() {
        let db = Firestore.firestore()
        db.collection("boards").document(boardID)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data(),
                      let invited = data["invited"] as? [String] else {
                    DispatchQueue.main.async { invitedUsers = [] }
                    return
                }
                DispatchQueue.main.async { invitedUsers = invited }
            }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    InviteUserView(boardID: "TEST")
}
