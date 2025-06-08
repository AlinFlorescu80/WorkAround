    //
    //  ProfileView.swift
    //  WorkAround
    //
    //  Created by Alin Florescu on 18.02.2025.
    //

import SwiftUI
import FirebaseAuth
import UIKit

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("appearanceOption") private var appearanceOption: Int = 2 // 0‑light, 1‑dark, 2‑system
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                    // MARK: Header
                VStack(spacing: 12) {
                    Text("Working Around")
                        .font(.title3.bold())
                }
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 12)
                
                    // MARK: Preferences
                Section("Preferences") {
                    HStack {
                        Label("Appearance", systemImage: "paintbrush")
                        Spacer()
                        Picker("", selection: $appearanceOption) {
                            Text("Light").tag(0)
                            Text("Dark").tag(1)
                            Text("System").tag(2)
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Button {
                        guard let url = notificationSettingsURL else { return }
                        UIApplication.shared.open(url)
                    } label: {
                        Label("Notification Preferences", systemImage: "bell.badge")
                    }
                }
                
                    // MARK: About
                Section("About") {
                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share WorkAround", systemImage: "square.and.arrow.up")
                    }
                    
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        Label("Privacy Policy", systemImage: "lock")
                    }
                    
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                }
                
                    // MARK: Account
                Section("Account") {
                    Button(role: .destructive) {
                        do {
                            try Auth.auth().signOut()
                            authManager.isSignedIn = false
                            dismiss()
                        } catch {
                            print(error.localizedDescription)
                        }
                    } label: {
                        Label("Sign Out", systemImage: "door.left.hand.open")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                let url = URL(string: "https://apps.apple.com/app/id123456789")!
                ActivityView(activityItems: [url])
            }
        }
        .onAppear { applyAppearance() }
        .onChange(of: appearanceOption) { _ in
            applyAppearance()
        }
    }
    
        // MARK: Helpers
        /// Applies the chosen appearance option to every window in every scene.
    private func applyAppearance() {
        let style: UIUserInterfaceStyle
        switch appearanceOption {
            case 0: style = .light
            case 1: style = .dark
            default: style = .unspecified   // system / follow device
        }
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
    
        /// Returns the appropriate URL for the app‑specific Notification settings if available,
        /// otherwise falls back to the main settings page for this app.
    private var notificationSettingsURL: URL? {
        if #available(iOS 16.0, *) {
            return URL(string: UIApplication.openNotificationSettingsURLString)
        } else {
            return URL(string: UIApplication.openSettingsURLString)
        }
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }
}
    // MARK: Activity View (Share Sheet)
private struct ActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity] = []
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems,
                                 applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

    // MARK: – Dummy Privacy‑Policy View
private struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    private let policyText: String = """
    Privacy Policy
    --------------
    This is a dummy document for demonstration purposes.
    
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer nec odio. Praesent libero. Sed cursus ante dapibus diam. Sed nisi. Nulla quis sem at nibh elementum imperdiet. Duis sagittis ipsum. Praesent mauris. Fusce nec tellus sed augue semper porta. Mauris massa. Vestibulum lacinia arcu eget nulla.
    
    Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Curabitur sodales ligula in libero. Sed dignissim lacinia nunc. Curabitur tortor. Pellentesque nibh. Aenean quam. In scelerisque sem at dolor. Maecenas mattis. Sed convallis tristique sem.
    """
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(policyText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Privacy Policy")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
