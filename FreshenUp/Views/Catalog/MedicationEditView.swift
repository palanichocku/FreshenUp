//
//  MedicationEditView.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/26/25.
//

import SwiftUI

struct MedicationEditView: View {
    // Environment
    @Environment(\.managedObjectContext) var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // The medication to edit
    var medication: Medication
    
    // Editable state
    @State private var name: String
    @State private var description: String
    @State private var manufacturer: String
    @State private var expirationDate: Date
    @State private var category: MedicationType
    
    // Status states
    @State private var isSaving = false
    @State private var showDeleteConfirmation = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // Initialize with medication values
    init(medication: Medication) {
        self.medication = medication
        
        // Initialize editable fields
        _name = State(initialValue: medication.name)
        _description = State(initialValue: medication.shortDescription)
        _manufacturer = State(initialValue: medication.manufacturer)
        _expirationDate = State(initialValue: medication.expirationDate)
        
        // Convert string category to enum
        if medication.category == MedicationType.prescription.rawValue {
            _category = State(initialValue: .prescription)
        } else {
            _category = State(initialValue: .overTheCounter)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medication Information")) {
                    // Editable name field
                    VStack(alignment: .leading) {
                        Text("Name").font(.caption).foregroundColor(.gray)
                        TextField("Name", text: $name)
                    }
                    
                    // Editable description field
                    VStack(alignment: .leading) {
                        Text("Description").font(.caption).foregroundColor(.gray)
                        TextField("Description", text: $description)
                    }
                    
                    // Editable manufacturer field
                    VStack(alignment: .leading) {
                        Text("Manufacturer").font(.caption).foregroundColor(.gray)
                        TextField("Manufacturer", text: $manufacturer)
                    }
                    
                    // Non-editable barcode (just for information)
                    VStack(alignment: .leading) {
                        Text("Barcode").font(.caption).foregroundColor(.gray)
                        Text(medication.barcode)
                    }
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        Text("Prescription").tag(MedicationType.prescription)
                        Text("Over-The-Counter").tag(MedicationType.overTheCounter)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Expiration Date")) {
                    DatePicker(
                        "Expiration Date",
                        selection: $expirationDate,
                        displayedComponents: .date
                    )
                }
                
                Section {
                    Button(action: updateMedication) {
                        if isSaving {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Saving...")
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .disabled(isSaving)
                }
                
                Section {
                    Button(action: { showDeleteConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Medication")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Edit Medication")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .actionSheet(isPresented: $showDeleteConfirmation) {
                ActionSheet(
                    title: Text("Delete Medication"),
                    message: Text("Are you sure you want to delete this medication? This action cannot be undone."),
                    buttons: [
                        .destructive(Text("Delete")) {
                            deleteMedication()
                        },
                        .cancel()
                    ]
                )
            }
        }
    }
    
    // Function to update medication
    private func updateMedication() {
        // Validation
        guard !name.isEmpty else {
            errorMessage = "Medication name cannot be empty"
            showError = true
            return
        }
        
        isSaving = true
        
        // Update medication properties
        medication.name = name
        medication.shortDescription = description
        medication.manufacturer = manufacturer
        medication.expirationDate = expirationDate
        medication.category = category.rawValue
        
        // Save changes
        do {
            try viewContext.save()
            
            // Dismiss the sheet
            DispatchQueue.main.async {
                isSaving = false
                presentationMode.wrappedValue.dismiss()
            }
        } catch {
            DispatchQueue.main.async {
                isSaving = false
                errorMessage = "Failed to save changes: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    // Function to delete medication
    private func deleteMedication() {
        // Delete the medication
        viewContext.delete(medication)
        
        // Save changes
        do {
            try viewContext.save()
            
            // Dismiss the sheet
            presentationMode.wrappedValue.dismiss()
        } catch {
            errorMessage = "Failed to delete medication: \(error.localizedDescription)"
            showError = true
        }
    }
}
