import SwiftUI

struct AuthenticateView: View {
    var namespace: Namespace.ID
    var onSignIn: () -> Void
    var imageWidth: CGFloat

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image("WorkAroundIcon")
                .resizable()
                .scaledToFit()
                .matchedGeometryEffect(id: "logo", in: namespace)
                .frame(maxWidth: imageWidth)
                .padding()
            
            VStack(spacing: 16) {
                Button(action: {
                    onSignIn()
                }) {
                    Text("Sign In")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: {
                }) {
                    Text("Sign Up")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(Color.blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                        .cornerRadius(12)
                }
            }
            .frame(width: imageWidth)
            
            Button(action: {
            }) {
                Text("Continue without an account")
                    .font(.body)
                    .foregroundColor(.gray)
            }
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.white, Color.blue.opacity(0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

struct AuthenticateView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticateView(namespace: Namespace().wrappedValue, onSignIn: {}, imageWidth: 300)
    }
}
