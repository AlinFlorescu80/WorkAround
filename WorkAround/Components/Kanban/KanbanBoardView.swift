    // =============================================================
    //  KanbanBoardView.swift — updated for AI task classification
    // =============================================================

import SwiftUI
import FirebaseAuth

struct KanbanBoardView: View {
    @StateObject private var viewModel: KanbanBoardViewModel
    @State private var showingInviteSheet = false
    @State private var showingChat = false
    
    init(boardID: String) {
        _viewModel = StateObject(wrappedValue: KanbanBoardViewModel(boardID: boardID))
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
                // ────────────────────────────────────────────────────────────
                //  Original board content
                // ────────────────────────────────────────────────────────────
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    ForEach($viewModel.columns) { $column in
                        VStack(spacing: 8) {
                            TextField("Column Title", text: $column.title)
                                .font(.headline)
                                .padding(.vertical, 8)
                                .multilineTextAlignment(.center)
                            
                            ScrollView {
                                VStack(spacing: 8) {
                                    ForEach(column.cards.indices, id: \ .self) { idx in
                                        KanbanCardView(card: $column.cards[idx])
                                    }
                                }
                                .padding()
                            }
                            .frame(minWidth: 250, maxHeight: .infinity)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .onDrop(of: [.text], delegate: ColumnDropDelegate(targetColumn: $column, allColumns: $viewModel.columns))
                            
                            Button(action: {
                                let newCard = KanbanCard(title: "New Task", details: "Task details")
                                withAnimation {
                                    column.cards.append(newCard)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Add Card")
                                }
                                .padding(8)
                            }
                        }
                        .frame(width: 250)
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    }
                    
                        //  Add‑column button
                    Button(action: {
                        let nextOrder = (viewModel.columns.map(\ .order).max() ?? -1) + 1
                        let newColumn = KanbanColumn(title: "New Column", cards: [], order: nextOrder)
                        withAnimation {
                            viewModel.columns.append(newColumn)
                        }
                    }) {
                        VStack {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                            Text("Add Column")
                                .font(.headline)
                        }
                        .frame(width: 250, height: 400)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    }
                    
                        //  Invite Users button
                    Button {
                        showingInviteSheet = true
                    } label: {
                        VStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .resizable()
                                .frame(width: 50, height: 50)
                            Text("Invite")
                                .font(.headline)
                        }
                        .frame(width: 250, height: 400)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    }
                    
                        //  Chat button
                    Button {
                        showingChat = true
                    } label: {
                        VStack {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                            Text("Chat")
                                .font(.headline)
                        }
                        .frame(width: 250, height: 400)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                    }
                }
                .padding()
            }
                // ────────────────────────────────────────────────────────────
                //  ⭐️ AI‑classify button (top‑right overlay)
                // ────────────────────────────────────────────────────────────
            Button {
                viewModel.classifyAllTasks()
            } label: {
                Image(systemName: "star.fill")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .padding(18)
                    .background(
                        Circle()
                            .fill(Color.accentColor)
                    )
                    .shadow(radius: 4)
            }
            .padding()
            .accessibilityLabel("Run AI task classifier")
        }
            //  Sheets & life‑cycle hooks remain unchanged
        .sheet(isPresented: $showingInviteSheet) {
            InviteUserView(boardID: viewModel.boardID)
        }
        .sheet(isPresented: $showingChat) {
            if let email = Auth.auth().currentUser?.email {
                ChatView(viewModel: ChatViewModel(boardID: viewModel.boardID), senderEmail: email)
            }
        }
        .onDisappear {
            for col in viewModel.columns {
                viewModel.saveColumn(col)
            }
        }
    }
}
