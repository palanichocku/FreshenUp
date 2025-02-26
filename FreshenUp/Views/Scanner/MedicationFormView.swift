//
//  MedicationFormView.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import SwiftUI

struct MedicationFormView: View {
    var barcode: String
    
    @State private var name = ""
    @State private var description = ""
    @State private var manufacturer = ""
    @State private var expirationDate = Date()
    @State private var category: MedicationCategory = .overTheCounter
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Drug Information")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    TextField("Manufacturer", text: $manufacturer)
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        Text("Prescription").tag(MedicationCategory.prescription)
                        Text("Over-The-Counter").tag(MedicationCategory.overTheCounter)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Expiration Date")) {
                    DatePicker("Expiration Date", selection: $expirationDate, displayedComponents: .date)
                }
                
                Section {
                    Button("Save Medication") {
                        // Save the medication
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarItems(trailing: Button("Cancel") {
                // Dismiss the form
            })
        }
    }
}
