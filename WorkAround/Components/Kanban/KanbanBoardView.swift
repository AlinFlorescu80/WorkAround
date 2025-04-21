import SwiftUI

struct KanbanBoardView: View {
    @StateObject private var viewModel: KanbanBoardViewModel
    @State private var showingInviteSheet = false
    
    init(boardID: String) {
        _viewModel = StateObject(wrappedValue: KanbanBoardViewModel(boardID: boardID))
    }
    
    var body: some View {
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
                                ForEach(column.cards.indices, id: \.self) { idx in
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
                
                    // Invite Users button
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
            }
            .padding()
        }
        .sheet(isPresented: $showingInviteSheet) {
            InviteUserView(boardID: viewModel.boardID)
        }
        .onDisappear {
            for col in viewModel.columns {
                viewModel.saveColumn(col)
            }
        }
    }
}
//#if DEBUG
//struct KanbanBoardView_Previews: PreviewProvider {
//    static var previews: some View {
//        KanbanBoardView(boardID: "preview")
//    }
//}
//#endif
