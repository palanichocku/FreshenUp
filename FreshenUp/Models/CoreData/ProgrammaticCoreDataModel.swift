import Foundation
import CoreData

// MARK: - Programmatic Core Data Model
extension PersistenceController {
    
    // Create the Core Data model programmatically
    static func createProgrammaticModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // MARK: - Create Medication Entity
        let medicationEntity = NSEntityDescription()
        medicationEntity.name = "Medication"
        medicationEntity.managedObjectClassName = NSStringFromClass(Medication.self)
        
        // Create properties for Medication (instead of attributes)
        var medicationProperties: [NSPropertyDescription] = []
        
        // ID attribute
        let idAttribute = NSAttributeDescription()
        idAttribute.name = "id"
        idAttribute.attributeType = .UUIDAttributeType
        idAttribute.isOptional = false
        medicationProperties.append(idAttribute)
        
        // Name attribute
        let nameAttribute = NSAttributeDescription()
        nameAttribute.name = "name"
        nameAttribute.attributeType = .stringAttributeType
        nameAttribute.isOptional = false
        medicationProperties.append(nameAttribute)
        
        // Description attribute
        let descriptionAttribute = NSAttributeDescription()
        descriptionAttribute.name = "shortDescription"
        descriptionAttribute.attributeType = .stringAttributeType
        descriptionAttribute.isOptional = false
        medicationProperties.append(descriptionAttribute)
        
        // Manufacturer attribute
        let manufacturerAttribute = NSAttributeDescription()
        manufacturerAttribute.name = "manufacturer"
        manufacturerAttribute.attributeType = .stringAttributeType
        manufacturerAttribute.isOptional = false
        medicationProperties.append(manufacturerAttribute)
        
        // Barcode attribute
        let barcodeAttribute = NSAttributeDescription()
        barcodeAttribute.name = "barcode"
        barcodeAttribute.attributeType = .stringAttributeType
        barcodeAttribute.isOptional = false
        medicationProperties.append(barcodeAttribute)
        
        // Expiration Date attribute
        let expirationDateAttribute = NSAttributeDescription()
        expirationDateAttribute.name = "expirationDate"
        expirationDateAttribute.attributeType = .dateAttributeType
        expirationDateAttribute.isOptional = false
        medicationProperties.append(expirationDateAttribute)
        
        // Date Added attribute
        let dateAddedAttribute = NSAttributeDescription()
        dateAddedAttribute.name = "dateAdded"
        dateAddedAttribute.attributeType = .dateAttributeType
        dateAddedAttribute.isOptional = false
        medicationProperties.append(dateAddedAttribute)
        
        // Category attribute
        let categoryAttribute = NSAttributeDescription()
        categoryAttribute.name = "category"
        categoryAttribute.attributeType = .stringAttributeType
        categoryAttribute.isOptional = false
        medicationProperties.append(categoryAttribute)
        
        // MARK: - Create NotificationAlert Entity
        let notificationEntity = NSEntityDescription()
        notificationEntity.name = "NotificationAlert"
        notificationEntity.managedObjectClassName = NSStringFromClass(NotificationAlert.self)
        
        // Create properties for NotificationAlert (instead of attributes)
        var notificationProperties: [NSPropertyDescription] = []
        
        // ID attribute
        let notificationIdAttribute = NSAttributeDescription()
        notificationIdAttribute.name = "id"
        notificationIdAttribute.attributeType = .UUIDAttributeType
        notificationIdAttribute.isOptional = false
        notificationProperties.append(notificationIdAttribute)
        
        // Trigger Date attribute
        let triggerDateAttribute = NSAttributeDescription()
        triggerDateAttribute.name = "triggerDate"
        triggerDateAttribute.attributeType = .dateAttributeType
        triggerDateAttribute.isOptional = false
        notificationProperties.append(triggerDateAttribute)
        
        // Is Delivered attribute
        let isDeliveredAttribute = NSAttributeDescription()
        isDeliveredAttribute.name = "isDelivered"
        isDeliveredAttribute.attributeType = .booleanAttributeType
        isDeliveredAttribute.isOptional = false
        notificationProperties.append(isDeliveredAttribute)
        
        // MARK: - Create Relationships
        
        // Medication to NotificationAlert relationship (one-to-many)
        let medicationToNotificationsRelationship = NSRelationshipDescription()
        medicationToNotificationsRelationship.name = "notifications"
        medicationToNotificationsRelationship.destinationEntity = notificationEntity
        medicationToNotificationsRelationship.isOptional = true
        medicationToNotificationsRelationship.deleteRule = .cascadeDeleteRule
        medicationToNotificationsRelationship.minCount = 0
        medicationToNotificationsRelationship.maxCount = 0 // 0 means unlimited
        
        // NotificationAlert to Medication relationship (many-to-one)
        let notificationToMedicationRelationship = NSRelationshipDescription()
        notificationToMedicationRelationship.name = "medication"
        notificationToMedicationRelationship.destinationEntity = medicationEntity
        notificationToMedicationRelationship.isOptional = false
        notificationToMedicationRelationship.deleteRule = .nullifyDeleteRule
        notificationToMedicationRelationship.minCount = 1
        notificationToMedicationRelationship.maxCount = 1
        
        // Set inverse relationships
        medicationToNotificationsRelationship.inverseRelationship = notificationToMedicationRelationship
        notificationToMedicationRelationship.inverseRelationship = medicationToNotificationsRelationship
        
        // Add relationships to properties arrays
        medicationProperties.append(medicationToNotificationsRelationship)
        notificationProperties.append(notificationToMedicationRelationship)
        
        // Set properties on entities
        medicationEntity.properties = medicationProperties
        notificationEntity.properties = notificationProperties
        
        // Add entities to model
        model.entities = [medicationEntity, notificationEntity]
        
        return model
    }
}

// The rest of the code remains the same...
