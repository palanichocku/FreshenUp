//
//  NotificationAlert.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import Foundation
import CoreData

class NotificationAlert: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var triggerDate: Date
    @NSManaged public var isDelivered: Bool
    @NSManaged public var medication: Medication
}

extension NotificationAlert {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NotificationAlert> {
        return NSFetchRequest<NotificationAlert>(entityName: "NotificationAlert")
    }
}
