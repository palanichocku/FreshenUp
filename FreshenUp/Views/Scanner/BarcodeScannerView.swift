//
//  BarcodeScannerView.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - Barcode Scanner View
struct BarcodeScannerView: UIViewRepresentable {
    @Binding var scannedCode: String
    @Binding var isScanningActive: Bool
    
    // Delegates and coordinators
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    // Setup the AV capture session in UIKit
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let captureSession = AVCaptureSession()
        
        // Setup the capture device
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return view }
        
        // Setup the input
        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else { return view }
        
        // Add input to session
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return view
        }
        
        // Setup the metadata output
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            // Set delegate to process captured metadata
            metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [
                .ean8,
                .ean13,
                .pdf417,
                .qr,
                .code39,
                .code128,
                .code39Mod43,
                .upce
            ]
        } else {
            return view
        }
        
        // Setup the preview layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        // Store the session in coordinator for lifecycle management
        context.coordinator.captureSession = captureSession
        
        // Start capture session in background
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }
        
        return view
    }
    
    // Configure AVCaptureSession with optimal barcode scanning settings
    func configureCaptureSession(_ captureSession: AVCaptureSession) {
        // Set high resolution preset for better scanning
        if captureSession.canSetSessionPreset(.high) {
            captureSession.sessionPreset = .high
        }
        
        // Configure metadata output for better barcode recognition
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            // Set comprehensive barcode types
            metadataOutput.metadataObjectTypes = [
                .ean8,
                .ean13,
                .pdf417,
                .qr,
                .code39,
                .code93,
                .code128,
                .code39Mod43,
                .upce,
                .interleaved2of5
            ]
            
            // Set scan rect to center of screen for better accuracy
            metadataOutput.rectOfInterest = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
            
            print("Barcode scanner configured with extended symbologies")
        }
    }
    
    // Handle view updates
    func updateUIView(_ uiView: UIView, context: Context) {
        // Handle active/inactive scanning
        if let captureSession = context.coordinator.captureSession {
            if isScanningActive && !captureSession.isRunning {
                DispatchQueue.global(qos: .userInitiated).async {
                    captureSession.startRunning()
                }
            } else if !isScanningActive && captureSession.isRunning {
                captureSession.stopRunning()
            }
        }
        
        // Update preview layer frame
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.layer.bounds
        }
    }
    
    // Coordinator to bridge UIKit and SwiftUI
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: BarcodeScannerView
        var captureSession: AVCaptureSession?
        
        init(_ parent: BarcodeScannerView) {
            self.parent = parent
        }
        
        // Process scanned metadata objects (barcodes)
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                
                // Emit a haptic feedback
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                
                // Pass the scanned code to the binding
                parent.scannedCode = stringValue
                
                // Pause scanning temporarily
                parent.isScanningActive = false
            }
        }
    }
}
