    //
    //  HomeView.swift
    //  WorkAround
    //
    //  Created by Alin Florescu on 18.02.2025.
    //

import SwiftUI
import SwiftData
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct HomeView: View {
        // MARK: – Environment
    @EnvironmentObject var authManager: AuthManager
    
        // MARK: – UI State
    @State private var searchText        = ""
    @State private var isLoading         = true
    @State private var showProfileSheet  = false
    @State private var navigateToAuth    = false
    @State var showLoadingView: Bool
    
        // MARK: – Board Data
    @State private var boards: [String] = []          // boardIDs owned/invited
    @State private var navBoardID: String? = nil      // triggers navigation
    private let db = Firestore.firestore()
    
        // MARK: – Demo Items (unchanged)
    private let allItems: [Item] = [
        Item(timestamp: Date(),                      title: "Plan Project",        details: "Outline all tasks for the WorkAround app."),
        Item(timestamp: Date().addingTimeInterval(-1*86400),  title: "Design UI",          details: "Sketch the Kanban interface."),
        Item(timestamp: Date().addingTimeInterval(-2*86400),  title: "Implement Features", details: "Code the drag‑and‑drop feature."),
        Item(timestamp: Date().addingTimeInterval(-3*86400),  title: "Test App",           details: "Perform thorough testing."),
        Item(timestamp: Date().addingTimeInterval(-4*86400),  title: "Deploy App",         details: "Deploy the app to production."),
        Item(timestamp: Date().addingTimeInterval(-5*86400),  title: "Collect Feedback",   details: "Gather user feedback for improvements.")
    ]
    
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
    
        // MARK: – Dashboard (boards + recent items)
    private var dashboard: some View {
        NavigationStack {
            List {
                    // Boards section
                Section("My Boards") {
                    ForEach(boards, id: \.self) { id in
                        NavigationLink(value: id) {
                            Text("Board \(id.prefix(6))")
                        }
                    }
                }
                
                    // Your existing demo items
                Section("Recent Items") {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.timestamp) { idx, item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            ItemCardView(item: item, index: idx)
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
                        Task { await createBoard() }
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
            .searchable(text: $searchText) {
                ForEach(searchSuggestions, id: \.self) { Text($0).searchCompletion($0) }
            }
            .sheet(isPresented: $showProfileSheet) { ProfileView() }
                // board navigation
            .navigationDestination(for: String.self) { id in
                KanbanBoardView(
                    viewModel: KanbanBoardViewModel(boardID: id)
                )
            }
                // hidden link for sign‑in
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
            let snap = try await db.collection("users")
                .document(uid)
                .collection("boards")
                .getDocuments()
            boards = snap.documents.map { $0.documentID }
        } catch {
            print("Failed to load boards: \(error)")
        }
    }
    
        /// Create a new board doc, save reference under user, then navigate to it.
    private func createBoard() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let newRef  = db.collection("boards").document()
            let boardID = newRef.documentID
            
                // root board document
            try await newRef.setData([
                "ownerUid": uid,
                "invited": [],
                "created": FieldValue.serverTimestamp()
            ])
            
                // reference under the user
            try await db.collection("users")
                .document(uid)
                .collection("boards")
                .document(boardID)
                .setData(["created": FieldValue.serverTimestamp()])
            
            boards.append(boardID)
            navBoardID = boardID     // triggers NavigationDestination
        } catch {
            print("Failed to create board: \(error)")
        }
    }
    
        // MARK: – Search helpers
    private var filteredItems: [Item] {
        searchText.isEmpty
        ? allItems
        : allItems.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    private var searchSuggestions: [String] {
        allItems.map { $0.title }
            .filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
}

#Preview {
    HomeView(showLoadingView: true)
        .environmentObject(AuthManager())
}
