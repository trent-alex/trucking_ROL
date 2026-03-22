import Foundation
import CoreLocation
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var currentAddress: String?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocating: Bool = false
    @Published var error: String?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = manager.authorizationStatus
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestCurrentLocation() {
        error = nil

        guard isAuthorized else {
            requestPermission()
            return
        }

        isLocating = true
        manager.requestLocation()
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLocating = false

                if let error = error {
                    self.error = error.localizedDescription
                    return
                }

                guard let placemark = placemarks?.first else {
                    self.error = "Could not determine address"
                    return
                }

                // Build address string
                var components: [String] = []

                if let street = placemark.thoroughfare {
                    if let number = placemark.subThoroughfare {
                        components.append("\(number) \(street)")
                    } else {
                        components.append(street)
                    }
                }

                if let city = placemark.locality {
                    components.append(city)
                }

                if let state = placemark.administrativeArea {
                    components.append(state)
                }

                if let zip = placemark.postalCode {
                    components.append(zip)
                }

                self.currentAddress = components.joined(separator: ", ")
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.currentLocation = location
            self.reverseGeocode(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.isLocating = false
            self.error = error.localizedDescription
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus

            // Auto-request location if just authorized
            if self.isAuthorized && self.isLocating {
                manager.requestLocation()
            }
        }
    }
}
