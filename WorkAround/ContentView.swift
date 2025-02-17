import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var showLoadingView = true

    private let allItems: [Item] = [
        Item(timestamp: Date(), title: "Plan Project", details: "Outline all tasks for the WorkAround app."),
        Item(timestamp: Date().addingTimeInterval(-86400), title: "Design UI", details: "Sketch the Kanban interface."),
        Item(timestamp: Date().addingTimeInterval(-172800), title: "Implement Features", details: "Code the drag-and-drop feature."),
        Item(timestamp: Date().addingTimeInterval(-259200), title: "Test App", details: "Perform thorough testing."),
        Item(timestamp: Date().addingTimeInterval(-345600), title: "Deploy App", details: "Deploy the app to production."),
        Item(timestamp: Date().addingTimeInterval(-432000), title: "Collect Feedback", details: "Gather user feedback for improvements.")
    ]
    
    var body: some View {
        ZStack {
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
            .opacity(showLoadingView ? 0 : 1)
            .animation(.easeIn(duration: 0.5), value: showLoadingView)
            
            if showLoadingView {
                NaturalLoadingView(isLoading: $isLoading, onAnimationEnd: {
                    showLoadingView = false
                })
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
    


    private func homeTab() -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.timestamp) { index, item in
                        ItemCardView(item: item, index: index)
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
}

struct NaturalLoadingView: View {
    @Binding var isLoading: Bool
    var onAnimationEnd: () -> Void
    
    @State private var tilt = false
    @State private var pulse = false
    @State private var zoomIn = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            Image("WorkAroundIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 260, height: 260)
                .saturation(zoomIn ? 0 : 1)
                .scaleEffect(zoomIn ? 100 : (pulse ? 1.15 : 1.05))
                .opacity(zoomIn ? 0 : 1)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
        }
        .onAppear {
            pulse.toggle()
        }
        .onChange(of: isLoading) { oldValue, newValue in
            if !newValue {
                withAnimation(.easeIn(duration: 0.5)) {
                    zoomIn = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onAnimationEnd()
                }
            }
        }
    }
}

struct ItemCardView: View {
    let item: Item
    let index: Int
    @State private var isVisible: Bool = false

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(radius: 4)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(item.details)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
