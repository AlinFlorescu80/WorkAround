    //
    //  ChatView.swift
    //  WorkAround
    //
    //  Created by Alin Florescu on 21.04.2025.
    //

import SwiftUI
import Foundation
import FirebaseFirestore
import FirebaseAuth

struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    let senderEmail: String
    
    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.messages) { msg in
                            VStack(spacing: 4) {
                                    // Sender’s email aligned with the bubble
                                HStack {
                                    if msg.sender == senderEmail {
                                        Spacer()
                                        Text(msg.sender)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text(msg.sender)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                }
                                    // Message bubble aligned the same way
                                HStack {
                                    if msg.sender == senderEmail {
                                        Spacer()
                                        bubble(msg.text, color: .blue.opacity(0.2))
                                    } else {
                                        bubble(msg.text, color: .gray.opacity(0.2))
                                        Spacer()
                                    }
                                }
                            }
                            .id(msg.id)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .opacity
                            ))
                        }
                    }
                    .padding(.horizontal, 10)
                    .animation(.easeInOut, value: viewModel.messages.count)
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
            .padding(.top, 8)
        }
        .padding(.vertical, 8)
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
