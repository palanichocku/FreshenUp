//
//  Untitled.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cross.case.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.blue)
                .padding()
            
            Text("FreshenUp")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Version 1.0")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("FreshenUp helps you keep track of your medications and their expiration dates. Scan barcodes to quickly add items to your catalog, get timely reminders about expiring medications, and generate comprehensive reports of your medicine inventory.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
            Text("© 2025 FreshenUp Developer")
                .font(.caption)
                .foregroundColor(.gray)
                .padding()
        }
        .padding()
    }
}
