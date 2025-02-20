import SwiftUI

struct AuthenticateView: View {
    @State private var showInitialView: Bool = true
    @State private var email: String = ""
    @State private var password: String = ""
    var body: some View {
        
        // MARK: Initial view
            Spacer()
            
            Image("WorkAroundIcon")
                .resizable()
                .frame(width: 250, height: 250)
            
            Spacer()
        
        if showInitialView
        {
            
            Button("Sign in")
            {
                showInitialView.toggle()
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
                .padding()
            
            SecureField("Password", text: $password)
                .padding()
            
            
            
            Button("Sign in with Google")
            {
                showInitialView.toggle()
            }
            .frame(width: 250, height: 50)
            .foregroundColor(.blue)

            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue, lineWidth: 2))
            .padding()
            
            
            Button("🍏 Sign in WIth Apple")
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
}


#Preview {
    AuthenticateView()
}
