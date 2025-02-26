import SwiftUI
import CoreData

struct MedicationInfoView: View {
    // Environment for dismissing the sheet and accessing managed object context
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var viewContext
    
    // Original info from API
    var info: MedicationInfo
    var onSave: () -> Void
    var onCancel: () -> Void
    
    // Editable state
    @State private var name: String
    @State private var description: String
    @State private var manufacturer: String
    @State private var expirationDate = Date().addingTimeInterval(60*60*24*365) // Default 1 year
    @State private var category: MedicationType
    @State private var isSaving = false
    @State private var showingSaveSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // Initialize with the info values
    init(info: MedicationInfo, onSave: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.info = info
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Initialize the editable fields with the info values
        _name = State(initialValue: info.name)
        _description = State(initialValue: info.description)
        _manufacturer = State(initialValue: info.manufacturer)
        
        // Set initial category (not optional)
        _category = State(initialValue: info.category)
        
        // Set initial expiration date if available
        if let existingDate = info.expirationDate {
            _expirationDate = State(initialValue: existingDate)
        }
        
        // Debug logging for initialization
        print("MedicationInfoView initialized with medication: \(info.name), barcode: \(info.barcode)")
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
                        Text(info.barcode)
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
                    Button(action: saveMedication) {
                        if isSaving {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Saving...")
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Add to Catalog")
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
            }
            .navigationTitle("Add to Catalog")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    // Properly dismiss the sheet and call onCancel
                    dismissSheet()
                }
            )
            .alert("Medication Added", isPresented: $showingSaveSuccess) {
                Button("OK") {
                    // Properly dismiss the sheet and call onSave
                    dismissSheet()
                    onSave()
                }
            } message: {
                Text("\(name) has been added to your catalog.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred while saving the medication.")
            }
        }
        .onAppear {
            // Print debug info about the context
            print("MedicationInfoView appeared - context: \(String(describing: viewContext))")
        }
    }
    
    private func dismissSheet() {
        presentationMode.wrappedValue.dismiss()
        onCancel()
    }
    
    // Function to save medication to database
    private func saveMedication() {
        // Validation
        guard !name.isEmpty else {
            errorMessage = "Medication name cannot be empty"
            showError = true
            return
        }
        
        isSaving = true
        print("➡️ STARTING SAVE: medication to catalog: \(name) with barcode \(info.barcode)")
        
        // Create a new medication directly in the viewContext
        let medication = Medication(context: viewContext)
        medication.id = UUID()
        medication.name = name
        medication.shortDescription = description
        medication.manufacturer = manufacturer
        medication.barcode = info.barcode
        medication.expirationDate = expirationDate
        medication.dateAdded = Date()
        medication.category = category.rawValue
        
        // Output for debugging
        print("📝 Created medication: ID=\(medication.id), Name=\(medication.name), Barcode=\(medication.barcode), Category=\(medication.category)")
        
        do {
            // Save immediately to Core Data
            try viewContext.save()
            print("✅ SAVE SUCCESS: medication saved to database with ID \(medication.id)")
            
            // Verify the medication was actually saved by trying to fetch it
            verifyMedicationWasSaved(id: medication.id)
            
            // Schedule notifications
            NotificationManager.shared.scheduleExpirationNotifications(for: medication)
            
            // Show success
            DispatchQueue.main.async {
                isSaving = false
                showingSaveSuccess = true
            }
        } catch {
            print("❌ SAVE ERROR: Failed to save medication: \(error.localizedDescription)")
            DispatchQueue.main.async {
                isSaving = false
                errorMessage = "Failed to save: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    // Verify the medication was actually saved to the database
    private func verifyMedicationWasSaved(id: UUID) {
        let fetchRequest = NSFetchRequest<Medication>(entityName: "Medication")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            if let savedMed = results.first {
                print("✅ VERIFICATION SUCCESS: Found saved medication: \(savedMed.name) with barcode \(savedMed.barcode)")
            } else {
                print("❌ VERIFICATION ERROR: Medication with ID \(id) not found after save")
            }
            
            // Also check if we can find it by barcode
            let barcodeRequest = NSFetchRequest<Medication>(entityName: "Medication")
            barcodeRequest.predicate = NSPredicate(format: "barcode == %@", info.barcode)
            let barcodeResults = try viewContext.fetch(barcodeRequest)
            print("🔍 Found \(barcodeResults.count) medications with barcode \(info.barcode)")
            
            // List all medications in the database
            let allRequest = NSFetchRequest<Medication>(entityName: "Medication")
            let allResults = try viewContext.fetch(allRequest)
            print("📊 Total medications in database: \(allResults.count)")
            for med in allResults {
                print("  - \(med.name) (\(med.barcode)) - Category: \(med.category), Expires: \(med.expirationDate)")
            }
        } catch {
            print("❌ VERIFICATION ERROR: Failed to verify medication save: \(error.localizedDescription)")
        }
    }
}
