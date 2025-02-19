import SwiftUI

struct SignInView: View {
    var namespace: Namespace.ID
    var imageWidth: CGFloat
    var onBack: () -> Void
    var onSignIn: () -> Void

    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Custom Back Button
                HStack {
                    Button(action: {
                        withAnimation {
                            onBack()
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding()
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                Spacer()
                
                Image("WorkAroundIcon")
                    .resizable()
                    .scaledToFit()
                    .matchedGeometryEffect(id: "logo", in: namespace)
                    .frame(maxWidth: imageWidth)
                    .padding()
                
                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    
                    Button(action: {
                        onSignIn()
                    }) {
                        Text("Sign In")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    VStack(spacing: 16) {
                        Button(action: {
                        }) {
                            HStack {
                                Image(systemName: "applelogo")
                                Text("Apple")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                        }) {
                            HStack {
                                Image("googleLogo")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text("Google")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .cornerRadius(8)
                        }
                    }
                }
                .frame(width: imageWidth)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .background(Color.white)
            .ignoresSafeArea()
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView(namespace: Namespace().wrappedValue, imageWidth: 300, onBack: { print("Back pressed") }, onSignIn: { print("Sign In pressed") })
    }
}
