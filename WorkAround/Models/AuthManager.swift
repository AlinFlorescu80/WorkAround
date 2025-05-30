import FirebaseAuth
import SwiftUI

class AuthManager: ObservableObject {
    @Published var isSignedIn: Bool = false
    
    init() {
            // 1. Seed initial state from any persisted user
        isSignedIn = (Auth.auth().currentUser != nil)
        
            // 2. Listen for auth state changes (e.g. session restoration)
        Auth.auth().addStateDidChangeListener { _, user in
            self.isSignedIn = (user != nil)
        }
    }
}
