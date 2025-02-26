//
//  BarcodeHandler.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/26/25.
//

import Foundation
import AVFoundation

// MARK: - Barcode Handler

class BarcodeHandler {
    // Comprehensive barcode normalization
    static func normalizeBarcode(_ code: String) -> String {
        // Remove any non-numeric characters
        let cleanedCode = code.filter { $0.isNumber }
        
        // Log original input for debugging
        print("🔍 BARCODE INPUT: \"\(code)\" cleaned to \"\(cleanedCode)\"")
        
        // Special case: The scanner seems to always add a prefix 0 to UPC codes
        // Let's detect and remove it based on common patterns
        var normalizedCode = cleanedCode
        
        // Step 1: Handle obvious zero prefixes
        if normalizedCode.hasPrefix("00") {
            // Remove one of the zeros (00 prefix is rarely valid)
            normalizedCode = String(normalizedCode.dropFirst())
            print("✂️ Removed leading zero from double-zero prefix: \(normalizedCode)")
        } else if normalizedCode.hasPrefix("0") {
            // Check if this is likely a UPC/EAN code with an extra zero
            if normalizedCode.count == 13 {
                // Standard UPC-A is 12 digits, so a 13-digit code with leading zero is likely an error
                normalizedCode = String(normalizedCode.dropFirst())
                print("✂️ Removed leading zero from 13-digit code: \(normalizedCode)")
            } else if normalizedCode.count == 14 {
                // Standard EAN-13 is 13 digits, so 14 with leading zero is likely an error
                normalizedCode = String(normalizedCode.dropFirst())
                print("✂️ Removed leading zero from 14-digit code: \(normalizedCode)")
            }
            // Special case: Many barcodes legitimately start with 0, so we're careful
            // If it's not 13 or 14 digits, leave the zero prefix
        }
        
        // Step 2: Check for known patterns and fix them
        // Match patterns for common medication barcodes
        
        // Pattern 1: UPC-A for common OTC medicines often have recognizable prefixes
        if normalizedCode.count == 12 {
            let prefix3 = normalizedCode.prefix(3)
            if ["300", "305", "311", "312", "350", "381", "041", "050"].contains(String(prefix3)) {
                // This is likely correct - common UPC medicine prefixes
                print("✅ Recognized standard UPC medicine prefix: \(prefix3)")
            }
        }
        
        // Pattern 2: NDC codes (often for prescription drugs)
        if normalizedCode.count == 10 || normalizedCode.count == 11 {
            if let reformatted = reformatNDC(normalizedCode) {
                print("🔄 Reformatted NDC code: \(reformatted)")
                // We don't actually change the code - just log the formatted version for API calls
            }
        }
        
        // Log final result
        print("✅ FINAL BARCODE: \(normalizedCode)")
        return normalizedCode
    }
    
    // Helper to format NDC codes with proper separators
    private static func reformatNDC(_ code: String) -> String? {
        if code.count == 11 {
            // 5-4-2 format
            return "\(code.prefix(5))-\(code.dropFirst(5).prefix(4))-\(code.suffix(2))"
        } else if code.count == 10 {
            // Could be 5-3-2 format
            return "\(code.prefix(5))-\(code.dropFirst(5).prefix(3))-\(code.suffix(2))"
        }
        return nil
    }
    
    static func detectBarcodeType(_ barcode: String) -> BarcodeType {
        let cleaned = barcode.filter { $0.isNumber }
        
        if cleaned.count == 10 || cleaned.count == 11 {
            // Check NDC patterns
            if cleaned.hasPrefix("05042") { // CVS brand
                return .ndc
            } else if cleaned.hasPrefix("3") || cleaned.hasPrefix("4") {
                return .ndc
            }
        }
        
        if cleaned.count == 12 {
            // UPC-A
            return .upc
        } else if cleaned.count == 13 {
            // EAN-13
            return .ean
        }
        
        return .unknown
    }
    
    // Format for specific API
    static func formatForAPI(_ barcode: String, type: BarcodeType) -> String {
        let cleaned = barcode.filter { $0.isNumber }
        
        switch type {
        case .ndc:
            // Format NDC code (various formats possible)
            if cleaned.count == 11 {
                // Try 5-4-2 format (most common for NDC)
                return "\(cleaned.prefix(5))-\(cleaned.dropFirst(5).prefix(4))-\(cleaned.suffix(2))"
            } else if cleaned.count == 10 {
                // Try 5-3-2 format
                return "\(cleaned.prefix(5))-\(cleaned.dropFirst(5).prefix(3))-\(cleaned.suffix(2))"
            }
            return cleaned
            
        case .upc, .ean, .unknown:
            return cleaned
        }
    }
    
    // For debugging - detect specific products
    static func isKnownProduct(_ barcode: String) -> (isKnown: Bool, productName: String) {
        let cleaned = barcode.filter { $0.isNumber }
        
        // Check for Claritin products
        if cleaned.hasSuffix("41100010174") {
            return (true, "Claritin 24-Hour Allergy Relief")
        } else if cleaned.hasSuffix("41100766613") {
            return (true, "Claritin 24-Hour Allergy Relief (30 tablets)")
        } else if cleaned.hasSuffix("41100010167") {
            return (true, "Claritin 24-Hour Allergy Relief (10 tablets)")
        } else if cleaned == "050428462701" || cleaned == "50428462701" {
            return (true, "CVS Health Allergy Relief Loratadine")
        }
        
        return (false, "")
    }
}

// Barcode types for API formatting
enum BarcodeType {
    case upc
    case ean
    case ndc
    case unknown
}

// MARK: - Alternative Barcode Scanner Options

/*
 If the built-in barcode scanner continues to have issues, consider:
 
 1. MTBBarcodeScanner - Popular iOS barcode scanner
    - GitHub: https://github.com/mikebuss/MTBBarcodeScanner
    - Installation via CocoaPods: pod 'MTBBarcodeScanner'
 
 2. EasyScanner - Simpler wrapper around AVFoundation
    - GitHub: https://github.com/muzipiao/EasyScanner
 
 3. ZXingObjC - Port of ZXing barcode library
    - GitHub: https://github.com/TheLevelUp/ZXingObjC
    - Installation via CocoaPods: pod 'ZXingObjC'
 
 Implementation example with ZXingObjC:
 
 ```swift
 import ZXingObjC
 
 class ZXingScanner: UIViewController, ZXCaptureDelegate {
     private var capture: ZXCapture!
     var resultCallback: ((String) -> Void)?
     
     override func viewDidLoad() {
         super.viewDidLoad()
         
         capture = ZXCapture()
         capture.delegate = self
         capture.layer.frame = view.bounds
         view.layer.addSublayer(capture.layer)
         
         capture.start()
     }
     
     func captureResult(_ capture: ZXCapture!, result: ZXResult!) {
         if let text = result.text {
             // Successfully scanned barcode
             resultCallback?(text)
         }
     }
 }
 ```
 */
