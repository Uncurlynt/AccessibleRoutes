//
//  MapViewModel.swift
//  AccessibleRoutes
//
//  Created by Артемий Андреев on 02.04.2025.
//

import Foundation
import Combine
import CoreLocation
import MapKit
import UIKit

class MapViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    // Входные данные
    @Published var searchQuery: String = ""
    // Выходные данные
    @Published var searchResults: [Place] = []
    @Published var routeInfo: (distance: Double, duration: Double)? = nil
    @Published var routeDestination: Place? = nil

    private let searchService = SearchService()
    private var cancellables = Set<AnyCancellable>()
    let locationManager = CLLocationManager()

    weak var mapView: MKMapView?

    override init() {
        super.init()

        $searchQuery
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] q in self?.performSearch(query: q) }
            .store(in: &cancellables)

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    private func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchResults.removeAll()
            return
        }
        let userLoc = locationManager.location?.coordinate
        searchService.search(query: trimmed, around: userLoc, resultsCount: 10) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let places):
                    self?.searchResults = places
                    UIAccessibility.post(notification: .announcement,
                                         argument: places.isEmpty
                                            ? "Ничего не найдено"
                                            : "Обновлено результатов: \(places.count)")
                case .failure:
                    UIAccessibility.post(notification: .announcement,
                                         argument: "Ошибка соединения или поиска")
                }
            }
        }
    }

    func buildRoute(to place: Place) {
        routeDestination = place
        routeInfo = nil

        // Проверяем, что карта уже привязана
        guard mapView != nil else {
            UIAccessibility.post(notification: .announcement,
                                 argument: "Карта ещё не готова")
            return
        }
        // Проверяем геолокацию
        guard let userLoc = locationManager.location else {
            locationManager.requestLocation()
            UIAccessibility.post(notification: .announcement,
                                 argument: "Не удалось определить вашу позицию")
            return
        }

        let startCoord = userLoc.coordinate
        let endCoord = place.coordinate

        // Формируем запрос маршрута
        let req = MKDirections.Request()
        req.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoord))
        req.destination = MKMapItem(placemark: MKPlacemark(coordinate: endCoord))
        req.transportType = .automobile

        let directions = MKDirections(request: req)
        directions.calculate { [weak self] response, error in
            guard let self = self, let route = response?.routes.first else {
                DispatchQueue.main.async {
                    UIAccessibility.post(notification: .announcement,
                                         argument: "Не удалось проложить маршрут")
                }
                return
            }
            self.showRouteOnMap(route: route, start: startCoord, end: endCoord, name: place.name)
            DispatchQueue.main.async {
                self.routeInfo = (distance: route.distance,
                                  duration: route.expectedTravelTime)
                let distStr = self.formatDistance(meters: route.distance)
                let timeStr = self.formatTime(seconds: route.expectedTravelTime)
                UIAccessibility.post(notification: .announcement,
                                     argument: "Маршрут построен. Расстояние \(distStr), время \(timeStr).")
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    private func showRouteOnMap(route: MKRoute,
                                start: CLLocationCoordinate2D,
                                end: CLLocationCoordinate2D,
                                name: String) {
        guard let mapView = mapView else { return }

        // Удаляем старые оверлеи и аннотации (кроме пользователя)
        let toRemoveAnns = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(toRemoveAnns)
        mapView.removeOverlays(mapView.overlays)

        // Добавляем линию маршрута
        mapView.addOverlay(route.polyline)
        mapView.setVisibleMapRect(route.polyline.boundingMapRect,
                                  edgePadding: UIEdgeInsets(top: 80, left: 40, bottom: 150, right: 40),
                                  animated: true)

        let startAnn = MKPointAnnotation()
        startAnn.coordinate = start
        startAnn.title = "Точка отправления"
        mapView.addAnnotation(startAnn)

        let endAnn = MKPointAnnotation()
        endAnn.coordinate = end
        endAnn.title = name
        mapView.addAnnotation(endAnn)
    }

    // MARK: Форматирование
    private func formatDistance(meters: Double) -> String {
        meters >= 1000
            ? String(format: "%.1f км", meters/1000)
            : "\(Int(meters)) м"
    }
    private func formatTime(seconds: TimeInterval) -> String {
        let mins = Int(seconds/60)
        if mins < 60 {
            return "\(mins) мин"
        } else {
            return "\(mins/60) ч \(mins%60) мин"
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager error: \(error)")
    }
}
