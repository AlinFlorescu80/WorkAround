import FirebaseAuth
import SwiftUI

class AuthManager: ObservableObject {
    @Published var isSignedIn: Bool = false
    
    init() {
        isSignedIn = (Auth.auth().currentUser != nil)
        
        Auth.auth().addStateDidChangeListener { _, user in
            self.isSignedIn = (user != nil)
        }
    }
}
