import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift




struct AuthenticateView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.colorScheme) var colorScheme
    
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
                                print("User signed in successfully: \(authResult!.user)!!!!!!!!!!!!!!!!")
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
                    
                    
                    Button {
                        Task {
                            if await signInWithGoogle() {
                                navigateToHome = true
                                authManager.isSignedIn = true
                            }
                        }
                    } label: {
                        Text("Sign in with Google")
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .frame(width: 250)
                            .padding(.vertical, 8)
                            .background(alignment: .leading) {
                                Image("Google")
                                    .resizable()
                                    .scaledToFit()
                            }
                            .background(Color.white)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))
                    }
//                    .buttonStyle(.bordered)
                    
                    
//                    Button("Sign in with Google")
//                    {
//                        
//                    }
//                    .frame(width: 250, height: 50)
//                    .foregroundColor(.blue)
//                    
//                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))
//                    .padding()
//                    
                    
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


//MARK: Google Sign-In

enum AuthenticationError: Error {
    case tokenError(message: String)
}

@MainActor
extension AuthenticateView {
    
    func signInWithGoogle() async -> Bool {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            fatalError("No Client ID found")
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else{
            print("There is no root view controller")
            return false
        }
        
        
        do{
            let userAuthentication = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = userAuthentication.user
            guard let idToken = user.idToken else {
                throw AuthenticationError.tokenError(message: "No ID Token found")
            }
            let accessToken = user.accessToken
            let credential = GoogleAuthProvider.credential(withIDToken: idToken.tokenString, accessToken: accessToken.tokenString)
            let result = try await Auth.auth().signIn(with: credential)
            let firebaseUser = result.user
            print("User \(firebaseUser.uid) signed in with email \(firebaseUser.email ?? "unknown")")
            return true
        }
        catch{
            print(error.localizedDescription)
            let errorMessage = error.localizedDescription  // am pus let aici desi nu stiu sigur daca asa trebuia
            return false
        }
        
        return false
        
        
    }
}
