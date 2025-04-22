//
//  AppDelegate.swift
//  AccessibleRoutes
//
//  Created by Артемий Андреев  on 02.04.2025.
//

import UIKit
import CoreLocation

class AppDelegate: NSObject, UIApplicationDelegate, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        return true
    }

    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            manager.startUpdatingLocation()
            manager.stopUpdatingLocation()
        }
    }
}
