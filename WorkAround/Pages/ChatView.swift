    //
    //  ChatView.swift
    //  WorkAround
    //
    //  Created by Alin Florescu on 21.04.2025.
    //

import SwiftUI
import Foundation
import FirebaseFirestore

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    let senderEmail: String
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(viewModel.messages) { msg in
                        HStack {
                            if msg.sender == senderEmail {
                                Spacer()
                                bubble(msg.text, color: .blue.opacity(0.2))
                            } else {
                                bubble(msg.text, color: .gray.opacity(0.2))
                                Spacer()
                            }
                        }
                        .id(msg.id)
                    }
                }
                .onChange(of: viewModel.messages.count) { _ in
                        // auto‑scroll to the latest message
                    if let lastID = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }
            
            HStack {
                TextField("Enter message…",
                          text: $viewModel.newMessage,
                          axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...3)
                
                Button("Send") {
                    viewModel.sendMessage(sender: senderEmail)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .navigationTitle("Board Chat")
    }
    
    @ViewBuilder
    private func bubble(_ text: String, color: Color) -> some View {
        Text(text)
            .padding(10)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
