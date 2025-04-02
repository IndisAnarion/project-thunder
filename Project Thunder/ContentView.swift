//
//  ContentView.swift
//  Project Thunder
//
//  Created by Enes Danyıldız (02483932) on 7.03.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var localizationManager = LocalizationManager.shared
    @State private var refreshView = UUID()
    
    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    AuthenticationView()
                        .environmentObject(localizationManager)
                        .id(refreshView) // Force view refresh on language change
                    
                    // Sağ üst köşede dil seçimi
                    VStack {
                        HStack {
                            Spacer()
                            
                            Menu {
                                Button(action: { 
                                    localizationManager.currentLanguage = "en"
                                    refreshView = UUID() // Force refresh
                                }) {
                                    Label("English", systemImage: "en".lowercased() == localizationManager.currentLanguage ? "checkmark" : "")
                                }
                                
                                Button(action: { 
                                    localizationManager.currentLanguage = "tr"
                                    refreshView = UUID() // Force refresh
                                }) {
                                    Label("Türkçe", systemImage: "tr".lowercased() == localizationManager.currentLanguage ? "checkmark" : "")
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Text(localizationManager.currentLanguage.uppercased())
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                    
                                    Image(systemName: "globe")
                                        .font(.caption)
                                }
                                .foregroundColor(Color("ThemePrimary"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color("ThemePrimary"), lineWidth: 1)
                                        .background(Color("ThemePrimary").opacity(0.1).cornerRadius(8))
                                )
                            }
                            .padding(.trailing)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 10)
                }
            }
        }
        .environmentObject(localizationManager)
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            // Force view update
            refreshView = UUID()
        }
    }
}

#Preview {
    ContentView()
}
