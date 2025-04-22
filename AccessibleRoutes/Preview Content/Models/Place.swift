//
//  Place.swift
//  AccessibleRoutes
//
//  Created by Артемий Андреев  on 02.04.2025.
//

import Foundation
import CoreLocation
import MapKit

struct Place: Identifiable {
    let id = UUID()
    let name: String
    let address: String?
    let latitude: Double
    let longitude: Double

    var category: String?
    var distance: Double?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(mapItem: MKMapItem) {
        let placemark = mapItem.placemark
        self.name = mapItem.name ?? "Без имени"
        // Собираем адрес из компонентов
        let comps = [
            placemark.thoroughfare,
            placemark.subThoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country
        ]
        .compactMap { $0 }
        self.address = comps.joined(separator: ", ")
        let coord = placemark.coordinate
        self.latitude = coord.latitude
        self.longitude = coord.longitude

        self.category = nil
        self.distance = nil
    }
}
