//
//  ReportGenerator.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import Foundation
import SwiftUI
import CoreData
import UIKit

// MARK: - Report Generator

class ReportGenerator {
    // Singleton instance
    static let shared = ReportGenerator()
    
    private func addFooter(to context: UIGraphicsPDFRendererContext, pageNumber: Int) {
        let pageInfo = context.pdfContextBounds
        let footer = "Page \(pageNumber)"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 8),
            .foregroundColor: UIColor.gray
        ]
        let footerSize = footer.size(withAttributes: footerAttributes)
        footer.draw(
            at: CGPoint(x: pageInfo.width - footerSize.width - 50, y: pageInfo.height - 20),
            withAttributes: footerAttributes
        )
    }
    
    // Generate a text report
    func generateTextReport(includeExpired: Bool = true, category: MedicationType? = nil) -> String {
        // Fetch medications based on filters
        let medications = MedicationDataManager.shared.fetchMedications(
            category: category,
            includeExpired: true
        )
        
        // Split into active and expired
        let activeItems = medications.filter { !$0.isExpired }
        let expiredItems = medications.filter { $0.isExpired }
        
        // Build report header
        var report = "FreshenUp Medication Catalog Report\n"
        report += "Generated on: \(formatDate(Date()))\n\n"
        
        // Add summary
        report += "SUMMARY:\n"
        report += "• Total Medications: \(medications.count)\n"
        report += "• Active Items: \(activeItems.count)\n"
        report += "• Expired Items: \(expiredItems.count)\n"
        
        // Add category breakdown if no category filter
        if category == nil {
            let prescriptionCount = medications.filter { $0.category == MedicationType.prescription.rawValue }.count
            let otcCount = medications.filter { $0.category == MedicationType.overTheCounter.rawValue }.count
            report += "• Prescription Medications: \(prescriptionCount)\n"
            report += "• Over-The-Counter Medications: \(otcCount)\n"
        }
        
        report += "\n"
        
        // Add active medications section
        report += "ACTIVE MEDICATIONS:\n"
        if activeItems.isEmpty {
            report += "No active medications found.\n"
        } else {
            for (index, medication) in activeItems.enumerated() {
                report += "\(index + 1). \(medication.name)\n"
                report += "   Description: \(medication.shortDescription)\n"
                report += "   Manufacturer: \(medication.manufacturer)\n"
                report += "   Expiration: \(formatDate(medication.expirationDate))"
                
                if medication.daysUntilExpiration <= 30 {
                    report += " (Expires in \(medication.daysUntilExpiration) days)"
                }
                
                report += "\n   Category: \(medication.category)\n"
                report += "\n"
            }
        }
        
        // Add expired medications section if requested
        if includeExpired && !expiredItems.isEmpty {
            report += "\nEXPIRED MEDICATIONS:\n"
            for (index, medication) in expiredItems.enumerated() {
                report += "\(index + 1). \(medication.name)\n"
                report += "   Description: \(medication.shortDescription)\n"
                report += "   Manufacturer: \(medication.manufacturer)\n"
                report += "   Expired: \(formatDate(medication.expirationDate))"
                
                let daysSinceExpiration = -medication.daysUntilExpiration
                report += " (Expired \(daysSinceExpiration) days ago)"
                
                report += "\n   Category: \(medication.category)\n"
                report += "\n"
            }
        }
        
        return report
    }
    
    // Generate PDF report
    func generatePDFReport(includeExpired: Bool = true, category: MedicationType? = nil) -> Data? {
        // Get the report text
        let reportText = generateTextReport(includeExpired: includeExpired, category: category)
        
        // Set up PDF rendering
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792)) // US Letter size
        
        // Create the PDF
        let data = renderer.pdfData { (context) in
            // Parse report text into sections for formatting
            let lines = reportText.components(separatedBy: "\n")
            
            // Track current page manually
            var currentPage = 0
            
            // Initial position
            var currentY: CGFloat = 50
            let maxY: CGFloat = 742 // Maximum height before starting new page
            
            // Set up attributes
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.black
            ]
            
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 14),
                .foregroundColor: UIColor.black
            ]
            
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.black
            ]
            
            // Start first page
            context.beginPage()
            currentPage += 1
            
            for (index, line) in lines.enumerated() {
                var attributes = bodyAttributes
                
                // Check if this is a title or section header
                if index == 0 {
                    // Main title
                    attributes = titleAttributes
                    currentY += 10
                } else if line.hasSuffix(":") && line == line.uppercased() {
                    // Section header
                    attributes = subtitleAttributes
                    currentY += 10
                }
                
                // Calculate line height
                let textSize = line.size(withAttributes: attributes)
                
                // Check if we need a new page
                if currentY + textSize.height > maxY {
                    // Add footer to current page before creating a new one
                    addFooter(to: context, pageNumber: currentPage)
                    
                    // Create new page
                    context.beginPage()
                    currentPage += 1
                    currentY = 50 // Reset Y position for new page
                }
                
                // Draw the line
                line.draw(at: CGPoint(x: 50, y: currentY), withAttributes: attributes)
                currentY += textSize.height + 5
            }
            
            // Add footer to the last page
            addFooter(to: context, pageNumber: currentPage)
        }
        
        return data
    }
    
    // Generate CSV report
    func generateCSVReport(includeExpired: Bool = true, category: MedicationType? = nil) -> String {
        // Fetch medications based on filters
        let medications = MedicationDataManager.shared.fetchMedications(
            category: category,
            includeExpired: includeExpired
        )
        
        // Build CSV header
        var csv = "Name,Description,Manufacturer,Expiration Date,Category,Status\n"
        
        // Add each medication
        for medication in medications {
            let status = medication.isExpired ? "Expired" : "Active"
            let formattedDate = formatDate(medication.expirationDate)
            
            // Escape any commas in text fields
            let name = escapeCSVField(medication.name)
            let description = escapeCSVField(medication.shortDescription)
            let manufacturer = escapeCSVField(medication.manufacturer)
            
            // Add the row
            csv += "\(name),\(description),\(manufacturer),\(formattedDate),\(medication.category),\(status)\n"
        }
        
        return csv
    }
    
    // Escape CSV field
    private func escapeCSVField(_ field: String) -> String {
        var escaped = field
        
        // If the field contains commas, quotes, or newlines, wrap it in quotes
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            // Double any existing quotes
            escaped = escaped.replacingOccurrences(of: "\"", with: "\"\"")
            // Wrap in quotes
            escaped = "\"\(escaped)\""
        }
        
        return escaped
    }
    
    // Helper to format dates
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Report Generator View

