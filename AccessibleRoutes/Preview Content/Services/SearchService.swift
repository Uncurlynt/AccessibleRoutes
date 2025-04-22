//
//  SearchService.swift
//  AccessibleRoutes
//
//  Created by Артемий Андреев  on 02.04.2025.
//

import Foundation
import MapKit
import CoreLocation

class SearchService {
    /// - Parameters:
    ///   - query: Текст запроса (адрес, название или категория).
    ///   - userLocation: Опционально: координаты для привязки поиска.
    ///   - resultsCount: Максимум результатов.
    ///   - completion: Callback с массивом Place или ошибкой.
    func search(query: String,
                around userLocation: CLLocationCoordinate2D? = nil,
                resultsCount: Int = 10,
                completion: @escaping (Result<[Place], Error>) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let loc = userLocation {
            // Радиус ~5 км
            request.region = MKCoordinateRegion(
                center: loc,
                latitudinalMeters: 5000,
                longitudinalMeters: 5000
            )
        }
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let err = error {
                completion(.failure(err))
                return
            }
            guard let mapItems = response?.mapItems else {
                completion(.success([]))
                return
            }
            let places = mapItems.prefix(resultsCount).map { Place(mapItem: $0) }
            completion(.success(Array(places)))
        }
    }
}
