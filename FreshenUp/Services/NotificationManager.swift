//
//  NotificationManager.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import Foundation
import UserNotifications
import Combine

// MARK: - Notification Manager

class NotificationManager: ObservableObject {
    // Singleton instance
    static let shared = NotificationManager()
    
    // Published properties
    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []
    
    // Default schedule preferences
    private let defaultAlertDaysBefore = [30, 7, 1]
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Check authorization status
        checkAuthorizationStatus()
        
        // Refresh pending notifications list
        refreshPendingNotifications()
    }
    
    // Request notification permission
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                
                if granted {
                    // Register notification categories for actions
                    self?.registerNotificationCategories()
                }
                
                if let error = error {
                    print("Notification authorization error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Check current authorization status
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // Register custom notification categories and actions
    private func registerNotificationCategories() {
        // Action to mark as reviewed
        let reviewAction = UNNotificationAction(
            identifier: "MARK_REVIEWED",
            title: "Mark as Reviewed",
            options: .foreground
        )
        
        // Action to snooze notification
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_DAY",
            title: "Remind Tomorrow",
            options: .foreground
        )
        
        // Create expiration category
        let expirationCategory = UNNotificationCategory(
            identifier: "EXPIRATION_ALERT",
            actions: [reviewAction, snoozeAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Register the category
        UNUserNotificationCenter.current().setNotificationCategories([expirationCategory])
    }
    
    // Get a list of pending notifications
    func refreshPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            DispatchQueue.main.async {
                self?.pendingNotifications = requests
            }
        }
    }
    
    // Schedule medication expiration notifications
    func scheduleExpirationNotifications(for medication: Medication, daysBefore: [Int]? = nil) {
        // Use default or provided schedule
        let alertDays = daysBefore ?? defaultAlertDaysBefore
        
        // Make sure we have permission
        guard isAuthorized else {
            requestAuthorization()
            return
        }
        
        // Get the expiration date
        let expirationDate = medication.expirationDate
        
        // For each scheduled alert timeframe
        for days in alertDays {
            // Calculate the notification date
            guard let notificationDate = Calendar.current.date(byAdding: .day, value: -days, to: expirationDate) else {
                continue
            }
            
            // Only schedule future notifications
            if notificationDate > Date() {
                scheduleNotification(
                    for: medication,
                    at: notificationDate,
                    daysRemaining: days
                )
            }
        }
        
        // Refresh the pending notifications list
        refreshPendingNotifications()
    }
    
    // Schedule a single notification
    private func scheduleNotification(for medication: Medication, at date: Date, daysRemaining: Int) {
        // Create notification content
        let content = UNMutableNotificationContent()
        
        // Set notification details based on days remaining
        if daysRemaining > 7 {
            content.title = "\(medication.name) Expires Soon"
            content.body = "Your medication expires in \(daysRemaining) days (on \(formatDate(medication.expirationDate)))."
        } else if daysRemaining > 1 {
            content.title = "\(medication.name) Expiring Soon"
            content.body = "Your medication will expire in \(daysRemaining) days (on \(formatDate(medication.expirationDate)))."
            content.sound = .default
        } else {
            content.title = "\(medication.name) Expires Tomorrow"
            content.body = "Your medication will expire tomorrow (on \(formatDate(medication.expirationDate)))."
            content.sound = .default
        }
        
        // Add medication ID to user info (using non-optional access)
        let medicationID = medication.id.uuidString
        content.userInfo = ["medicationID": medicationID]
        
        // Set category for actions
        content.categoryIdentifier = "EXPIRATION_ALERT"
        
        // Create date components trigger
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        // Create unique identifier (using non-optional access)
        let identifier = "medication-\(medication.id.uuidString)-\(daysRemaining)days"
        
        // Create and schedule the request
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Cancel all notifications for a specific medication
    func cancelNotifications(for medication: Medication) {
        // Use direct access to id (non-optional)
        let medicationID = medication.id.uuidString
        
        // Find all notification identifiers for this medication
        let identifiers = pendingNotifications
            .filter { $0.content.userInfo["medicationID"] as? String == medicationID }
            .map { $0.identifier }
        
        // Remove the notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        
        // Refresh the list
        refreshPendingNotifications()
    }
    
    // Cancel all medication expiration notifications
    func cancelAllMedicationNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        refreshPendingNotifications()
    }
    
    // Helper to format dates
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