struct ReportGeneratorView: View {
    // Report settings
    @State private var includeExpired = true
    @State private var selectedCategory: MedicationType? = nil
    @State private var selectedFormat: ReportFormat = .text
    
    // Report states
    @State private var isGeneratingReport = false
    @State private var reportText: String = ""
    @State private var reportData: Data? = nil
    @State private var showShareSheet = false
    
    var body: some View {
        Form {
            Section(header: Text("Report Options")) {
                // Include expired toggle
                Toggle("Include Expired Medications", isOn: $includeExpired)
                
                // Category picker
                Picker("Filter by Category", selection: $selectedCategory) {
                    Text("All Categories").tag(nil as MedicationType?)
                    Text("Prescription").tag(MedicationType.prescription)
                    Text("Over-The-Counter").tag(MedicationType.overTheCounter)
                }
                .pickerStyle(DefaultPickerStyle())
                
                // Format picker
                Picker("Report Format", selection: $selectedFormat) {
                    ForEach(ReportFormat.allCases, id: \.self) { format in
                        Text(format.description).tag(format)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section {
                // Generate report button
                Button(action: generateReport) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Generate Report")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(isGeneratingReport)
                
                // Share button
                if !reportText.isEmpty || reportData != nil {
                    Button(action: { showShareSheet = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Report")
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            
            // Report preview
            if !reportText.isEmpty && selectedFormat == .text {
                Section(header: Text("Preview")) {
                    ScrollView {
                        Text(reportText)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                    }
                    .frame(height: 300)
                }
            } else if reportData != nil && selectedFormat == .pdf {
                Section(header: Text("Preview Available")) {
                    Text("PDF report is ready to share")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else if !reportText.isEmpty && selectedFormat == .csv {
                Section(header: Text("CSV Preview")) {
                    Text("CSV data is ready to share")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Generate Report")
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(
                items: getItemsToShare(),
                excludedTypes: []
            )
        }
    }
    
    // Generate the report based on selected options
    private func generateReport() {
        isGeneratingReport = true
        
        // Clear previous report
        reportText = ""
        reportData = nil
        
        // Generate report based on selected format
        switch selectedFormat {
        case .text:
            reportText = ReportGenerator.shared.generateTextReport(
                includeExpired: includeExpired,
                category: selectedCategory
            )
            
        case .pdf:
            reportData = ReportGenerator.shared.generatePDFReport(
                includeExpired: includeExpired,
                category: selectedCategory
            )
            
        case .csv:
            reportText = ReportGenerator.shared.generateCSVReport(
                includeExpired: includeExpired,
                category: selectedCategory
            )
        }
        
        isGeneratingReport = false
    }
    
    // Get items to share based on format
    private func getItemsToShare() -> [Any] {
        switch selectedFormat {
        case .text:
            return [reportText]
        case .pdf:
            if let data = reportData {
                return [data]
            }
            return []
        case .csv:
            // Create a temporary file for CSV
            let fileName = "medications_\(Date().timeIntervalSince1970).csv"
            let tempDirectoryURL = FileManager.default.temporaryDirectory
            let fileURL = tempDirectoryURL.appendingPathComponent(fileName)
            
            do {
                try reportText.write(to: fileURL, atomically: true, encoding: .utf8)
                return [fileURL]
            } catch {
                print("Failed to write CSV file: \(error)")
                return [reportText]
            }
        }
    }
}

// Report format options
enum ReportFormat: CaseIterable {
    case text
    case pdf
    case csv
    
    var description: String {
        switch self {
        case .text: return "Text"
        case .pdf: return "PDF"
        case .csv: return "CSV"
        }
    }
}

// Share sheet UIViewControllerRepresentable
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    var excludedTypes: [UIActivity.ActivityType]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedTypes
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to update
    }
}

// MARK: - Medication Table Report View

struct MedicationTableReportView: View {
    // Filters
    @State private var selectedCategory: MedicationType? = nil
    @State private var showExpired = true
    @State private var searchText = ""
    
    // Medications
    @State private var medications: [Medication] = []
    
    var body: some View {
        VStack {
            // Filter controls
            HStack {
                Picker("Category", selection: $selectedCategory) {
                    Text("All").tag(nil as MedicationType?)
                    Text("Prescription").tag(MedicationType.prescription)
                    Text("OTC").tag(MedicationType.overTheCounter)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Toggle("Expired", isOn: $showExpired)
                    .toggleStyle(SwitchToggleStyle(tint: .red))
                    .labelsHidden()
            }
            .padding(.horizontal)
            
            // Search field
            TextField("Search medications", text: $searchText)
                .padding(7)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            
            // Table header
            HStack(spacing: 10) {
                Text("Name")
                    .font(.headline)
                    .frame(width: 100, alignment: .leading)
                
                Spacer()
                
                Text("Expiration")
                    .font(.headline)
                    .frame(width: 100, alignment: .center)
                
                Text("Status")
                    .font(.headline)
                    .frame(width: 80, alignment: .trailing)
            }
            .padding(.horizontal)
            .padding(.top, 5)
            
            // Table content
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredMedications, id: \.id) { medication in
                        MedicationTableRow(medication: medication)
                            .background(rowBackgroundColor(for: medication))
                    }
                }
            }
            
            // Export buttons
            HStack {
                Button(action: exportAsText) {
                    Label("Text", systemImage: "doc.text")
                }
                .buttonStyle(BorderedButtonStyle())
                
                Spacer()
                
                Button(action: exportAsPDF) {
                    Label("PDF", systemImage: "doc.richtext")
                }
                .buttonStyle(BorderedButtonStyle())
                
                Spacer()
                
                Button(action: exportAsCSV) {
                    Label("CSV", systemImage: "tablecells")
                }
                .buttonStyle(BorderedButtonStyle())
            }
            .padding()
        }
        .onAppear(perform: loadMedications)
        .onChange(of: selectedCategory) { _ in loadMedications() }
        .onChange(of: showExpired) { _ in loadMedications() }
    }
    
    // Load medications from Core Data
    private func loadMedications() {
        medications = MedicationDataManager.shared.fetchMedications(
            category: selectedCategory,
            includeExpired: showExpired
        )
    }
    
    // Filter medications based on search text
    private var filteredMedications: [Medication] {
        if searchText.isEmpty {
            return medications
        } else {
            return medications.filter { medication in
                medication.name.localizedCaseInsensitiveContains(searchText) ||
                medication.manufacturer.localizedCaseInsensitiveContains(searchText) ||
                medication.shortDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // Determine row background color
    private func rowBackgroundColor(for medication: Medication) -> Color {
        if medication.isExpired {
            return Color.red.opacity(0.1)
        } else if medication.daysUntilExpiration <= 30 {
            return Color.yellow.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    // Export functions
    private func exportAsText() {
        // Generate text report with current filters
        let report = ReportGenerator.shared.generateTextReport(
            includeExpired: showExpired,
            category: selectedCategory
        )
        
        // Share the text
        let activityController = UIActivityViewController(
            activityItems: [report],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
    
    private func exportAsPDF() {
        // Generate PDF report with current filters
        if let data = ReportGenerator.shared.generatePDFReport(
            includeExpired: showExpired,
            category: selectedCategory
        ) {
            // Share the PDF
            let activityController = UIActivityViewController(
                activityItems: [data],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityController, animated: true)
            }
        }
    }
    
    private func exportAsCSV() {
        // Generate CSV report with current filters
        let csv = ReportGenerator.shared.generateCSVReport(
            includeExpired: showExpired,
            category: selectedCategory
        )
        
        // Create a temporary file
        let fileName = "medications_\(Date().timeIntervalSince1970).csv"
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let fileURL = tempDirectoryURL.appendingPathComponent(fileName)
        
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Share the file
            let activityController = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityController, animated: true)
            }
        } catch {
            print("Failed to write CSV file: \(error)")
        }
    }
}

// Table row component
struct MedicationTableRow: View {
    let medication: Medication
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name)
                    .font(.body)
                    .lineLimit(1)
                
                Text(medication.manufacturer)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Text(formatDate(medication.expirationDate))
                .font(.body)
                .frame(width: 100, alignment: .center)
            
            statusView
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .contentShape(Rectangle())
    }
    
    // Status view
    private var statusView: some View {
        Group {
            if medication.isExpired {
                Text("Expired")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(4)
            } else if medication.daysUntilExpiration <= 30 {
                Text("\(medication.daysUntilExpiration)d left")
                    .font(.caption)
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.yellow)
                    .cornerRadius(4)
            } else {
                Text("Active")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green)
                    .cornerRadius(4)
            }
        }
    }
    
    // Helper to format dates
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
}
