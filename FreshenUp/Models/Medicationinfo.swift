//
//  Medicationinfo.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import Foundation
import CoreData

import Foundation

// Updated MedicationInfo with var properties to allow modification
struct MedicationInfo {
    var name: String
    var description: String
    var manufacturer: String
    let barcode: String  // Keep barcode as let since it shouldn't change
    var expirationDate: Date? = nil
    var category: MedicationType = .overTheCounter
    
    // Convert to Medication Entity
    func toMedicationEntity(in context: NSManagedObjectContext) -> Medication {
        // Create a new Medication entity directly
        let medication = Medication(context: context)
        
        // Set all properties
        medication.id = UUID()
        medication.name = name
        medication.shortDescription = description
        medication.manufacturer = manufacturer
        medication.barcode = barcode
        
        // Default expiration date to 1 year if not set
        if let expDate = expirationDate {
            medication.expirationDate = expDate
        } else {
            medication.expirationDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        }
        
        medication.dateAdded = Date()
        medication.category = category.rawValue
        
        return medication
    }
    
    // Save to database
    func saveMedication() -> Medication {
        return MedicationDataManager.shared.createMedication(
            name: name,
            description: description,
            manufacturer: manufacturer,
            barcode: barcode,
            expirationDate: expirationDate ?? Calendar.current.date(byAdding: .year, value: 1, to: Date())!,
            category: category
        )
    }
}
