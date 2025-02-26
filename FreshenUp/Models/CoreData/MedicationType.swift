//
//  MedicationType.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import Foundation

enum MedicationType: String, CaseIterable, Identifiable {
    case prescription = "Prescription"
    case overTheCounter = "OTC"
    
    var id: String { self.rawValue }
    
    // Display name (for UI)
    var displayName: String {
        switch self {
        case .prescription:
            return "Prescription"
        case .overTheCounter:
            return "Over-The-Counter"
        }
    }
}

