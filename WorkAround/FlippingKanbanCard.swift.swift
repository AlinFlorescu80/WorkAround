//
//  FlippingKanbanCard.swift.swift
//  WorkAround
//
//  Created by Alin Florescu on 17.02.2025.
//

import SwiftUI

struct FlippingKanbanCard: View {
    @State private var flipped = false

    var body: some View {
        ZStack {
            // Kanban card design with a gradient and shadow
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing)
                )
                .frame(width: 200, height: 150)
                .overlay(
                    // Display a title or logo on the card
                    Text("Kanban")
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .bold()
                )
                .rotation3DEffect(
                    // Flip the card 180° along the Y-axis
                    .degrees(flipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .onAppear {
            // Start the flipping animation when the view appears
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
            ) {
                flipped.toggle()
            }
        }
    }
}

struct FlippingKanbanCard_Previews: PreviewProvider {
    static var previews: some View {
        FlippingKanbanCard()
    }
}
