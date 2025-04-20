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

    /// Simple model for listing boards with title and optional photo.
private struct BoardInfo: Identifiable {
    let id: String
    let title: String
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
                // Fake splash‑screen delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { isLoading = false }
            }
        }
    }
    
        // MARK: – Dashboard (boards)
    private var dashboard: some View {
        NavigationStack {
            List {
                    // Boards section
                Section("My Boards") {
                    ForEach(filteredBoards) { board in
                        NavigationLink(destination: KanbanBoardView(boardID: board.id)) {
                            Text(board.title)
                        }
                    }
                }
            }
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
                    if !authManager.isSignedIn {
                        Button("Sign In") { navigateToAuth = true }
                    }
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
                // Hidden link for programmatic sign-in navigation
            NavigationLink(
                destination: AuthenticateView().environmentObject(authManager),
                isActive: $navigateToAuth
            ) { EmptyView() }
                .hidden()
        }
    }
    
        // MARK: – Board helpers
        /// Load board IDs the user owns or is invited to.
    private func loadBoards() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let snap = try await db
                .collection("users")
                .document(uid)
                .collection("boards")
                .getDocuments()
            boards = snap.documents.compactMap { doc in
                let data = doc.data()
                guard let title = data["title"] as? String else { return nil }
                let photoURL = data["photoURL"] as? String
                return BoardInfo(id: doc.documentID, title: title, photoURL: photoURL)
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
                ["localId": UUID().uuidString, "title": "To Do",       "cards": [], "order": 0],
                ["localId": UUID().uuidString, "title": "In Progress","cards": [], "order": 1],
                ["localId": UUID().uuidString, "title": "Done",        "cards": [], "order": 2]
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
            if let imageURL = image {
                    // store photo URL if you saved one
                    // userBoardData["photoURL"] = ...
            }
            try await db
                .collection("users")
                .document(uid)
                .collection("boards")
                .document(boardID)
                .setData(userBoardData)
            
                // 5️⃣ Update local list and navigate
            boards.append(BoardInfo(id: boardID, title: title, photoURL: nil))
                // Immediate navigation is handled by the direct NavigationLink
        } catch {
            print("Failed to create board:", error)
        }
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
                Section("Photo") {
                    PhotosPicker(selection: $photoItem,
                                 matching: .images,
                                 photoLibrary: .shared()) {
                        HStack {
                            Label("Choose Photo", systemImage: "photo")
                            Spacer()
                            if let data = imageData,
                               let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                                 .onChange(of: photoItem) { item in
                                     Task {
                                         if let data = try? await item?.loadTransferable(type: Data.self) {
                                             imageData = data
                                         }
                                     }
                                 }
                }
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

#Preview {
    HomeView(showLoadingView: true)
        .environmentObject(AuthManager())
}
