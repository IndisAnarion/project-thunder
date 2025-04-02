//
//  Project_ThunderApp.swift
//  Project Thunder
//
//  Created by Enes Danyıldız (02483932) on 7.03.2025.
//

import SwiftUI

@main
struct Project_ThunderApp: App {
    @StateObject private var localizationManager = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(localizationManager)
        }
    }
}
