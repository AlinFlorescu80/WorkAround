//
//  ProfileView.swift
//  WorkAround
//
//  Created by Alin Florescu on 18.02.2025.
//

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var AuthManager: AuthManager
        
    var body: some View {
        
        VStack {
            
            Text("Profile")
                .font(.largeTitle)
                .padding()
            
            if AuthManager.isSignedIn
            {
                Button("Sign Out")
                {
                    do{
                        try Auth.auth().signOut()
                        print("signed out successfully")
                        dismiss()
                        AuthManager.isSignedIn=false
                    }
                    catch
                    {
                        print(error.localizedDescription)
                    }
                }
                .frame(width: 250, height: 50)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding()
            }
            else
            {
                
            }
            
            
            
            Spacer()
        }
        .navigationTitle("Profile")
    }
}

