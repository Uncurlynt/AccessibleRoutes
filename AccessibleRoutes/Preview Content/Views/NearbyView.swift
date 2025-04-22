//
//  NearbyView.swift
//  AccessibleRoutes
//
//  Created by Артемий Андреев  on 02.04.2025.
//

import SwiftUI

struct NearbyView: View {
    @EnvironmentObject var viewModel: NearbyViewModel
    @EnvironmentObject var mapViewModel: MapViewModel

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Окрестности")
                    .font(.headline)
                    .padding(.top, 16)
                    .padding(.leading, 16)

                if viewModel.isLoading {
                    Spacer()
                    Text("Загрузка ближайших объектов...")
                        .foregroundColor(.gray)
                        .padding()
                        .accessibilityLabel("Загрузка объектов")
                    Spacer()
                } else if viewModel.nearbyPlaces.isEmpty {
                    Spacer()
                    Text("Поблизости ничего не найдено")
                        .foregroundColor(.secondary)
                        .padding()
                        .accessibilityLabel("Поблизости ничего не найдено")
                    Spacer()
                } else {
                    List(viewModel.nearbyPlaces) { place in
                        NearbyRow(place: place) {
                            mapViewModel.buildRoute(to: place)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationBarTitle("Окрестности", displayMode: .inline)
            .onAppear {
                viewModel.loadNearbyPlaces()
            }
        }
    }
}

struct NearbyRow: View {
    let place: Place
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        HStack {
            Image(systemName: iconName(for: place.category))
                .foregroundColor(.blue)
                .imageScale(.large)
                .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Text("\(place.category ?? ""): \(place.name)")
                    .bold()
                if let dist = place.distance {
                    Text("\(formatDistance(dist)) от вас")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onTapGesture {
            isPressed = true
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isPressed = false
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Двойной тап – проложить маршрут на карте")
        .accessibilityAction(named: Text("Проложить маршрут")) {
            action()
        }
    }

    // MARK: Вспомогательные
    private func iconName(for category: String?) -> String {
        switch category {
        case "Кафе":     return "cup.and.saucer.fill"
        case "Аптека":   return "cross.case.fill"
        case "Остановка":return "bus.fill"
        default:         return "mappin.and.ellipse"
        }
    }

    private func formatDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.1f км", meters / 1000)
        } else {
            return "\(Int(meters)) м"
        }
    }
}
