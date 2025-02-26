import SwiftUI

struct MedicationCatalogView: View {
    // Change from boolean to enum for more flexibility
    @State private var expirationFilter: ExpirationFilterType = .active
    @State private var selectedCategory: MedicationType? = nil
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        VStack(spacing: 0) {
            // Category Picker
            Picker("Category", selection: $selectedCategory) {
                Text("All").tag(nil as MedicationType?)
                Text("Prescription").tag(MedicationType.prescription)
                Text("Over-The-Counter").tag(MedicationType.overTheCounter)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Improved Expiration Filter with 3 options
            VStack(spacing: 4) {
                Text("Expiration Filter:")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Picker("Expiration Filter", selection: $expirationFilter) {
                    Text("Active Only").tag(ExpirationFilterType.active)
                    Text("Expired Only").tag(ExpirationFilterType.expired)
                    Text("Show All").tag(ExpirationFilterType.all)
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)
            .padding(.bottom)
            
            // Pass the new filter type to MedicationListView
            MedicationListView(
                expirationFilter: expirationFilter,
                category: selectedCategory
            )
            .environment(\.managedObjectContext, viewContext)
            // Force recreation when filters change
            .id("\(expirationFilter.rawValue)-\(selectedCategory?.rawValue ?? "all")")
        }
        .navigationTitle("Medicine Catalog")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Add medication manually action
                }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

// Expiration filter options
enum ExpirationFilterType: String, CaseIterable {
    case active = "active"
    case expired = "expired"
    case all = "all"
}
