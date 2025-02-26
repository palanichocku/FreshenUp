//
//  MedicationDataManager.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import Foundation
import CoreData


class MedicationDataManager {
    // Singleton for easy access throughout the app
    static let shared = MedicationDataManager()
    
    // Private constructor for singleton
    private init() {}
    
    // Use the persistent container from the central controller
    var viewContext: NSManagedObjectContext {
        return PersistenceController.shared.container.viewContext
    }
    
    // Save context changes
    func saveContext() {
        PersistenceController.shared.save()
    }
    
    // MARK: - Create Medication
    
    func createMedication(name: String,
                              description: String,
                              manufacturer: String,
                              barcode: String,
                              expirationDate: Date,
                              category: MedicationType) -> Medication {
            
        let medication = Medication(context: viewContext)
        medication.id = UUID()
        medication.name = name
        medication.shortDescription = description
        medication.manufacturer = manufacturer
        medication.barcode = barcode
        medication.expirationDate = expirationDate
        medication.dateAdded = Date()
        medication.category = category.rawValue
        
        saveContext()
        print("Created medication: \(name) with ID: \(medication.id.uuidString)")
        return medication
    }
    
    // MARK: - Barcode Cache
    
    // Check if a barcode exists in the database
    func medicationExists(withBarcode barcode: String) -> Bool {
            let fetchRequest = NSFetchRequest<Medication>(entityName: "Medication")
            fetchRequest.predicate = NSPredicate(format: "barcode == %@", barcode)
            fetchRequest.fetchLimit = 1
            
            do {
                let count = try viewContext.count(for: fetchRequest)
                return count > 0
            } catch {
                print("Error checking barcode existence: \(error)")
                return false
            }
    }
    
    // Find medication by barcode
    func findMedication(byBarcode barcode: String) -> Medication? {
            let fetchRequest = NSFetchRequest<Medication>(entityName: "Medication")
            fetchRequest.predicate = NSPredicate(format: "barcode == %@", barcode)
            fetchRequest.fetchLimit = 1
            
            do {
                let results = try viewContext.fetch(fetchRequest)
                return results.first
            } catch {
                print("Error fetching medication by barcode: \(error)")
                return nil
            }
    }
    
