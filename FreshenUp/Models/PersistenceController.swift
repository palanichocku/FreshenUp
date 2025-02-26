//
//  PersistenceController.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/26/25.
//

import Foundation
import CoreData
import SwiftUI

// MARK: - Persistent Controller - Core Data Manager
class PersistenceController: ObservableObject {
    
    // Add a published property that will change when data is updated
    @Published var dataUpdated = Date()
    
    // Shared instance for app-wide use
    static let shared = PersistenceController()
    
    // Storage for preview content
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        // Create sample data for previews
        let viewContext = controller.container.viewContext
        
        let sampleMed1 = Medication(context: viewContext)
        sampleMed1.id = UUID()
        sampleMed1.name = "Advil"
        sampleMed1.shortDescription = "Pain reliever"
        sampleMed1.manufacturer = "Pfizer"
        sampleMed1.barcode = "305730169609"
        sampleMed1.expirationDate = Date().addingTimeInterval(60*60*24*30*6) // 6 months
        sampleMed1.dateAdded = Date()
        sampleMed1.category = MedicationType.overTheCounter.rawValue
        
        let sampleMed2 = Medication(context: viewContext)
        sampleMed2.id = UUID()
        sampleMed2.name = "Amoxicillin"
        sampleMed2.shortDescription = "Antibiotic"
        sampleMed2.manufacturer = "Various"
        sampleMed2.barcode = "309040844012"
        sampleMed2.expirationDate = Date().addingTimeInterval(-60*60*24*30) // 1 month ago
        sampleMed2.dateAdded = Date().addingTimeInterval(-60*60*24*60) // 2 months ago
        sampleMed2.category = MedicationType.prescription.rawValue
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Failed to create preview data: \(nsError), \(nsError.userInfo)")
        }
        
        return controller
    }()
    
    // NSPersistentContainer holds the Core Data stack
    let container: NSPersistentContainer
    
    // Constructor - optionally create in-memory store for previews
    init(inMemory: Bool = false) {
        // Create a custom container with our programmatic model
        let model = PersistenceController.createProgrammaticModel()
        container = NSPersistentContainer(name: "FreshenUp", managedObjectModel: model)
        
        // Configure for in-memory storage if needed
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Load the persistent stores
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // Replace this with better error handling for production
                fatalError("Failed to load Core Data stack: \(error), \(error.userInfo)")
            }
        }
        
        // Configure automatic merging of changes
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Use this for better performance during batch operations
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // Save helper method
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Error saving context: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}
