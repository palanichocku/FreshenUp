//
//  MedicationItemView.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import SwiftUI

struct MedicationItemView: View {
    var medication: Medication
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name)
                    .font(.headline)
                
                Text("Expires: \(formatDate(medication.expirationDate))")
                    .font(.subheadline)
                    .foregroundColor(medication.isExpired ? .red : .gray)
            }
            
            Spacer()
            
            // Visual indicator for expired items
            if medication.isExpired {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            } else if medication.daysUntilExpiration < 30 {
                // Show warning for items expiring soon
                Text("\(medication.daysUntilExpiration)d")
                    .font(.caption)
                    .padding(4)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
    
    // Helper to format dates
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