    // Find medication by ID
    func findMedication(byID id: UUID) -> Medication? {
        let fetchRequest = NSFetchRequest<Medication>(entityName: "Medication")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            return results.first
        } catch {
            print("Error fetching medication by ID: \(error)")
            return nil
        }
    }
    
    // MARK: - Fetching Medications
    
    // Fetch all medications
    func fetchAllMedications() -> [Medication] {
        let fetchRequest = NSFetchRequest<Medication>(entityName: "Medication")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching medications: \(error)")
            return []
        }
    }
    
    // Fetch medications by category
    func fetchMedications(category: MedicationType? = nil, includeExpired: Bool = true) -> [Medication] {
        let fetchRequest = NSFetchRequest<Medication>(entityName: "Medication")
        
        var predicates: [NSPredicate] = []
        
        // Category filter
        if let category = category {
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        }
        
        // Expiration filter
        if !includeExpired {
            predicates.append(NSPredicate(format: "expirationDate > %@", Date() as NSDate))
        }
        
        // Combine predicates if needed
        if !predicates.isEmpty {
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "category", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching medications: \(error)")
            return []
        }
    }
    
    // Fetch expired medications
    func fetchExpiredMedications() -> [Medication] {
        let fetchRequest = NSFetchRequest<Medication>(entityName: "Medication")
        fetchRequest.predicate = NSPredicate(format: "expirationDate < %@", Date() as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "expirationDate", ascending: true)]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching expired medications: \(error)")
            return []
        }
    }
    
    // Fetch medications expiring soon
    func fetchMedicationsExpiringSoon(withinDays days: Int = 30) -> [Medication] {
        let calendar = Calendar.current
        guard let futureDate = calendar.date(byAdding: .day, value: days, to: Date()) else {
            return []
        }
        
        let fetchRequest = NSFetchRequest<Medication>(entityName: "Medication")
        fetchRequest.predicate = NSPredicate(format: "expirationDate > %@ AND expirationDate <= %@",
                                            Date() as NSDate, futureDate as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "expirationDate", ascending: true)]
        
        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("Error fetching medications expiring soon: \(error)")
            return []
        }
    }
    
    // MARK: - Delete Operations
    
    // Delete a single medication
    func deleteMedication(_ medication: Medication) {
        viewContext.delete(medication)
        saveContext()
    }
    
    // Delete all medications (clear catalog)
    func deleteAllMedications() {
        // Create a fetch request for batch delete
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Medication")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            // Configure batch delete to return the IDs of deleted objects
            deleteRequest.resultType = .resultTypeObjectIDs
            
            do {
                // Use the PersistenceController.shared.container instead of persistentContainer
                let result = try PersistenceController.shared.container.persistentStoreCoordinator.execute(deleteRequest, with: viewContext) as? NSBatchDeleteResult
                
                if let objectIDArray = result?.result as? [NSManagedObjectID] {
                    // Merge the changes into our managed object context
                    NSManagedObjectContext.mergeChanges(
                        fromRemoteContextSave: [NSDeletedObjectsKey: objectIDArray],
                        into: [viewContext]
                    )
                }
                
                // Explicitly refresh objects in the context to ensure they disappear from the UI
                viewContext.refreshAllObjects()
                
                // Save context to persist changes
                saveContext()
                
                print("Successfully deleted all medications")
            } catch {
                print("Error deleting all medications: \(error)")
            }
    }
    
    // MARK: - Notification Alerts
    
    // Create a notification alert
    func createNotificationAlert(for medication: Medication, triggerDate: Date) -> NotificationAlert {
        let alert = NotificationAlert(context: viewContext)
        alert.id = UUID()
        alert.triggerDate = triggerDate
        alert.isDelivered = false
        alert.medication = medication
        
        saveContext()
        return alert
    }
    
    // Schedule alerts for medication expiration
    func scheduleExpirationAlerts(for medication: Medication, daysBeforeArray: [Int] = [30, 7, 1]) {
        // First remove any existing alerts
        let fetchRequest = NSFetchRequest<NotificationAlert>(entityName: "NotificationAlert")
        fetchRequest.predicate = NSPredicate(format: "medication == %@", medication)
        
        do {
            let existingAlerts = try viewContext.fetch(fetchRequest)
            for alert in existingAlerts {
                viewContext.delete(alert)
            }
            
            // Create new alerts for each interval
            for days in daysBeforeArray {
                if let alertDate = Calendar.current.date(byAdding: .day, value: -days, to: medication.expirationDate) {
                    // Only create future alerts
                    if alertDate > Date() {
                        createNotificationAlert(for: medication, triggerDate: alertDate)
                    }
                }
            }
            
            saveContext()
        } catch {
            print("Error scheduling alerts: \(error)")
        }
    }
    
    // Process pending notifications for scheduling
    func processPendingNotifications() {
        let fetchRequest = NSFetchRequest<NotificationAlert>(entityName: "NotificationAlert")
        fetchRequest.predicate = NSPredicate(format: "isDelivered == %@", NSNumber(value: false))
        
        do {
            let pendingAlerts = try viewContext.fetch(fetchRequest)
            for alert in pendingAlerts {
                if alert.triggerDate > Date() {
                    // This would be handled by NotificationManager
                    print("Processing alert: \(alert.id.uuidString ?? "unknown")")
                }
            }
        } catch {
            print("Error fetching pending notifications: \(error)")
        }
    }
    
    // Mark a notification as delivered
    func markNotificationDelivered(alertID: UUID) {
        let fetchRequest = NSFetchRequest<NotificationAlert>(entityName: "NotificationAlert")
        fetchRequest.predicate = NSPredicate(format: "id == %@", alertID as CVarArg)
        fetchRequest.fetchLimit = 1
        
        do {
            if let alert = try viewContext.fetch(fetchRequest).first {
                alert.isDelivered = true
                saveContext()
            }
        } catch {
            print("Error marking notification as delivered: \(error)")
        }
    }
}
