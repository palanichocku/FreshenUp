//
//  NotificationSettingsView.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import Foundation
import SwiftUI
import AVFoundation
import Combine

struct NotificationSettingsView: View {
    @ObservedObject private var notificationManager = NotificationManager.shared
    @State private var alertDays = [30, 7, 1]
    @State private var showingPermissionAlert = false
    
    var body: some View {
        Form {
            Section(header: Text("Notification Permissions")) {
                HStack {
                    Text("Notifications")
                    Spacer()
                    if notificationManager.isAuthorized {
                        Text("Enabled")
                            .foregroundColor(.green)
                    } else {
                        Button("Enable") {
                            notificationManager.requestAuthorization()
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            
            Section(header: Text("Alert Schedule")) {
                Text("Send alerts before expiration:")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                ForEach(0..<alertDays.count, id: \.self) { index in
                    Stepper("\(alertDays[index]) days before", value: $alertDays[index], in: 1...365)
                }
                
                Button("Add Alert") {
                    alertDays.append(30)
                }
                .foregroundColor(.blue)
                .disabled(alertDays.count >= 5)
            }
            
            Section {
                Button("Save Settings") {
                    if notificationManager.isAuthorized {
                        // Save the alert days to UserDefaults
                        UserDefaults.standard.set(alertDays, forKey: "ExpirationAlertDays")
                        
                        // Reschedule all medication notifications
                        rescheduleMedicationNotifications()
                    } else {
                        showingPermissionAlert = true
                    }
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
            }
            
            Section(header: Text("Pending Alerts")) {
                Text("\(notificationManager.pendingNotifications.count) notifications scheduled")
                
                if !notificationManager.pendingNotifications.isEmpty {
                    Button("View All") {
                        // Action to show all pending notifications
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            // Load saved alert days
            if let savedDays = UserDefaults.standard.array(forKey: "ExpirationAlertDays") as? [Int] {
                alertDays = savedDays
            }
        }
        .alert(isPresented: $showingPermissionAlert) {
            Alert(
                title: Text("Notification Permission Required"),
                message: Text("Please enable notifications to receive expiration alerts."),
                primaryButton: .default(Text("Settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // Reschedule all medication notifications
    private func rescheduleMedicationNotifications() {
        // Cancel all existing notifications
        notificationManager.cancelAllMedicationNotifications()
        
        // Get all medications
        let medications = MedicationDataManager.shared.fetchAllMedications()
        
        // Schedule new notifications for each medication
        for medication in medications {
            notificationManager.scheduleExpirationNotifications(for: medication, daysBefore: alertDays)
        }
    }
}
