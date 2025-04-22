//
//  AccessibleRoutesApp.swift
//  AccessibleRoutes
//
//  Created by Артемий Андреев  on 01.04.2025.
//

import SwiftUI

@main
struct AccessibleRoutesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, Locale(identifier: "ru"))
                .environmentObject(MapViewModel())
                .environmentObject(NearbyViewModel())
                .environmentObject(RadarViewModel())
        }
    }
}
