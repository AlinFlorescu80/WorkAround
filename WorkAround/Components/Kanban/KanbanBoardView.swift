    //
    //  KanbanBoardView.swift
    //  WorkAround
    //
    //  Created by Alin Florescu on 18.02.2025.
    //

import SwiftUI

struct KanbanBoardView: View {
    @StateObject private var viewModel = KanbanBoardViewModel()
    
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
                                        //                                        .onDrag {
                                        //                                            NSItemProvider(object: card.id.uuidString as NSString)
                                        //                                        }
                                        //                                        .onDrop(of: [.text], delegate: CardDropDelegate(targetCard: card, targetColumn: $column, allColumns: $viewModel.columns))
                                        //                                        .onChange(of: card) { _ in
                                        //                                            viewModel.saveColumn(column)
                                        //                                        }
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
                                viewModel.saveColumn(column)
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
                    let newColumn = KanbanColumn(title: "New Column", cards: [])
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
}
#if DEBUG
struct KanbanBoardView_Previews: PreviewProvider {
    static var previews: some View {
        KanbanBoardView()
    }
}
#endif
