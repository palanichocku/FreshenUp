//
//  BackgroundNotificationProcessor.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import Foundation
import UserNotifications
import CoreData

class BackgroundNotificationProcessor {
    // Process medication expiration in the background
    static func processExpiredMedications() {
        // Get medications that have expired
        let expiredMedications = MedicationDataManager.shared.fetchExpiredMedications()
        
        // Process each expired medication
        for medication in expiredMedications {
            // Get the medication ID string directly (since it's non-optional)
            let medicationIDString = medication.id.uuidString
            
            // Check if there's a notification set for this medication
            let notificationCenter = UNUserNotificationCenter.current()
            notificationCenter.getPendingNotificationRequests { requests in
                // Filter for notifications related to this medication
                let medicationNotifications = requests.filter { request in
                    // Check if userInfo contains this medication's ID
                    if let notificationMedicationID = request.content.userInfo["medicationID"] as? String {
                        return notificationMedicationID == medicationIDString
                    }
                    return false
                }
                
                // If no notification exists for this expired medication, create one
                if medicationNotifications.isEmpty {
                    // Create expired notification content
                    let content = UNMutableNotificationContent()
                    content.title = "\(medication.name) Has Expired"
                    content.body = "Your medication expired on \(Self.formatDate(medication.expirationDate)). Please dispose of it properly."
                    content.sound = .default
                    content.categoryIdentifier = "EXPIRATION_ALERT"
                    
                    // Add the medication ID to userInfo
                    content.userInfo = ["medicationID": medicationIDString]
                    
                    // Create immediate trigger
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                    
                    // Create unique identifier
                    let identifier = "medication-expired-\(medicationIDString)"
                    
                    // Create and schedule the request
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    notificationCenter.add(request)
                }
            }
        }
    }
    
    // Helper to format dates
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
