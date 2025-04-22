//
//  MapView.swift
//  AccessibleRoutes
//
//  Created by Артемий Андреев  on 02.04.2025.
//

import SwiftUI

struct MapView: View {
    @EnvironmentObject var viewModel: MapViewModel

    var body: some View {
        NavigationView {
            ZStack {
                MapViewRepresentable()
                    .ignoresSafeArea(edges: .top)

                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Поиск места или адреса", text: $viewModel.searchQuery)
                            .accessibilityLabel("Поиск места")
                            .accessibilityHint("Ввод адреса или названия, результаты ниже")
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disableAutocorrection(true)
                    }
                    .padding(.all, 8)
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(10)
                    .padding([.top, .horizontal], 16)
                    .accessibilityElement(children: .combine)

                    // Список результатов поиска
                    if !viewModel.searchResults.isEmpty {
                        List(viewModel.searchResults) { place in
                            VStack(alignment: .leading) {
                                if let addr = place.address, !addr.isEmpty {
                                    Text("\(place.name) — \(addr)")
                                        .lineLimit(3)
                                        .accessibilityLabel("\(place.name). \(addr)")
                                } else {
                                    Text(place.name)
                                        .accessibilityLabel(place.name)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.buildRoute(to: place)
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                viewModel.searchResults = []
                            }
                            .accessibilityAddTraits(.isButton)
                            .accessibilityHint("Двойной тап – проложить маршрут")
                        }
                        .frame(maxHeight: 250)
                        .background(Color(.systemBackground).opacity(0.9))
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                        .accessibilityRotor("Результаты поиска") {
                            ForEach(viewModel.searchResults) { place in
                                AccessibilityRotorEntry(place.name, id: place.id)
                            }
                        }
                    }

                    Spacer()

                    // Если есть активный маршрут – отображаем информационную плашку
                    if let route = viewModel.routeInfo, let destination = viewModel.routeDestination {
                        RouteInfoBar(route: route, destinationName: destination.name)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitle("Карта", displayMode: .inline)
            .navigationBarHidden(true)
        }
    }
}

// Дополнительное представление: информационная панель маршрута
struct RouteInfoBar: View {
    let route: (distance: Double, duration: Double)
    let destinationName: String

    var body: some View {
        let distanceStr = route.distance >= 1000 ? String(format: "%.1f км", route.distance/1000) : "\(Int(route.distance)) м"
        let minutes = Int(route.duration / 60)
        let durationStr = minutes < 60 ? "\(minutes) мин" : "\(minutes/60) ч \(minutes % 60) мин"

        return HStack {
            Image(systemName: "location.fill")
                .foregroundColor(.white)
            Text("\(destinationName): \(distanceStr), \(durationStr)")
                .foregroundColor(.white)
                .bold()
                .lineLimit(2)
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Маршрут до \(destinationName), расстояние \(distanceStr), время \(durationStr)")
    }
}
