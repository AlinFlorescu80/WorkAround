import SwiftUI
import SwiftData

struct ContentView: View {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    // Hardcoded dummy items
    private let allItems: [Item] = [
        Item(timestamp: Date(), title: "Plan Project", details: "Outline all tasks for the WorkAround app."),
        Item(timestamp: Date().addingTimeInterval(-86400), title: "Design UI", details: "Sketch the Kanban interface."),
        Item(timestamp: Date().addingTimeInterval(-172800), title: "Implement Features", details: "Code the drag-and-drop feature.")
    ]
    
    // State to manage search text
    @State private var searchText = ""
    
    var body: some View {
        TabView {
            homeTab()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            privateTab()
                .tabItem {
                    Label("Private", systemImage: "lock")
                }
            
            publicTab()
                .tabItem {
                    Label("Public", systemImage: "globe")
                }
            
            optionsTab()
                .tabItem {
                    Label("Options", systemImage: "gearshape")
                }
        }
    }

    private func homeTab() -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Filter items based on search text
                    ForEach(filteredItems, id: \.timestamp) { item in
                        HStack(spacing: 16) {
                            // Picture frame on the left side
                            Image(systemName: "photo.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)  // Set fixed size for the image
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(radius: 4)
                            
                            // Item details on the right side
                            VStack(alignment: .leading, spacing: 12) {
                                Text(item.title)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .bold()
                                    .frame(maxWidth: .infinity, alignment: .leading) // Ensures title is aligned left
                                
                                Text(item.details)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                    .frame(maxWidth: .infinity, alignment: .leading) // Ensures details are aligned left
                                
                                Text("Created on \(item.timestamp, formatter: dateFormatter)")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                    .padding(.top, 4)
                                    .frame(maxWidth: .infinity, alignment: .leading) // Ensures date is aligned left
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 4)
                        )
                        .padding(.horizontal)  // Padding to avoid touching the edges of the screen
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic)) {
                ForEach(searchSuggestions, id: \.self) { suggestion in
                    Text(suggestion).searchCompletion(suggestion)
                }
            }
        }
    }

    private var filteredItems: [Item] {
        if searchText.isEmpty {
            return allItems
        } else {
            return allItems.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private var searchSuggestions: [String] {
        allItems.map { $0.title }.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    private func privateTab() -> some View {
        Text("Private Content")
    }

    private func publicTab() -> some View {
        Text("Public Content")
    }

    private func optionsTab() -> some View {
        Text("Options Content")
    }

    private func performSearch() {}
}

#Preview {
    ContentView()
}
