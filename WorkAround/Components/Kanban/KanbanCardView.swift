//
//  KanbanCardView.swift
//  WorkAround
//
//  Created by Alin Florescu on 18.02.2025.
//

import SwiftUI

struct KanbanCardView: View {
    @Binding var card: KanbanCard
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Title", text: $card.title)
                .font(.headline)
                .foregroundColor(.primary)
                .textFieldStyle(PlainTextFieldStyle())
            TextField("Details", text: $card.details)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}
