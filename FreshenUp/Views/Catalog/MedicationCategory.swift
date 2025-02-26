//
//  MedicationCategory.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import Foundation

enum MedicationCategory: String, CaseIterable, Identifiable {
    case prescription = "Prescription"
    case overTheCounter = "Over-The-Counter"
    
    var id: String { self.rawValue }
}
