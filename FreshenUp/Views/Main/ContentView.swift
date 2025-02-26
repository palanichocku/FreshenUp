//
//  ContentView.swift
//  FreshenUp
//
//  Created by Palam Chocku on 2/25/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Screen - Main Catalog View
            NavigationView {
                MedicationCatalogView()
                    .navigationTitle("FreshenUp")
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Scanner View
            NavigationView {
                ScannerView()
                    .navigationTitle("Scanner")
            }
            .tabItem {
                Label("Scan", systemImage: "barcode.viewfinder")
            }
            .tag(1)
            
            // Reports View
            NavigationView {
                ReportsView()
                    .navigationTitle("Reports")
            }
            .tabItem {
                Label("Reports", systemImage: "doc.text.fill")
            }
            .tag(2)
            
            // Settings View
            NavigationView {
                SettingsView()
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
        .accentColor(.blue)
    }
}
