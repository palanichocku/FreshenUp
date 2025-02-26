//
//  Medication.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import Foundation
import CoreData

// MARK: - Core Data Model

// This represents how the Core Data entities would be defined in the .xcdatamodeld file
// For completeness, I'm also including the NSManagedObject subclasses

// MARK: - Medication Entity
class Medication: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var shortDescription: String
    @NSManaged public var manufacturer: String
    @NSManaged public var barcode: String
    @NSManaged public var expirationDate: Date
    @NSManaged public var dateAdded: Date
    @NSManaged public var category: String // "Prescription" or "OTC"
    @NSManaged public var notifications: Set<NotificationAlert>?
    
    // Computed property to check if expired
    var isExpired: Bool {
        return Date() > expirationDate
    }
    
    // Computed property for days until expiration
    var daysUntilExpiration: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expirationDate)
        return components.day ?? 0
    }
}

extension Medication {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Medication> {
        return NSFetchRequest<Medication>(entityName: "Medication")
    }
}
