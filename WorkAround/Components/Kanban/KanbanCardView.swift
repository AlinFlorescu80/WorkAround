import SwiftUI
import PencilKit
import UIKit
import FirebaseFirestore

struct KanbanCardView: View {
    @Binding var card: KanbanCard
    @State private var showingDrawing = false
    @State private var canvas = PKCanvasView()
    
    private let db = Firestore.firestore()
    
        /// Loads an existing drawing from disk into the canvas when editing.
    private func loadDrawing() {
        guard let path = card.drawingURL,
              let url = URL(string: path)
        else { return }
        if let data = try? Data(contentsOf: url),
           let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
        }
    }
    
        /// Extracts the drawing, saves it as vector data in Documents, and closes the sheet.
    private func saveDrawing() {
        let drawing = canvas.drawing
        let data = drawing.dataRepresentation()
            // Build a file URL in the app’s Documents directory
        let filename = "\(card.id).drawing"
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documents.appendingPathComponent(filename)
        do {
            try data.write(to: fileURL, options: .atomic)
            DispatchQueue.main.async {
                card.drawingURL = fileURL.absoluteString
                showingDrawing = false
            }
        } catch {
            print("🔴 File save error: \(error.localizedDescription)")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Title", text: $card.title)
                .font(.headline)
                .textFieldStyle(PlainTextFieldStyle())
            
            TextField("Details", text: $card.details)
                .font(.subheadline)
                .textFieldStyle(PlainTextFieldStyle())
            
            Button("Draw") {
                showingDrawing = true
            }
            .padding(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue, lineWidth: 1)
            )
            .sheet(isPresented: $showingDrawing) {
                NavigationView {
                    DrawingCanvas(canvas: $canvas)
                        .navigationBarTitle("Drawing", displayMode: .inline)
                        .navigationBarItems(
                            leading: Button("Cancel") {
                                showingDrawing = false
                            },
                            trailing: Button("Save") {
                                saveDrawing()
                            }
                        )
                }
                .onAppear {
                    loadDrawing()
                }
            }
            
                // If a drawing URL exists, render and display the canvas drawing
            if let path = card.drawingURL,
               let url = URL(string: path),
               let data = try? Data(contentsOf: url),
               let drawing = try? PKDrawing(data: data) {
                let bounds = drawing.bounds
                let uiImage = drawing.image(from: bounds, scale: UIScreen.main.scale)
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .contextMenu {
                        Button(role: .destructive) {
                                // Delete the drawing file from disk
                            if let fileURL = URL(string: path) {
                                try? FileManager.default.removeItem(at: fileURL)
                            }
                                // Clear the canvas drawing so it doesn’t reappear
                            canvas.drawing = PKDrawing()
                                // Remove the reference so the view updates
                            card.drawingURL = nil
                        } label: {
                            Label("Delete Drawing", systemImage: "trash")
                        }
                    }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}

    /// UIViewRepresentable wrapper for PencilKit
struct DrawingCanvas: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
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
        toolPicker.setVisible(true, forFirstResponder: uiView)
        toolPicker.addObserver(uiView)
    }
}
