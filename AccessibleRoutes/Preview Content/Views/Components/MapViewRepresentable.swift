//
//  MapViewRepresentable.swift
//  AccessibleRoutes
//
//  Created by Артемий Андреев  on 02.04.2025.
//

import SwiftUI
import UIKit
import MapKit
import CoreLocation

struct MapViewRepresentable: UIViewRepresentable {
    @EnvironmentObject var viewModel: MapViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow

        if let loc = viewModel.locationManager.location?.coordinate {
            mapView.setRegion(
                MKCoordinateRegion(center: loc, latitudinalMeters: 1000, longitudinalMeters: 1000),
                animated: false
            )
        } else {

            let moscow = CLLocationCoordinate2D(latitude: 55.751244, longitude: 37.618423)
            mapView.setRegion(
                MKCoordinateRegion(center: moscow, latitudinalMeters: 10000, longitudinalMeters: 10000),
                animated: false
            )
        }

        viewModel.mapView = mapView
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {

    }

    class Coordinator: NSObject, MKMapViewDelegate {
        let viewModel: MapViewModel

        init(viewModel: MapViewModel) {
            self.viewModel = viewModel
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let poly = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: poly)
                r.lineWidth = 5
                r.strokeColor = .systemBlue
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
