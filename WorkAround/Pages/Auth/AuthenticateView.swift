import SwiftUI
import FirebaseAuth

struct AuthenticateView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var showInitialView: Bool = true
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var navigateToHome: Bool = false
    @State private var showLoadingView : Bool = true

    var body: some View {
        
        NavigationStack {
            VStack {
                Spacer()
                
                
                Image("WorkAroundIcon")
                    .resizable()
                    .frame(width: 250, height: 250)
                
                Spacer()
                
                if showInitialView
                {
                    
                    Button("Sign in")
                    {
                        withAnimation(.bouncy) {
                            showInitialView.toggle()
                        }
                    }
                    .frame(width: 250, height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding()
                    
                    
                    Button("Sign Up")
                    {
                        
                    }
                    .frame(width: 250, height: 50)
                    .foregroundColor(.blue)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))
                    .padding(.bottom)
                    
                    
                    Button ("Continue without an account...")
                    {
                        
                    }
                    
                    Spacer()
                }
                
                else {
                    TextField("Mail", text: $email)
                        .frame(width: 250)
                        .keyboardType(.emailAddress)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .frame(width: 250)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Sign in with Email")
                    {
                        Auth.auth().signIn(withEmail: email, password: password)
                        {
                            authResult,
                            error in
                            if let error = error
                            {
                                print("Failed to sign in: \(error.localizedDescription)")
                            }
                            else
                            {
                                print("User signed in successfully.")
                                showLoadingView = false
                                withAnimation(.bouncy)
                                {
                                    navigateToHome = true
                                    authManager.isSignedIn = true
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(width: 250, height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.top)
                    
                    
                    
                    Button("Sign in with Google")
                    {
                        
                    }
                    .frame(width: 250, height: 50)
                    .foregroundColor(.blue)
                    
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))
                    .padding()
                    
                    
                    Button("🍏 Sign in With Apple")
                    {
                        
                        showInitialView.toggle()
                    }
                    .frame(width: 250, height: 50)
                    .foregroundColor(.blue)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))
                    .padding(.bottom)
                    
                    Spacer()
                    
                    
                }
                
            }
            
            
            .overlay(
                Group {
                    if !showInitialView {
                        Button(action: {
                            withAnimation(.bouncy) {
                                showInitialView = true
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.left")
                                Text("Back")
                            }
                            .padding(8)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(8)
                        }
                        .padding(.top, 10)
                        .padding(.leading, 10)
                    }
                },
                alignment: .topLeading
                
                
            )
            
            .navigationDestination(isPresented: $navigateToHome)
            {
                HomeView(showLoadingView: false)
            }
        }
        
    }
  
}


//#Preview {
//    AuthenticateView()
//}
