//
//  HomeView.swift
//  WorkAround
//
//  Created by Alin Florescu on 18.02.2025.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var showLoadingView = true
    @State private var showProfileSheet = false

    // Example data (in a real app, you’d load this from your model/persistence)
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
            homeContent()
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
    
    private func homeContent() -> some View {
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
                    Button(action: { showProfileSheet = true }) {
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

#Preview {
    HomeView()
}
