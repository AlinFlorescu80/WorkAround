    //
    //  HomeView.swift
    //  WorkAround
    //
    //  Created by Alin Florescu on 18.02.2025.
    //

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import PhotosUI
import FirebaseStorage
import UIKit

    /// Simple model for listing boards with title, optional description, and optional photo.
private struct BoardInfo: Identifiable {
    let id: String
    let title: String
    let description: String?
    let photoURL: String?
}

struct HomeView: View {
        // MARK: – Environment
    @EnvironmentObject var authManager: AuthManager
    
        // MARK: – UI State
    @State private var searchText           = ""
    @State private var isLoading            = true
    @State private var showProfileSheet     = false
    @State private var navigateToAuth       = false
    @State var showLoadingView: Bool
    @State private var showingNewBoardSheet = false
    @State private var editingBoard: BoardInfo?
    
        // MARK: – Board Data
    @State private var boards: [BoardInfo] = []      // user’s boards with metadata
    private let db = Firestore.firestore()
    
        // MARK: – Body
    var body: some View {
        ZStack {
            dashboard
                .opacity(showLoadingView ? 0 : 1)
                .animation(.easeIn(duration: 0.5), value: showLoadingView)
            
            if showLoadingView {
                NaturalLoadingView(isLoading: $isLoading) {
                    showLoadingView = false
                }
            }
        }
        .task { await loadBoards() }      // fetch board list on appear
        .onAppear {
                // Redirect to sign‑in if not authenticated
            if !authManager.isSignedIn {
                navigateToAuth = true
                return
            }
                // Fake splash‑screen delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { isLoading = false }
            }
        }
        .onChange(of: authManager.isSignedIn) { signedIn in
                // Navigate back to sign‑in screen when signing out
            if !signedIn {
                navigateToAuth = true
            }
        }
            // Present authentication modally if not signed in
        .fullScreenCover(isPresented: $navigateToAuth) {
            AuthenticateView()
                .environmentObject(authManager)
        }
    }
    
        // MARK: – Dashboard (boards)
    private var dashboard: some View {
        NavigationStack {
            List {
                Section("My Boards") {
                    ForEach(filteredBoards) { board in
                        ZStack {
                                // Visible row content
                            HStack(alignment: .center) {
                                    // Title + optional description on the left
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(board.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    if let desc = board.description, !desc.isEmpty {
                                        Text(desc)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer(minLength: 12)
                                
                                    // Chevron icon on the right
                                Image(systemName: "chevron.right")
                                    .imageScale(.small)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color(uiColor: .secondarySystemBackground))
                            )
                            
                                // Invisible NavigationLink overlay (no chevron)
                            NavigationLink(destination: KanbanBoardView(boardID: board.id)) {
                                EmptyView()
                            }
                            .opacity(0)                // hide link label & chevron
                        }
                        .contextMenu {
                            Button {
                                editingBoard = board
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                Task { await deleteBoard(board) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Home")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                    // Leading: create board
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingNewBoardSheet = true
                    } label: {
                        Label("New Board", systemImage: "plus")
                    }
                }
                    // Trailing: auth/profile
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button { showProfileSheet = true } label: {
                        Image(systemName: "person.circle")
                            .resizable()
                            .frame(width: 40, height: 40)
                    }
                }
            }
            .searchable(text: $searchText)
            .sheet(isPresented: $showProfileSheet) { ProfileView() }
            .sheet(isPresented: $showingNewBoardSheet) {
                NewBoardSheet { title, description, image in
                    Task {
                        await createBoard(title: title, description: description, image: image)
                    }
                }
            }
            .sheet(item: $editingBoard) { board in
                EditBoardSheet(board: board) { newTitle, newDesc in
                    Task {
                        await updateBoard(boardID: board.id, title: newTitle, description: newDesc)
                    }
                }
            }
        }
    }
    
    private func deleteBoard(_ board: BoardInfo) async {
        do {
            try await db.collection("boards").document(board.id).delete()
            if let uid = Auth.auth().currentUser?.uid {
                try await db.collection("users")
                    .document(uid)
                    .collection("boards")
                    .document(board.id)
                    .delete()
            }
            DispatchQueue.main.async {
                boards.removeAll { $0.id == board.id }
            }
        } catch {
            print("Failed to delete board:", error)
        }
    }
    
    private func updateBoard(boardID: String, title: String, description: String?) async {
        do {
            var data: [String: Any] = ["title": title]
            if let desc = description { data["description"] = desc }
            try await db.collection("boards").document(boardID).updateData(data)
            if let uid = Auth.auth().currentUser?.uid {
                try await db.collection("users")
                    .document(uid)
                    .collection("boards")
                    .document(boardID)
                    .updateData([
                        "title": title,
                        "description": description ?? FieldValue.delete()
                    ])
            }
            DispatchQueue.main.async {
                if let idx = boards.firstIndex(where: { $0.id == boardID }) {
                    boards[idx] = BoardInfo(id: boardID,
                                            title: title,
                                            description: description ?? boards[idx].description,
                                            photoURL: boards[idx].photoURL)
                }
            }
        } catch {
            print("Failed to update board:", error)
        }
    }
    
        // MARK: – Board helpers
        /// Load board IDs the user owns or is invited to.
    private func loadBoards() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let userEmail = Auth.auth().currentUser?.email?.lowercased() else { return }
        do {
            var newBoards: [BoardInfo] = []
            
                // 1. Fetch owned boards (shallow list)
            let ownedSnap = try await db
                .collection("users")
                .document(uid)
                .collection("boards")
                .getDocuments()
            for doc in ownedSnap.documents {
                let data = doc.data()
                guard let title = data["title"] as? String else { continue }
                let desc = data["description"] as? String
                let photoURL = data["photoURL"] as? String
                newBoards.append(BoardInfo(id: doc.documentID,
                                           title: title,
                                           description: desc,
                                           photoURL: photoURL))
            }
            
                // 2. Fetch invited boards from root collection
            let invitedSnap = try await db
                .collection("boards")
                .whereField("invited", arrayContains: userEmail)
                .getDocuments()
            for doc in invitedSnap.documents {
                let boardID = doc.documentID
                    // avoid duplicates if user is also the owner
                guard !newBoards.contains(where: { $0.id == boardID }) else { continue }
                let data = doc.data()
                guard let title = data["title"] as? String else { continue }
                let desc = data["description"] as? String
                let photoURL = data["photoURL"] as? String
                newBoards.append(BoardInfo(id: boardID,
                                           title: title,
                                           description: desc,
                                           photoURL: photoURL))
            }
            
                // Update on main thread
            DispatchQueue.main.async {
                boards = newBoards
                registerBoardListeners(newBoards)   // 🔔 start listeners
            }
        } catch {
            print("Failed to load boards:", error)
        }
    }
    
        /// Create a new board doc, set up defaults, and navigate to it.
    private func createBoard(title: String, description: String?, image: UIImage?) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
                // 1️⃣ Create the board document
            let newRef  = db.collection("boards").document()
            let boardID = newRef.documentID
            
            var data: [String: Any] = [
                "ownerUid": uid,
                "invited": [],
                "created": FieldValue.serverTimestamp(),
                "title": title
            ]
            if let desc = description {
                data["description"] = desc
            }
            try await newRef.setData(data)
            
                // 2️⃣ Create default columns
            let columnsRef = newRef.collection("columns")
            let defaultCols: [[String: Any]] = [
                ["localId": UUID().uuidString, "title": "To Do",        "cards": [], "order": 0],
                ["localId": UUID().uuidString, "title": "In Progress",  "cards": [], "order": 1],
                ["localId": UUID().uuidString, "title": "Done",         "cards": [], "order": 2]
            ]
            for colData in defaultCols {
                let colDoc = columnsRef.document()
                try await colDoc.setData(colData)
            }
            
                // 3️⃣ Upload photo if provided
            if let image {
                let storageRef = Storage.storage().reference()
                    .child("boards/\(boardID)/photo.jpg")
                if let jpeg = image.jpegData(compressionQuality: 0.8) {
                    try await storageRef.putDataAsync(jpeg, metadata: nil)
                    let url = try await storageRef.downloadURL()
                    try await newRef.updateData(["photoURL": url.absoluteString])
                }
            }
            
                // 4️⃣ Reference under the user
            var userBoardData: [String: Any] = [
                "created": FieldValue.serverTimestamp(),
                "title": title
            ]
            if let description {
                userBoardData["description"] = description
            }
            try await db
                .collection("users")
                .document(uid)
                .collection("boards")
                .document(boardID)
                .setData(userBoardData)
            
                // 5️⃣ Update local list and navigate
            boards.append(BoardInfo(id: boardID,
                                    title: title,
                                    description: description,
                                    photoURL: nil))
            registerBoardListeners([BoardInfo(id: boardID,
                                              title: title,
                                              description: description,
                                              photoURL: nil)])
                // Immediate navigation is handled by the direct NavigationLink
        } catch {
            print("Failed to create board:", error)
        }
    }
    
        /// Start background chat listeners for every board in `infos`.
    private func registerBoardListeners(_ infos: [BoardInfo]) {
        infos.forEach { ChatNotificationService.shared.startListening(for: $0.id) }
    }
    
    private var filteredBoards: [BoardInfo] {
        searchText.isEmpty
        ? boards
        : boards.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
}

