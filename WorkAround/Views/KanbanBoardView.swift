import SwiftUI
import FirebaseAuth

struct KanbanBoardView: View {
    @StateObject private var viewModel: KanbanBoardViewModel
    @State private var showingInviteSheet = false
    @State private var showingChat = false
    let userEmail = Auth.auth().currentUser?.email
    
    init(boardID: String) {
        _viewModel = StateObject(wrappedValue: KanbanBoardViewModel(boardID: boardID))
    }
    
    var body: some View {
        VStack(alignment: .trailing) {
            HStack {
                Spacer()
                Button {
                    showingInviteSheet = true
                } label: {
                    Label("Invite", systemImage: "person.crop.circle.badge.plus")
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(Color.accentColor)
                        .cornerRadius(8)
                }
                Button {
                    showingChat = true
                } label: {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(Color.accentColor)
                        .cornerRadius(8)
                }
                Button {
                    viewModel.classifyAllTasks()
                } label: {
                    Label("Classify with AI", systemImage: "star.fill")
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(Color.accentColor)
                        .cornerRadius(8)
                        .lineLimit(1)
                }
                .padding(.trailing, 12)
                .accessibilityLabel("Run AI task classifier")
            }
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
                                    ForEach($column.cards, id: \.id) { $card in
                                        KanbanCardView(
                                            card: $card,
                                            classification: viewModel.predictions[card.id].flatMap { viewModel.descriptiveText(for: $0) }
                                        )
                                        .onDrag {
                                            let cardID = card.id.data(using: .utf8)
                                            return NSItemProvider(item: cardID as NSData?, typeIdentifier: "public.text")
                                        }
                                        .contextMenu {
                                            Menu("Add assignee") {
                                                ForEach(viewModel.invitedUsers.filter { !card.assignees.contains($0) }, id: \.self) { user in
                                                    Button(user) {
                                                        viewModel.addAssignee(user, toCardID: card.id)
                                                    }
                                                }
                                            }
                                                // Only show remove menu when there are assignees
                                            if !card.assignees.isEmpty {
                                                Menu("Remove assignee") {
                                                    ForEach(card.assignees, id: \.self) { user in
                                                        Button(user) {
                                                            viewModel.removeAssignee(user, fromCardID: card.id)
                                                        }
                                                    }
                                                }
                                            }
                                            Divider()
                                            Button(role: .destructive) {
                                                if let idx = column.cards.firstIndex(where: { $0.id == card.id }) {
                                                    column.cards.remove(at: idx)
                                                }
                                            } label: {
                                                Label("Delete Card", systemImage: "trash")
                                            }
                                        }
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
                        .contextMenu {
                            Button(role: .destructive) {
                                if let index = viewModel.columns.firstIndex(where: { $0.id == column.id }) {
                                    let columnToDelete = viewModel.columns[index]
                                    viewModel.deleteColumn(columnToDelete)
                                    viewModel.columns.remove(at: index)
                                }
                            } label: {
                                Label("Delete Column", systemImage: "trash")
                            }
                        }
                    }
                        //  Add‑column button
                    Button(action: {
                        let nextOrder = (viewModel.columns.map(\.order).max() ?? -1) + 1
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
                }
                .padding()
            }
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
        .navigationTitle(viewModel.boardTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
