//
//  SettingsView.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var alertDaysBefore = 7
        @State private var showDeletionConfirmation = false
        @State private var showDeletionSuccess = false
    
    // Environment objects to refresh the UI
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        Form {
            Section(header: Text("Notification Settings")) {
                Stepper("Alert \(alertDaysBefore) days before expiration", value: $alertDaysBefore, in: 1...90)
            }
            
            Section(header: Text("Catalog Management")) {
                Button(action: deleteEntireCatalog) {
                    Label("Delete Entire Catalog", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
            
            Section(header: Text("About")) {
                NavigationLink(destination: AboutView()) {
                    Label("About FreshenUp", systemImage: "info.circle")
                }
            }
        }
        .alert("Confirm Deletion", isPresented: $showDeletionConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        confirmDeletion()
                    }
                } message: {
                    Text("Are you sure you want to delete your entire medication catalog? This action cannot be undone.")
                }
                .alert("Catalog Deleted", isPresented: $showDeletionSuccess) {
                    Button("OK") { }
                } message: {
                    Text("Your medication catalog has been successfully cleared.")
                }
    }
    
    func deleteEntireCatalog() {
            showDeletionConfirmation = true
    }
        
    func confirmDeletion() {
        // Delete all medications
        MedicationDataManager.shared.deleteAllMedications()
        
        // Cancel all notifications
        NotificationManager.shared.cancelAllMedicationNotifications()
        
        // Show success message
        showDeletionSuccess = true
    }
    
}
