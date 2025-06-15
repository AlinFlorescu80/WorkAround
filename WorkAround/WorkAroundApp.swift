import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import UserNotifications
import FirebaseFirestore

    /// Keeps Firestore listeners alive so local notifications fire even when UI is closed.
final class ChatNotificationService {
    static let shared = ChatNotificationService()
    private init() {}
    
    private let db = Firestore.firestore()
    private var listeners: [String: ListenerRegistration] = [:]
    
        /// Start listening for new messages on a board. Calling twice with the same ID does nothing.
    func startListening(for boardID: String) {
        var isInitialSnapshot = true  // ignore the first batch of existing messages
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
                            // Skip notifications for messages authored by the current user
                        if let myEmail = Auth.auth().currentUser?.email?.lowercased(),
                           msg.sender.lowercased() == myEmail {
                            return           // ignore own message
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
        ChatNotificationService.shared.startListening(for: "sharedBoardID")
        
        return true
    }
    
        /// Show banners (and play sound) even when the app is active
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
                        // User is already signed in
                    HomeView(logoNamespace: logoNamespace, showLoadingView: false)     // Replace with your app's main content view
                } else {
                        // User is not signed in
                    AuthenticateView()
                }
            }
            .environmentObject(authManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
