//
//  BarcodeScannerViewModel.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//
import Foundation
import Combine

struct AlertMessage: Identifiable {
    let id = UUID()
    let content: String
    let shouldShowManualEntry: Bool
}

class BarcodeScannerViewModel: ObservableObject {
    @Published var scannedBarcode: String = ""
    @Published var isScanning: Bool = true
    @Published var showManualEntry: Bool = false
    @Published var errorMessage: String?
    @Published var alertMessage: AlertMessage?
    @Published var showMedicationInfo: Bool = false
    @Published var medicationInfo: MedicationInfo?
    @Published var isProcessing: Bool = false
   
    private let barcodeService = BarcodeService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to barcode service updates
        barcodeService.$medicationInfo
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] info in
                self?.isProcessing = false
                self?.medicationInfo = info
                
                // Only pause scanning if we found a match
                if self?.isScanning == true {
                    self?.isScanning = false
                }
                
                self?.showMedicationInfo = true
            }
            .store(in: &cancellables)
        
        barcodeService.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                self?.isProcessing = false
                
                // Show error alert
                self?.alertMessage = AlertMessage(
                    content: error,
                    shouldShowManualEntry: true
                )
            }
            .store(in: &cancellables)
    }
    
    // Improved barcode normalization
    func normalizeBarcode(_ code: String) -> String {
        // Remove any non-numeric characters
        let cleanedCode = code.filter { $0.isNumber }
        print("Original barcode: \(code), Cleaned: \(cleanedCode)")
        
        // Handle various barcode formats
        if cleanedCode.hasPrefix("00") && cleanedCode.count >= 12 {
            // Double-zero prefix - likely an error in scanning
            let trimmed = String(cleanedCode.dropFirst(1)) // Remove only one zero
            print("Removed extra zero, now: \(trimmed)")
            return trimmed
        } else if cleanedCode.hasPrefix("0") && cleanedCode.count == 13 {
            // Standard EAN-13 with leading zero
            let trimmed = String(cleanedCode.dropFirst())
            print("Normalized from EAN-13 to UPC: \(trimmed)")
            return trimmed
        }
        
        return cleanedCode
    }
    
    // Process a scanned or manually entered barcode
    func processBarcode(automaticLookup: Bool = false) {
        isProcessing = true
        
        // Normalize the barcode
        let normalizedBarcode = normalizeBarcode(scannedBarcode)
        print("Processing barcode: \(normalizedBarcode)")
        
        guard !normalizedBarcode.isEmpty else {
            isProcessing = false
            alertMessage = AlertMessage(
                content: "Please enter a valid barcode",
                shouldShowManualEntry: false
            )
            return
        }
        
        // Don't pause scanning during automatic lookup
        if !automaticLookup {
            isScanning = false
        }
        // Use the more comprehensive barcode handling from BarcodeHandler
        print("Processing barcode: \(scannedBarcode)")
        
        // Try looking up with the barcode service
        barcodeService.lookupMedication(barcode: normalizedBarcode)
    }
    
    // Reset scanner state
    func resetScanner() {
        scannedBarcode = ""
        isScanning = true
        showManualEntry = false
        showMedicationInfo = false
        errorMessage = nil
        alertMessage = nil
        medicationInfo = nil
        isProcessing = false
    }
    
    // Check if a barcode matches a known pattern
    func isValidBarcodeFormat(_ code: String) -> Bool {
        let cleaned = code.filter { $0.isNumber }
        
        // Common barcode formats: UPC-A (12 digits), EAN-13 (13 digits), NDC (10-11 digits)
        return cleaned.count >= 10 && cleaned.count <= 14 // Allow slightly larger range
    }
}
