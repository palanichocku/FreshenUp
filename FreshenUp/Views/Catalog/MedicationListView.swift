import SwiftUI
import CoreData

struct MedicationListView: View {
    // Properties to control filtering
    var expirationFilter: ExpirationFilterType
    var category: MedicationType?
    
    // Environment for context
    @Environment(\.managedObjectContext) private var viewContext
    
    // State for medication detail view
    @State private var selectedMedication: Medication?
    @State private var showingMedicationDetail = false
    
    // Create a fetch request using SwiftUI's FetchRequest property wrapper
    @FetchRequest private var medications: FetchedResults<Medication>
    
    // Initialize with filter parameters
    init(expirationFilter: ExpirationFilterType, category: MedicationType?) {
        self.expirationFilter = expirationFilter
        self.category = category
        
        // Create the appropriate predicate based on filters
        var predicates: [NSPredicate] = []
        
        // Filter by expiration
        switch expirationFilter {
        case .active:
            // Show only non-expired items
            predicates.append(NSPredicate(format: "expirationDate >= %@", Date() as NSDate))
        case .expired:
            // Show only expired items
            predicates.append(NSPredicate(format: "expirationDate < %@", Date() as NSDate))
        case .all:
            // Don't add any expiration predicate - show everything
            break
        }
        
        // Filter by category if specified
        if let category = category {
            predicates.append(NSPredicate(format: "category == %@", category.rawValue))
        }
        
        // Combine predicates if we have any
        let predicate: NSPredicate?
        if predicates.isEmpty {
            predicate = nil  // No predicates, match everything
        } else if predicates.count == 1 {
            predicate = predicates[0]  // Just one predicate
        } else {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)  // Multiple predicates
        }
        
        // Initialize the FetchRequest with the predicate
        _medications = FetchRequest(
            entity: Medication.entity(),
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Medication.expirationDate, ascending: true),
                NSSortDescriptor(keyPath: \Medication.name, ascending: true)
            ],
            predicate: predicate,
            animation: .default
        )
        
        print("MedicationListView initialized with filter - Expiration: \(expirationFilter.rawValue), Category: \(category?.rawValue ?? "All")")
    }
    
    var body: some View {
        ZStack {
            // Main view depends on whether we have medications
            if medications.isEmpty {
                // Empty state view
                VStack(spacing: 20) {
                    Image(systemName: "pill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                    
                    Group {
                        // Dynamically choose text based on filter type
                        switch expirationFilter {
                        case .active:
                            Text("No active medications found")
                        case .expired:
                            Text("No expired medications found")
                        case .all:
                            Text("No medications found")
                        }
                    }
                    .font(.headline)
                    
                    Text("Scan a barcode or add medications manually")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    // Debug button in development
                    #if DEBUG
                    Button("Debug: Show Database Contents") {
                        debugPrintAllMedications()
                    }
                    .padding(.top, 30)
                    .font(.caption)
                    #endif
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Show list of medications
                List {
                    // If showing "all", group by expiration status
                    if expirationFilter == .all {
                        // Active medications section
                        let activeMeds = medications.filter { !$0.isExpired }
                        if !activeMeds.isEmpty {
                            Section(header: Text("Active Medications")) {
                                ForEach(activeMeds, id: \.id) { medication in
                                    MedicationItemView(medication: medication)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedMedication = medication
                                            showingMedicationDetail = true
                                        }
                                }
                                .onDelete(perform: { indexSet in
                                    deleteMedications(medications: activeMeds, at: indexSet)
                                })
                            }
                        }
                        
                        // Expired medications section
                        let expiredMeds = medications.filter { $0.isExpired }
                        if !expiredMeds.isEmpty {
                            Section(header: Text("Expired Medications")) {
                                ForEach(expiredMeds, id: \.id) { medication in
                                    MedicationItemView(medication: medication)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedMedication = medication
                                            showingMedicationDetail = true
                                        }
                                }
                                .onDelete(perform: { indexSet in
                                    deleteMedications(medications: expiredMeds, at: indexSet)
                                })
                            }
                        }
                    } else {
                        // Standard list when not showing "all"
                        ForEach(medications, id: \.id) { medication in
                            MedicationItemView(medication: medication)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedMedication = medication
                                    showingMedicationDetail = true
                                }
                        }
                        .onDelete(perform: { indexSet in
                            deleteMedications(medications: Array(medications), at: indexSet)
                        })
                    }
                }
                
                // Debug info in development builds
                #if DEBUG
                VStack {
                    Spacer()
                    Text("Showing \(medications.count) medications")
                        .font(.caption)
                        .padding(8)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.bottom)
                #endif
            }
        }
        .onAppear {
            // Just print debug info, don't trigger refresh
            print("MedicationListView appeared with \(medications.count) medications")
            debugPrintAllMedications()
        }
        .sheet(isPresented: $showingMedicationDetail) {
            if let medication = selectedMedication {
                MedicationEditView(medication: medication)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    // Delete medications from an array at specific indices
    private func deleteMedications(medications: [Medication], at indexSet: IndexSet) {
        for index in indexSet {
            // Make sure index is valid
            guard index < medications.count else { continue }
            
            let medication = medications[index]
            viewContext.delete(medication)
        }
        
        do {
            try viewContext.save()
            print("✅ Successfully deleted medication(s)")
        } catch {
            print("❌ Error deleting medication: \(error)")
        }
    }
    
    // Debug function to print all medications in the database
    private func debugPrintAllMedications() {
        let request = NSFetchRequest<Medication>(entityName: "Medication")
        
        do {
            let allMeds = try viewContext.fetch(request)
            print("🔍 DEBUG: All medications in database (\(allMeds.count) total):")
            
            for med in allMeds {
                print("  - \(med.name) (Barcode: \(med.barcode))")
                print("    Category: \(med.category), Expires: \(med.expirationDate)")
                print("    Is Expired: \(med.isExpired)")
            }
            
            // Also print our filter conditions
            print("🔍 Current filter: Category=\(category?.rawValue ?? "All"), ExpirationFilter=\(expirationFilter.rawValue)")
        } catch {
            print("❌ Error fetching all medications: \(error)")
        }
    }
}
