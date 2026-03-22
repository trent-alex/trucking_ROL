import SwiftUI
import MapKit

struct ScenarioRouteMapView: View {
    let segments: [RouteSegment]

    @State private var position: MapCameraPosition = .automatic

    private var boundingRegion: MKCoordinateRegion? {
        var allCoords: [CLLocationCoordinate2D] = []
        for segment in segments {
            if let polyline = segment.routePolyline {
                let points = polyline.points()
                allCoords.append(contentsOf: (0..<polyline.pointCount).map { points[$0].coordinate })
            }
        }

        guard !allCoords.isEmpty else { return nil }

        var minLat = allCoords[0].latitude
        var maxLat = allCoords[0].latitude
        var minLon = allCoords[0].longitude
        var maxLon = allCoords[0].longitude

        for coord in allCoords {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
        )

        return MKCoordinateRegion(center: center, span: span)
    }

    // Pre-compute polyline data for MapContent
    private var polylineData: [(id: UUID, coordinates: [CLLocationCoordinate2D], isLoaded: Bool)] {
        segments.compactMap { segment in
            guard let polyline = segment.routePolyline else { return nil }
            let points = polyline.points()
            let coords = (0..<polyline.pointCount).map { points[$0].coordinate }
            return (id: segment.id, coordinates: coords, isLoaded: segment.segmentType.isLoaded)
        }
    }

    // Pre-compute marker data
    private var markerData: [(id: String, title: String, icon: String, coordinate: CLLocationCoordinate2D, color: Color)] {
        var markers: [(id: String, title: String, icon: String, coordinate: CLLocationCoordinate2D, color: Color)] = []

        // Start marker
        if let firstSegment = segments.first,
           let originCoord = firstSegment.originCoordinate {
            markers.append((id: "start", title: "Start", icon: "location.fill", coordinate: originCoord, color: .green))
        }

        // Intermediate and end markers
        for (index, segment) in segments.enumerated() {
            if let destCoord = segment.destinationCoordinate {
                if index == segments.count - 1 {
                    markers.append((id: "end", title: "End", icon: "flag.fill", coordinate: destCoord, color: .red))
                } else if segment.segmentType.isLoaded {
                    markers.append((id: "drop-\(index)", title: "Drop \(index + 1)", icon: "shippingbox.fill", coordinate: destCoord, color: .blue))
                }
            }
        }

        return markers
    }

    var body: some View {
        Map(position: $position, interactionModes: [.pan, .zoom]) {
            // Draw polylines
            ForEach(polylineData, id: \.id) { data in
                MapPolyline(coordinates: data.coordinates)
                    .stroke(data.isLoaded ? .blue : .gray, lineWidth: 4)
            }

            // Draw markers
            ForEach(markerData, id: \.id) { marker in
                Marker(marker.title, systemImage: marker.icon, coordinate: marker.coordinate)
                    .tint(marker.color)
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onAppear {
            if let region = boundingRegion {
                position = .region(region)
            }
        }
    }
}
