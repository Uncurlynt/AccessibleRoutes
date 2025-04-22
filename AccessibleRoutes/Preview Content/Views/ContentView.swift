//
//  ContentView.swift
//  AccessibleRoutes
//
//  Created by Артемий Андреев  on 01.04.2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var mapVM: MapViewModel
    @EnvironmentObject var nearbyVM: NearbyViewModel
    @EnvironmentObject var radarVM: RadarViewModel

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .environmentObject(mapVM)
                .tag(0)
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Карта")
                }

            NearbyView()
                .environmentObject(nearbyVM)
                .environmentObject(mapVM)
                .tag(1)
                .tabItem {
                    Image(systemName: "figure.walk.circle")
                    Text("Окрестности")
                }

            RadarView()
                .environmentObject(radarVM)
                .environmentObject(mapVM)
                .tag(2)
                .tabItem {
                    Image(systemName: "accessibility.badge.arrow.up.right")
                    Text("Радар")
                }
        }
        .accentColor(.blue)
                .onChange(of: selectedTab) { newValue, _ in
                    if newValue == 2 {
                        radarVM.targetCoordinate = mapVM.routeDestination?.coordinate
                    }
                }
            }
        }


#Preview {
    ContentView()
}
