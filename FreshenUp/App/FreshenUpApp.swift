//
//  FreshenUpApp.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import SwiftUI

@main
struct FreshenUpApp: App {
    // Create a shared persistence controller
    @StateObject private var persistenceController = PersistenceController.shared
    
    // Create notification delegate once for the whole app
    @StateObject private var notificationDelegate = NotificationDelegate()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // Inject Core Data context into the environment
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                // Make NotificationDelegate available across the app
                .environmentObject(notificationDelegate)
                // Add OnAppear to handle notification setup
                .onAppear {
                    // Request notification permissions on first launch
                    NotificationManager.shared.requestAuthorization()
                }
        }
    }
}

