//
//  KanbanBoardView.swift
//  WorkAround
//
//  Created by Alin Florescu on 18.02.2025.
//

import SwiftUI

struct KanbanBoardView: View {
    @State private var columns: [KanbanColumn] = [
        KanbanColumn(title: "To Do", cards: [
            KanbanCard(title: "Task 1", details: "Define requirements"),
            KanbanCard(title: "Task 2", details: "Set up project")
        ]),
        KanbanColumn(title: "In Progress", cards: [
            KanbanCard(title: "Task 3", details: "Design UI")
        ]),
        KanbanColumn(title: "Done", cards: [])
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                ForEach($columns) { $column in
                    VStack(spacing: 8) {
                        TextField("Column Title", text: $column.title)
                            .font(.headline)
                            .padding(.vertical, 8)
                            .multilineTextAlignment(.center)
                        
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach($column.cards) { $card in
                                    KanbanCardView(card: $card)
                                        .onDrag {
                                            NSItemProvider(object: card.id.uuidString as NSString)
                                        }
                                        .onDrop(of: [.text], delegate: CardDropDelegate(targetCard: card, targetColumn: $column, allColumns: $columns))
                                }
                            }
                            .padding()
                        }
                        .frame(minWidth: 250, maxHeight: .infinity)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .onDrop(of: [.text], delegate: ColumnDropDelegate(targetColumn: $column, allColumns: $columns))
                        
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
                    withAnimation {
                        columns.append(KanbanColumn(title: "New Column", cards: []))
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
