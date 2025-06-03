import SwiftUI
import PencilKit
import UIKit
import FirebaseFirestore

struct KanbanCardView: View {
    @Binding var card: KanbanCard
    var classification: String? = nil
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
                    .stroke(Color.accentColor, lineWidth: 1)
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
            if let classification = classification {
                Text(classification)
                    .font(.caption)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(pastelBackgroundColor(for: classification))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(UIColor.separator), lineWidth: 1)
        )
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

private func pastelBackgroundColor(for classification: String?) -> Color {
    switch classification {
        case "High Importance":
            return Color(red: 1.0, green: 0.78, blue: 0.78) // Pastel red
        case "Medium Importance":
            return Color(red: 1.0, green: 0.92, blue: 0.78) // Pastel orange
        case "Moderate Importance":
            return Color(red: 1.0, green: 1.0, blue: 0.8)   // Pastel yellow
        case "Low Importance":
            return Color(red: 0.8, green: 1.0, blue: 0.8)   // Pastel green
        case "Very Low Importance":
            return Color(red: 0.8, green: 1.0, blue: 1.0)   // Pastel cyan
        case "Negligible Importance":
            return Color(red: 0.86, green: 0.86, blue: 1.0) // Pastel blue
        default:
            return Color(UIColor.secondarySystemBackground)
    }
}
