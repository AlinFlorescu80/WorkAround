import SwiftUI

struct LoginView: View {
    @State private var navigateToHome = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Image("WorkAroundIcon")
                    .resizable()
                    .frame(width: 400, height: 400)
                
                Button("Sign In") {
                    navigateToHome = true
                }
                .foregroundColor(.white)
                .font(.largeTitle)
                .frame(width: 300, height: 50)
                .padding(32)
                .background(Color.blue)
                .cornerRadius(20)
                .padding()
                
                Button("Sign Up") {
                    // Sign Up action
                }
                .font(.largeTitle)
                .frame(width: 300, height: 50)
                .padding(32)
                .foregroundColor(.blue)
                .background(Color.white)
                .border(Color.blue, width: 1)
                .cornerRadius(20)
                
                Button("Continue without an account...") {
                    // Continue without account action
                }
                .padding()
                .font(.title3)
            }
            // The navigationDestination is attached to this NavigationStack:
            .navigationDestination(isPresented: $navigateToHome) {
                HomeView()
            }
        }
    }
}

#Preview {
    LoginView()
}