private struct NewBoardSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var imageData: Data?
    
    var onCreate: (String, String?, UIImage?) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Title *") {
                    TextField("Enter board title", text: $title)
                }
                Section("Description") {
                    TextField("Enter description (optional)", text: $description)
                }
//                Section("Photo") {
//                    PhotosPicker(selection: $photoItem,
//                                 matching: .images,
//                                 photoLibrary: .shared()) {
//                        HStack {
//                            Label("Choose Photo", systemImage: "photo")
//                            Spacer()
//                            if let data = imageData,
//                               let uiImage = UIImage(data: data) {
//                                Image(uiImage: uiImage)
//                                    .resizable()
//                                    .scaledToFit()
//                                    .frame(width: 60, height: 60)
//                                    .clipShape(RoundedRectangle(cornerRadius: 4))
//                            }
//                        }
//                    }
//                                 .onChange(of: photoItem) { item in
//                                     Task {
//                                         if let data = try? await item?.loadTransferable(type: Data.self) {
//                                             imageData = data
//                                         }
//                                     }
//                                 }
//                }
            }
            .navigationTitle("New Board")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let img = imageData.flatMap { UIImage(data: $0) }
                        onCreate(
                            title.trimmingCharacters(in: .whitespaces),
                            description.isEmpty ? nil : description,
                            img
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
    //
    //    #Preview {
    //        HomeView(showLoadingView: true)
    //            .environmentObject(AuthManager())
    //    }
    // REMINDER: AM SI ANIMATIE CA LA TWITTER AICI!!!!

private struct EditBoardSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var board: BoardInfo
    @State private var title: String
    @State private var description: String
    var onSave: (String, String?) -> Void
    
    init(board: BoardInfo, onSave: @escaping (String, String?) -> Void) {
        self.board = board
        _title = State(initialValue: board.title)
        _description = State(initialValue: board.description ?? "")
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Title *") {
                    TextField("Enter board title", text: $title)
                }
                Section("Description") {
                    TextField("Enter description (optional)", text: $description)
                }
            }
            .navigationTitle("Edit Board")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(title.trimmingCharacters(in: .whitespaces),
                               description.isEmpty ? nil : description)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
