    //
    //  KanbanCardView.swift
    //  WorkAround
    //
    //  Created by Alin Florescu on 18.02.2025.
    //

import SwiftUI
import PencilKit

struct KanbanCardView: View {
    @Binding var card: KanbanCard
    @State private var showingDrawing = false
    @State private var canvas = PKCanvasView()
    
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
            
            Button(action: {
                showingDrawing = true
            }) {
                Text("Draw")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: 1)
                    )
            }
            .sheet(isPresented: $showingDrawing) {
                DrawingCanvas(canvas: $canvas)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

struct DrawingCanvas: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    
        /// Keep a strong reference so the palette isn’t de‑allocated
    private let toolPicker = PKToolPicker()
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvas.backgroundColor = .systemBackground
        canvas.drawingPolicy = .anyInput
        
        toolPicker.setVisible(true, forFirstResponder: canvas)
        toolPicker.addObserver(canvas)
        canvas.becomeFirstResponder()
        
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
            // Keep the palette visible across state updates
        toolPicker.setVisible(true, forFirstResponder: uiView)
        toolPicker.addObserver(uiView)
    }
}
