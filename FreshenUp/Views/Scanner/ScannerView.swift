import SwiftUI

struct ScannerView: View {
    // Use a StateObject properly attached to this view
    @StateObject private var viewModel = BarcodeScannerViewModel()
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var viewContext
    
    var body: some View {
        VStack {
            if viewModel.isScanning {
                // Camera Scanner View
                ZStack {
                    BarcodeScannerView(
                        scannedCode: $viewModel.scannedBarcode,
                        isScanningActive: $viewModel.isScanning
                    )
                    
                    // Camera overlay with scanning indicator
                    VStack {
                        Spacer()
                        
                        if viewModel.isProcessing {
                            // Show processing indicator when looking up a barcode
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(10)
                        } else {
                            // Show regular scanning guide
                            Text("Center barcode in frame")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(10)
                        }
                        
                        Spacer().frame(height: 100)
                    }
                }
                .frame(height: 400)
                
                Button("Enter code manually") {
                    viewModel.isScanning = false
                }
                .padding()
                .foregroundColor(.blue)
            } else {
                // Manual Input View
                VStack(spacing: 20) {
                    Text("Enter Barcode Manually")
                        .font(.headline)
                    
                    Text("Most drug barcodes in the US are either 10-digit NDC codes or 12-digit UPC codes")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    TextField("Enter barcode numbers", text: $viewModel.scannedBarcode)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .onSubmit {
                            // Process barcode when user submits (presses return)
                            viewModel.processBarcode()
                        }
                    
                    // Auto-process note instead of button
                    Text("Barcode will be processed automatically")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top)
                    
                    if viewModel.isProcessing {
                        // Show processing indicator
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    }
                    
                    Button("Back to Scanner") {
                        viewModel.isScanning = true
                    }
                    .foregroundColor(.blue)
                    .padding()
                    .disabled(viewModel.isProcessing)
                }
                .padding()
                .onChange(of: viewModel.scannedBarcode) { newValue in
                    // Automatically process when entering a barcode manually after small delay
                    if !newValue.isEmpty && viewModel.isValidBarcodeFormat(newValue) {
                        // Debounce the lookup with a small delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if newValue == viewModel.scannedBarcode { // Ensure value hasn't changed
                                viewModel.processBarcode()
                            }
                        }
                    }
                }
            }
        }
        .alert(item: $viewModel.alertMessage) { message in
            Alert(
                title: Text("Barcode Error"),
                message: Text(message.content),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $viewModel.showMedicationInfo) {
            if let info = viewModel.medicationInfo {
                // Pass the managed object context to the info view
                MedicationInfoView(
                    info: info,
                    onSave: {
                        // Called after save completes successfully
                        viewModel.resetScanner()
                    },
                    onCancel: {
                        // Called when user cancels
                        viewModel.resetScanner()
                    }
                )
                .environment(\.managedObjectContext, viewContext)
                .onDisappear {
                    // Safety fallback - ensure view model is reset if sheet is dismissed by swipe
                    if viewModel.showMedicationInfo {
                        viewModel.resetScanner()
                    }
                }
            }
        }
        .onChange(of: viewModel.scannedBarcode) { newValue in
            // Only process when scanning (not manual entry) and valid format
            if !newValue.isEmpty && viewModel.isScanning && viewModel.isValidBarcodeFormat(newValue) {
                print("Automatically processing scanned barcode: \(newValue)")
                viewModel.processBarcode(automaticLookup: true)
            }
        }
    }
}
