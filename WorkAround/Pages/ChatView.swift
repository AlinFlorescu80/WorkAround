//
//  ChatView.swift
//  WorkAround
//
//  Created by Alin Florescu on 21.04.2025.
//

import SwiftUI

struct ChatView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    let senderEmail: String
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach(chatViewModel.messages) { msg in
                    HStack {
                        if msg.sender == senderEmail {
                            Spacer()
                            Text(msg.text)
                                .padding()
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(8)
                        } else {
                            Text(msg.text)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            Spacer()
                        }
                    }
                }
            }
            .padding()
            
            HStack {
                TextField("Enter message...", text: $chatViewModel.newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    chatViewModel.sendMessage(sender: senderEmail)
                }
            }
            .padding()
        }
        .navigationTitle("Board Chat")
    }
}
