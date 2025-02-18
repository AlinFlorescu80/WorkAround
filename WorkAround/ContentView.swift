import SwiftUI
import SwiftData

// MARK: - Main Content & Navigation

struct ContentView: View {
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var showLoadingView = true
    @State private var showProfileSheet = false

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
            homeTab()
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
    
    // MARK: - Home Content

    private func homeTab() -> some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.timestamp) { index, item in
                        NavigationLink(destination: ItemDetailView(item: item)) {
                            ItemCardView(item: item, index: index)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showProfileSheet = true
                    }) {
                        Image(systemName: "person.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.primary)
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic)) {
                ForEach(searchSuggestions, id: \.self) { suggestion in
                    Text(suggestion).searchCompletion(suggestion)
                }
            }
            .sheet(isPresented: $showProfileSheet) {
                ProfileView()
            }
        }
    }
    
    // MARK: - Filtering & Suggestions
    
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
}

// MARK: - Loading View

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

// MARK: - Item Card & Detail Views

struct ItemCardView: View {
    let item: Item
    let index: Int

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


struct ItemDetailView: View {
    let item: Item
    
    var body: some View {
        KanbanBoardView()
            .navigationTitle("Kanban Board")
    }
}

struct ProfileView: View {
    var body: some View {
        VStack {
            Text("Profile")
                .font(.largeTitle)
                .padding()
            Spacer()
        }
        .navigationTitle("Profile")
    }
}

// MARK: - Kanban Board Models & Views

struct KanbanColumn: Identifiable {
    let id = UUID()
    var title: String
    var cards: [KanbanCard]
}

struct KanbanCard: Identifiable, Equatable {
    let id: UUID = UUID()
    var title: String
    var details: String
}

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
                        .frame( minWidth: 250, maxHeight: .infinity)
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

struct CardDropDelegate: DropDelegate {
    let targetCard: KanbanCard
    @Binding var targetColumn: KanbanColumn
    @Binding var allColumns: [KanbanColumn]
    
    func performDrop(info: DropInfo) -> Bool {
        handleDrop(info: info)
    }
    
    private func handleDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else {
            return false
        }
        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
            DispatchQueue.main.async {
                if let data = data as? Data,
                   let idString = String(data: data, encoding: .utf8),
                   let draggedCardID = UUID(uuidString: idString) {
                    moveCard(with: draggedCardID)
                }
            }
        }
        return true
    }
    
    private func moveCard(with draggedCardID: UUID) {
        for i in allColumns.indices {
            if let removeIndex = allColumns[i].cards.firstIndex(where: { $0.id == draggedCardID }) {
                let movingCard = allColumns[i].cards.remove(at: removeIndex)
                if let targetIndex = targetColumn.cards.firstIndex(where: { $0.id == targetCard.id }) {
                    targetColumn.cards.insert(movingCard, at: targetIndex)
                } else {
                    targetColumn.cards.append(movingCard)
                }
                break
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

struct ColumnDropDelegate: DropDelegate {
    @Binding var targetColumn: KanbanColumn
    @Binding var allColumns: [KanbanColumn]
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else {
            return false
        }
        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { data, error in
            DispatchQueue.main.async {
                if let data = data as? Data,
                   let idString = String(data: data, encoding: .utf8),
                   let draggedCardID = UUID(uuidString: idString) {
                    moveCard(with: draggedCardID)
                }
            }
        }
        return true
    }
    
    private func moveCard(with draggedCardID: UUID) {
        for i in allColumns.indices {
            if let removeIndex = allColumns[i].cards.firstIndex(where: { $0.id == draggedCardID }) {
                let movingCard = allColumns[i].cards.remove(at: removeIndex)
                targetColumn.cards.append(movingCard)
                break
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}
