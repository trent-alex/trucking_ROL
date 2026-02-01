import Foundation
import MapKit

struct Route: Identifiable {
    let id = UUID()
    var origin: String
    var destination: String
    var distanceMiles: Double
    var statesTraversed: [String]
    var routePolyline: MKPolyline?
    var originCoordinate: CLLocationCoordinate2D?
    var destinationCoordinate: CLLocationCoordinate2D?
}
