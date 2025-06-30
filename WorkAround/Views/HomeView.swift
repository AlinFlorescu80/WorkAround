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

struct SplashView: View {
    var namespace: Namespace.ID
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    var body: some View {
        Image("WorkAroundIcon")
            .resizable()
            .matchedGeometryEffect(id: "logo", in: namespace)
            .scaledToFit()
            .frame(width: 120, height: 120)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.6).repeatCount(4, autoreverses: true)) {
                    scale = 1.2
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        scale = 25.0
                        opacity = 0.0
                    }
                }
            }
    }
}

private struct BoardInfo: Identifiable {
    let id: String
    let title: String
    let description: String?
    let photoURL: String?
}

struct HomeView: View {
    let logoNamespace: Namespace.ID
    @EnvironmentObject var authManager: AuthManager
    
    @State private var searchText           = ""
    @State private var isLoading            = true
    @State private var showProfileSheet     = false
    @State var showLoadingView: Bool
    @State private var showingNewBoardSheet = false
    @State private var editingBoard: BoardInfo?
    
    @State private var showSplash: Bool = true
    
    @State private var boards: [BoardInfo] = []
    private let db = Firestore.firestore()
    
    var body: some View {
        ZStack {
            dashboard
                .opacity(showSplash ? 0 : 1)
                .animation(.easeInOut, value: showSplash)
            
            if showSplash {
                SplashView(namespace: logoNamespace)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.9) {
                withAnimation(.easeInOut) {
                    showSplash = false
                }
            }
        }
        .task { await loadBoards() }
        .onAppear {
               
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { isLoading = false }
            }
        }
            
    }
    
    private var dashboard: some View {
        NavigationStack {
            List {
                Section("My Boards") {
                    ForEach(filteredBoards) { board in
                        ZStack {
                            HStack(alignment: .center) {
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
                            
                            NavigationLink(destination: KanbanBoardView(boardID: board.id)) {
                                EmptyView()
                            }
                            .opacity(0)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingNewBoardSheet = true
                    } label: {
                        Label("New Board", systemImage: "plus")
                    }
                }
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
    
    private func loadBoards() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let userEmail = Auth.auth().currentUser?.email?.lowercased() else { return }
        do {
            var newBoards: [BoardInfo] = []
            
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
            
            let invitedSnap = try await db
                .collection("boards")
                .whereField("invited", arrayContains: userEmail)
                .getDocuments()
            for doc in invitedSnap.documents {
                let boardID = doc.documentID
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
            
            DispatchQueue.main.async {
                boards = newBoards
                registerBoardListeners(newBoards)
            }
        } catch {
            print("Failed to load boards:", error)
        }
    }
    
    private func createBoard(title: String, description: String?, image: UIImage?) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
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
            
            if let image {
                let storageRef = Storage.storage().reference()
                    .child("boards/\(boardID)/photo.jpg")
                if let jpeg = image.jpegData(compressionQuality: 0.8) {
                    try await storageRef.putDataAsync(jpeg, metadata: nil)
                    let url = try await storageRef.downloadURL()
                    try await newRef.updateData(["photoURL": url.absoluteString])
                }
            }
            
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
            
            boards.append(BoardInfo(id: boardID,
                                    title: title,
                                    description: description,
                                    photoURL: nil))
            registerBoardListeners([BoardInfo(id: boardID,
                                              title: title,
                                              description: description,
                                              photoURL: nil)])
        } catch {
            print("Failed to create board:", error)
        }
    }
    
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
