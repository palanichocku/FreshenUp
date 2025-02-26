//
//  NotificationDelegate.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import Foundation
import CoreData
import UserNotifications

// This is likely part of your NotificationDelegate class
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    @Published var selectedMedicationID: UUID?
    
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        print("NotificationDelegate initialized")
    }
    
    // Helper to get medication by ID
    private func getMedication(withID uuid: UUID) -> Medication? {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest = NSFetchRequest<Medication>(entityName: "Medication")
        fetchRequest.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching medication by ID: \(error)")
            return nil
        }
    }
    
    // Handle received notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show the notification even if app is in foreground
        completionHandler([.banner, .sound])
    }
    
    // Handle notification actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Get the medication ID from the notification (fixed to handle optionals properly)
        if let medicationIDString = response.notification.request.content.userInfo["medicationID"] as? String,
           let uuid = UUID(uuidString: medicationIDString) {
            
            // Handle different actions
            switch response.actionIdentifier {
            case "MARK_REVIEWED":
                // Update UI to show this medication
                DispatchQueue.main.async {
                    self.selectedMedicationID = uuid
                }
                
            case "SNOOZE_DAY":
                // Snooze notification for 1 day
                if let medication = getMedication(withID: uuid) {
                    // Create snoozed notification
                    let content = response.notification.request.content.mutableCopy() as! UNMutableNotificationContent
                    content.title = "[Snoozed] \(content.title)"
                    
                    // Set trigger for tomorrow
                    let triggerDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                    let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    
                    // Create new request with snoozed identifier
                    let identifier = "\(response.notification.request.identifier)-snoozed"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    
                    // Schedule the snoozed notification
                    center.add(request)
                }
                
            default:
                // For other actions, including default tap
                DispatchQueue.main.async {
                    self.selectedMedicationID = uuid
                }
            }
        }
        
        completionHandler()
    }
}
