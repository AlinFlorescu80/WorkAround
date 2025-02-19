import SwiftUI

enum AuthFlow {
    case authenticate, signIn, home
}

struct AuthParentView: View {
    @Namespace private var logoNamespace
    @State private var flow: AuthFlow = .authenticate
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let imageWidth = min(screenWidth * 0.6, 300)
            
            ZStack {
                switch flow {
                case .home:
                    HomeView()
                        .transition(.opacity)
                case .signIn:
                    SignInView(namespace: logoNamespace, imageWidth: imageWidth, onBack: {
                        withAnimation(.easeInOut) {
                            flow = .authenticate
                        }
                    }, onSignIn: {
                        withAnimation(.easeInOut) {
                            flow = .home
                        }
                    })
                    .transition(.opacity)
                case .authenticate:
                    AuthenticateView(namespace: logoNamespace, onSignIn: {
                        withAnimation(.easeInOut) {
                            flow = .signIn
                        }
                    }, imageWidth: imageWidth)
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.6), value: flow)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

struct AuthParentView_Previews: PreviewProvider {
    static var previews: some View {
        AuthParentView()
    }
}
