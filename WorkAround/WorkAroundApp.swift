import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import UserNotifications
import FirebaseFirestore

final class ChatNotificationService {
    static let shared = ChatNotificationService()
    private init() {}
    
    private let db = Firestore.firestore()
    private var listeners: [String: ListenerRegistration] = [:]
    
    func startListening(for boardID: String) {
        var isInitialSnapshot = true
        guard listeners[boardID] == nil else { return }
        
        let handle = db.collection("boards")
            .document(boardID)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { snapshot, error in
                if isInitialSnapshot {
                    isInitialSnapshot = false
                    return
                }
                if let error = error {
                    print("Notification service error (\(boardID)): \(error)")
                    return
                }
                
                snapshot?.documentChanges.forEach { change in
                    if change.type == .added,
                       let msg = try? change.document.data(as: ChatMessage.self) {
                        if let myEmail = Auth.auth().currentUser?.email?.lowercased(),
                           msg.sender.lowercased() == myEmail {
                            return
                        }
                        Self.fireLocalNotification(for: msg)
                    }
                }
            }
        listeners[boardID] = handle
    }
    
    private static func fireLocalNotification(for msg: ChatMessage) {
        let content = UNMutableNotificationContent()
        content.title = msg.sender
        content.body  = msg.text
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        FirebaseApp.configure()
        if let email = Auth.auth().currentUser?.email?.lowercased() {
            Firestore.firestore().collection("boards").whereField("members", arrayContains: email).getDocuments { snapshot, error in
                guard let docs = snapshot?.documents, error == nil else {
                    print("Error fetching boards for notifications: \(error?.localizedDescription ?? "unknown error")")
                    return
                }
                for doc in docs {
                    ChatNotificationService.shared.startListening(for: doc.documentID)
                }
            }
        }
        
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

@main
struct WorkAroundApp: App {
    @StateObject var authManager = AuthManager()
    @Namespace private var logoNamespace
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ Item.self ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if Auth.auth().currentUser != nil {
                    HomeView(logoNamespace: logoNamespace, showLoadingView: false)     
                } else {
                    AuthenticateView()
                }
            }
            .environmentObject(authManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
