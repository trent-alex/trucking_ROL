import SwiftUI
import MapKit

struct RouteMapView: View {
    let polyline: MKPolyline
    let originCoordinate: CLLocationCoordinate2D
    let destinationCoordinate: CLLocationCoordinate2D

    @State private var position: MapCameraPosition = .automatic

    private var coordinates: [CLLocationCoordinate2D] {
        let points = polyline.points()
        return (0..<polyline.pointCount).map { points[$0].coordinate }
    }

    private var fitRegion: MKCoordinateRegion {
        let rect = polyline.boundingMapRect
        let padded = rect.insetBy(dx: -rect.size.width * 0.15, dy: -rect.size.height * 0.15)
        return MKCoordinateRegion(padded)
    }

    var body: some View {
        Map(position: $position, interactionModes: [.pan, .zoom]) {
            MapPolyline(coordinates: coordinates)
                .stroke(.blue, lineWidth: 5)

            Marker("Origin", systemImage: "figure.wave", coordinate: originCoordinate)
                .tint(.green)

            Marker("Destination", systemImage: "flag.fill", coordinate: destinationCoordinate)
                .tint(.red)
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onAppear {
            position = .region(fitRegion)
        }
    }
}
