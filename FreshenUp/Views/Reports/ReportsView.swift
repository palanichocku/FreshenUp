//
//  ReportsView.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import SwiftUI

struct ReportsView: View {
    @State private var includeExpired = true
    
    var body: some View {
        Form {
            Section(header: Text("Report Options")) {
                Toggle("Include Expired Items", isOn: $includeExpired)
            }
            
            Section {
                Button(action: {
                    // Generate report action
                }) {
                    Label("Generate Report", systemImage: "doc.text")
                }
                
                Button(action: {
                    // Share report action
                }) {
                    Label("Share Catalog", systemImage: "square.and.arrow.up")
                }
            }
            
            Section(header: Text("Report Preview")) {
                // Preview of the report content
                List {
                    Text("This is a preview of how your report will look")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Sample report items
                    VStack(alignment: .leading) {
                        Text("Prescription Medications: 5")
                            .font(.headline)
                        Text("Over-The-Counter: 12")
                        Text("Expired Items: 3")
                        Text("Expiring Soon: 2")
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
}
