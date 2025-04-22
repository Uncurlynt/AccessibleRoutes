//
//  NearbyViewModel.swift
//  AccessibleRoutes
//
//  Created by Артемий Андреев  on 02.04.2025.
//

import Foundation
import UIKit
import AVFoundation
import CoreLocation
import Combine

class NearbyViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var nearbyPlaces: [Place] = []
    @Published var isLoading: Bool = false

    private let locationManager = CLLocationManager()
    private let searchService   = SearchService()

    private let categories: [(query: String, name: String)] = [
        ("Кафе",     "Кафе"),
        ("Аптека",   "Аптека"),
        ("Остановка","Остановка")
    ]

    override init() {
        super.init()
        locationManager.delegate        = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func loadNearbyPlaces() {
        let status = locationManager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            locationManager.requestWhenInUseAuthorization()
            return
        }

        isLoading = true
        if let coord = locationManager.location?.coordinate {
            fetchNearby(for: coord)
        } else {
            locationManager.requestLocation()
        }
    }

    // Обрабатываем изменение авторизации и повторяем запрос
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            loadNearbyPlaces()
        }
    }

    private func fetchNearby(for coordinate: CLLocationCoordinate2D) {
        var fetchedPlaces: [Place] = []
        let group = DispatchGroup()

        for (query, categoryName) in categories {
            group.enter()
            searchService.search(query: query, around: coordinate, resultsCount: 1) { result in
                if case .success(let places) = result, let place = places.first {
                    var copy = place
                    copy.category = categoryName
                    let userLoc  = CLLocation(latitude: coordinate.latitude,
                                              longitude: coordinate.longitude)
                    let placeLoc = CLLocation(latitude: place.latitude,
                                              longitude: place.longitude)
                    copy.distance = userLoc.distance(from: placeLoc)
                    fetchedPlaces.append(copy)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            fetchedPlaces.sort { ($0.distance ?? 0) < ($1.distance ?? 0) }
            self.nearbyPlaces = fetchedPlaces
            self.isLoading = false
            UIAccessibility.post(notification: .announcement,
                                 argument: "Объекты поблизости обновлены")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        if let coord = locations.last?.coordinate {
            fetchNearby(for: coord)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Nearby location error: \(error.localizedDescription)")
        isLoading = false
    }
}
