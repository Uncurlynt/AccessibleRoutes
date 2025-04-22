//
//  RadarView.swift
//  AccessibleRoutes
//
//  Created by Артемий Андреев  on 02.04.2025.
//

import SwiftUI
import CoreLocation

struct RadarView: View {
    @EnvironmentObject var viewModel: RadarViewModel
    @EnvironmentObject var mapViewModel: MapViewModel

    @State private var isActive = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Радар")
                .font(.largeTitle)
                .bold()

            ZStack {
                // Фоновой круг‑компас
                Circle()
                    .stroke(lineWidth: 2)
                    .frame(width: 200, height: 200)

                // Кольцевой прогресс‑бар расстояния
                Circle()
                    .trim(from: 0, to: CGFloat(viewModel.progress))
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                    .foregroundColor(
                        viewModel.progress > 0.75 ? .green :
                        viewModel.progress > 0.4  ? .yellow :
                                                   .red
                    )

                // Стрелка‑указатель
                Image(systemName: "location.north.fill")
                    .resizable()
                    .frame(width: 30, height: 90)
                    .offset(y: -10)
                    .rotationEffect(.degrees(viewModel.bearing))
                    .animation(.easeInOut, value: viewModel.bearing)
            }

            Text(viewModel.statusText)
                .foregroundColor(isActive ? .green : .secondary)
            Text("Расстояние: \(viewModel.distanceText)")
                .font(.title3)
            Text("ETA: \(viewModel.etaText)")
                .font(.subheadline)

            Spacer()

            Button(action: toggleRadar) {
                HStack {
                    Image(systemName: isActive
                          ? "stop.fill"
                          : "antenna.radiowaves.left.and.right")
                    Text(isActive ? "Остановить радар" : "Запустить радар")
                }
                .padding()
                .foregroundColor(.white)
                .background(isActive ? Color.red : Color.blue)
                .cornerRadius(8)
            }
            .accessibilityLabel(isActive ? "Остановить радар" : "Запустить радар")
            .padding(.bottom, 40)
        }
        .padding()
        .onDisappear {
            if isActive { toggleRadar() }
        }
    }

    private func toggleRadar() {
        if !isActive {
            viewModel.startRadar()
        } else {
            viewModel.stopRadar()
        }
        isActive.toggle()
    }
}
