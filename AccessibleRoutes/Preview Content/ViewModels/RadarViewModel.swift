//
//  RadarViewModel.swift
//  AccessibleRoutes
//
//  Created by Артемий Андреев  on 02.04.2025.
//

import Foundation
import UIKit
import AVFoundation
import CoreLocation
import Combine

class RadarViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    var targetCoordinate: CLLocationCoordinate2D? {
        didSet {
            if let c = targetCoordinate {
                targetLocation = CLLocation(latitude: c.latitude, longitude: c.longitude)
            } else {
                targetLocation = nil
            }
        }
    }
    private var targetLocation: CLLocation?

    // MARK: Паблишеры для View
    @Published var statusText: String = "Радар не активен"
    @Published var distanceText: String = "-- м"
    @Published var bearing: Double = 0
    @Published var progress: Double = 0
    @Published var etaText: String = "--:--"

    // Менеджер локации/компаса
    private let locationManager = CLLocationManager()

    // Звук
    private var audioPlayer: AVAudioPlayer?
    private var beepTimer: Timer?

    // Вибро
    private var lastAlignment: Bool = false

    // Максимальная дистанция для прогресса (1 км)
    private let maxDistance: Double = 1000

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.headingFilter = 1
    }

    func startRadar() {
        guard targetLocation != nil else {
            statusText = "Цель не задана"
            return
        }
        statusText = "Радар запущен"
        setupAudio()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        UIAccessibility.post(notification: .announcement,
                             argument: "Радар активен. Поворачивайте телефон для поиска.")
    }

    func stopRadar() {
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
        beepTimer?.invalidate()
        audioPlayer?.stop()
        statusText = "Радар остановлен"
    }

    private func setupAudio() {
        guard let url = Bundle.main.url(forResource: "beep", withExtension: "wav") else { return }
        audioPlayer = try? AVAudioPlayer(contentsOf: url)
        audioPlayer?.numberOfLoops = 0
        audioPlayer?.prepareToPlay()
    }

    private func scheduleBeep(interval: TimeInterval) {
        beepTimer?.invalidate()
        beepTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            self?.playBeep()
        }
    }

    private func playBeep() {
        audioPlayer?.play()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.audioPlayer?.stop()
        }
    }

    // CLLocationManagerDelegate — обновление компаса
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard let target = targetLocation,
              let current = manager.location else { return }

        // Текущий heading и азимут на цель
        let heading = newHeading.magneticHeading
        let bearingDeg = bearingBetween(start: current.coordinate, end: target.coordinate)
        let diff = angleDifference(bearingDeg, heading)

        // Расстояние
        let distance = current.distance(from: target)
        // Прогресс: 1 при 0 м, 0 при >= maxDistance
        let prog = 1 - min(distance / maxDistance, 1)

        // ETA (пешком ~1.4 м/с)
        let etaSec = distance / 1.4

        DispatchQueue.main.async {
            self.bearing = bearingDeg - heading
            self.distanceText = self.formatDistance(meters: distance)
            self.progress = prog
            self.etaText = self.formatTime(seconds: etaSec)
        }

        // Звук: частота бипов зависит от отклонения
        let absDiff = abs(diff)
        let interval = max(0.1, absDiff / 180) // от 0.1 до 1.0 с
        scheduleBeep(interval: interval)

        // Вибрация при точном наведении (±5°)
        if absDiff < 5 {
            if !lastAlignment {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                lastAlignment = true
            }
        } else {
            lastAlignment = false
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Compass error: \(error)")
    }

    // MARK: Вспомогательные
    private func bearingBetween(start: CLLocationCoordinate2D,
                                end: CLLocationCoordinate2D) -> Double {
        let lat1 = start.latitude.toRadians()
        let lon1 = start.longitude.toRadians()
        let lat2 = end.latitude.toRadians()
        let lon2 = end.longitude.toRadians()
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2)
            - sin(lat1) * cos(lat2) * cos(dLon)
        let brng = atan2(y, x).toDegrees()
        return brng < 0 ? brng + 360 : brng
    }

    private func angleDifference(_ bearing: Double, _ heading: Double) -> Double {
        var diff = bearing - heading
        if diff > 180 { diff -= 360 }
        if diff < -180 { diff += 360 }
        return diff
    }

    private func formatDistance(meters: CLLocationDistance) -> String {
        meters >= 1000
            ? String(format: "%.1f км", meters/1000)
            : "\(Int(meters)) м"
    }

    private func formatTime(seconds: TimeInterval) -> String {
        let mins = Int(seconds / 60)
        if mins < 60 {
            return "\(mins) мин"
        } else {
            let h = mins / 60
            let m = mins % 60
            return "\(h) ч \(m) мин"
        }
    }
}

fileprivate extension Double {
    func toRadians() -> Double { self * .pi / 180 }
    func toDegrees() -> Double { self * 180 / .pi }
}
