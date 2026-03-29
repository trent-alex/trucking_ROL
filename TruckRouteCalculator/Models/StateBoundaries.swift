import Foundation
import CoreLocation

/// State boundary data for offline coordinate lookup
struct StateBoundary {
    let code: String
    let name: String
    let boundingBox: (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double)
    let polygon: [CLLocationCoordinate2D]
}

/// Continental US state boundaries (Lower 48)
/// Simplified polygons with 10-20 vertices for performance
struct StateBoundaries {

    static let all: [StateBoundary] = [
        // ALABAMA
        StateBoundary(
            code: "AL", name: "Alabama",
            boundingBox: (30.22, 35.01, -88.47, -84.89),
            polygon: [
                CLLocationCoordinate2D(latitude: 35.00, longitude: -88.20),
                CLLocationCoordinate2D(latitude: 34.99, longitude: -85.61),
                CLLocationCoordinate2D(latitude: 32.84, longitude: -85.18),
                CLLocationCoordinate2D(latitude: 32.15, longitude: -84.90),
                CLLocationCoordinate2D(latitude: 31.00, longitude: -85.00),
                CLLocationCoordinate2D(latitude: 30.25, longitude: -87.60),
                CLLocationCoordinate2D(latitude: 30.99, longitude: -88.01),
                CLLocationCoordinate2D(latitude: 34.89, longitude: -88.47),
                CLLocationCoordinate2D(latitude: 35.00, longitude: -88.20)
            ]
        ),

        // ARIZONA
        StateBoundary(
            code: "AZ", name: "Arizona",
            boundingBox: (31.33, 37.00, -114.82, -109.04),
            polygon: [
                CLLocationCoordinate2D(latitude: 37.00, longitude: -114.05),
                CLLocationCoordinate2D(latitude: 37.00, longitude: -109.04),
                CLLocationCoordinate2D(latitude: 31.33, longitude: -109.05),
                CLLocationCoordinate2D(latitude: 31.34, longitude: -111.07),
                CLLocationCoordinate2D(latitude: 32.49, longitude: -114.81),
                CLLocationCoordinate2D(latitude: 36.14, longitude: -114.75),
                CLLocationCoordinate2D(latitude: 36.00, longitude: -114.05),
                CLLocationCoordinate2D(latitude: 37.00, longitude: -114.05)
            ]
        ),

        // ARKANSAS
        StateBoundary(
            code: "AR", name: "Arkansas",
            boundingBox: (33.00, 36.50, -94.62, -89.64),
            polygon: [
                CLLocationCoordinate2D(latitude: 36.50, longitude: -94.62),
                CLLocationCoordinate2D(latitude: 36.50, longitude: -89.73),
                CLLocationCoordinate2D(latitude: 35.00, longitude: -90.37),
                CLLocationCoordinate2D(latitude: 33.00, longitude: -91.17),
                CLLocationCoordinate2D(latitude: 33.00, longitude: -94.04),
                CLLocationCoordinate2D(latitude: 33.68, longitude: -94.48),
                CLLocationCoordinate2D(latitude: 36.50, longitude: -94.62)
            ]
        ),

        // CALIFORNIA
        StateBoundary(
            code: "CA", name: "California",
            boundingBox: (32.53, 42.01, -124.48, -114.13),
            polygon: [
                CLLocationCoordinate2D(latitude: 42.00, longitude: -124.21),
                CLLocationCoordinate2D(latitude: 42.00, longitude: -120.00),
                CLLocationCoordinate2D(latitude: 39.00, longitude: -120.00),
                CLLocationCoordinate2D(latitude: 35.00, longitude: -114.63),
                CLLocationCoordinate2D(latitude: 34.45, longitude: -114.13),
                CLLocationCoordinate2D(latitude: 32.72, longitude: -114.72),
                CLLocationCoordinate2D(latitude: 32.53, longitude: -117.12),
                CLLocationCoordinate2D(latitude: 33.85, longitude: -118.41),
                CLLocationCoordinate2D(latitude: 34.45, longitude: -120.47),
                CLLocationCoordinate2D(latitude: 35.79, longitude: -121.29),
                CLLocationCoordinate2D(latitude: 37.77, longitude: -122.51),
                CLLocationCoordinate2D(latitude: 38.91, longitude: -123.73),
                CLLocationCoordinate2D(latitude: 40.44, longitude: -124.41),
                CLLocationCoordinate2D(latitude: 42.00, longitude: -124.21)
            ]
        ),

        // COLORADO
        StateBoundary(
            code: "CO", name: "Colorado",
            boundingBox: (36.99, 41.00, -109.05, -102.04),
            polygon: [
                CLLocationCoordinate2D(latitude: 41.00, longitude: -109.05),
                CLLocationCoordinate2D(latitude: 41.00, longitude: -102.04),
                CLLocationCoordinate2D(latitude: 37.00, longitude: -102.04),
                CLLocationCoordinate2D(latitude: 37.00, longitude: -109.05),
                CLLocationCoordinate2D(latitude: 41.00, longitude: -109.05)
            ]
        ),

        // CONNECTICUT
        StateBoundary(
            code: "CT", name: "Connecticut",
            boundingBox: (40.98, 42.05, -73.73, -71.79),
            polygon: [
                CLLocationCoordinate2D(latitude: 42.05, longitude: -73.49),
                CLLocationCoordinate2D(latitude: 42.03, longitude: -71.80),
                CLLocationCoordinate2D(latitude: 41.02, longitude: -71.79),
                CLLocationCoordinate2D(latitude: 40.98, longitude: -73.65),
                CLLocationCoordinate2D(latitude: 41.21, longitude: -73.73),
                CLLocationCoordinate2D(latitude: 42.05, longitude: -73.49)
            ]
        ),

        // DELAWARE
        StateBoundary(
            code: "DE", name: "Delaware",
            boundingBox: (38.45, 39.84, -75.79, -75.05),
            polygon: [
                CLLocationCoordinate2D(latitude: 39.84, longitude: -75.79),
                CLLocationCoordinate2D(latitude: 39.72, longitude: -75.05),
                CLLocationCoordinate2D(latitude: 38.45, longitude: -75.07),
                CLLocationCoordinate2D(latitude: 38.45, longitude: -75.69),
                CLLocationCoordinate2D(latitude: 39.84, longitude: -75.79)
            ]
        ),

        // FLORIDA
        StateBoundary(
            code: "FL", name: "Florida",
            boundingBox: (24.52, 31.00, -87.63, -80.03),
            polygon: [
                CLLocationCoordinate2D(latitude: 31.00, longitude: -87.60),
                CLLocationCoordinate2D(latitude: 30.36, longitude: -81.51),
                CLLocationCoordinate2D(latitude: 29.00, longitude: -80.53),
                CLLocationCoordinate2D(latitude: 27.20, longitude: -80.03),
                CLLocationCoordinate2D(latitude: 25.12, longitude: -80.38),
                CLLocationCoordinate2D(latitude: 24.52, longitude: -81.82),
                CLLocationCoordinate2D(latitude: 24.69, longitude: -83.05),
                CLLocationCoordinate2D(latitude: 26.42, longitude: -82.02),
                CLLocationCoordinate2D(latitude: 28.79, longitude: -82.67),
                CLLocationCoordinate2D(latitude: 29.69, longitude: -83.59),
                CLLocationCoordinate2D(latitude: 29.92, longitude: -84.86),
                CLLocationCoordinate2D(latitude: 30.42, longitude: -86.63),
                CLLocationCoordinate2D(latitude: 30.99, longitude: -87.63),
                CLLocationCoordinate2D(latitude: 31.00, longitude: -87.60)
            ]
        ),

        // GEORGIA
        StateBoundary(
            code: "GA", name: "Georgia",
            boundingBox: (30.36, 35.00, -85.61, -80.84),
            polygon: [
                CLLocationCoordinate2D(latitude: 35.00, longitude: -85.61),
                CLLocationCoordinate2D(latitude: 35.00, longitude: -83.11),
                CLLocationCoordinate2D(latitude: 34.50, longitude: -83.35),
                CLLocationCoordinate2D(latitude: 33.96, longitude: -83.14),
                CLLocationCoordinate2D(latitude: 32.03, longitude: -81.11),
                CLLocationCoordinate2D(latitude: 30.36, longitude: -81.44),
                CLLocationCoordinate2D(latitude: 30.36, longitude: -82.03),
                CLLocationCoordinate2D(latitude: 31.00, longitude: -84.86),
                CLLocationCoordinate2D(latitude: 31.00, longitude: -85.00),
                CLLocationCoordinate2D(latitude: 32.15, longitude: -84.92),
                CLLocationCoordinate2D(latitude: 34.99, longitude: -85.61),
                CLLocationCoordinate2D(latitude: 35.00, longitude: -85.61)
            ]
        ),

        // IDAHO
        StateBoundary(
            code: "ID", name: "Idaho",
            boundingBox: (41.99, 49.00, -117.24, -111.04),
            polygon: [
                CLLocationCoordinate2D(latitude: 49.00, longitude: -117.03),
                CLLocationCoordinate2D(latitude: 49.00, longitude: -116.05),
                CLLocationCoordinate2D(latitude: 47.96, longitude: -116.05),
                CLLocationCoordinate2D(latitude: 45.99, longitude: -117.00),
                CLLocationCoordinate2D(latitude: 44.39, longitude: -117.24),
                CLLocationCoordinate2D(latitude: 42.00, longitude: -117.03),
                CLLocationCoordinate2D(latitude: 42.00, longitude: -111.04),
                CLLocationCoordinate2D(latitude: 44.47, longitude: -111.05),
                CLLocationCoordinate2D(latitude: 45.00, longitude: -112.97),
                CLLocationCoordinate2D(latitude: 45.57, longitude: -114.57),
                CLLocationCoordinate2D(latitude: 46.63, longitude: -114.44),
                CLLocationCoordinate2D(latitude: 47.50, longitude: -115.75),
                CLLocationCoordinate2D(latitude: 48.99, longitude: -116.05),
                CLLocationCoordinate2D(latitude: 49.00, longitude: -117.03)
            ]
        ),

        // ILLINOIS
        StateBoundary(
            code: "IL", name: "Illinois",
            boundingBox: (36.97, 42.51, -91.51, -87.02),
            polygon: [
                CLLocationCoordinate2D(latitude: 42.51, longitude: -90.64),
                CLLocationCoordinate2D(latitude: 42.49, longitude: -87.02),
                CLLocationCoordinate2D(latitude: 39.17, longitude: -87.53),
                CLLocationCoordinate2D(latitude: 37.95, longitude: -87.97),
                CLLocationCoordinate2D(latitude: 37.00, longitude: -89.17),
                CLLocationCoordinate2D(latitude: 36.97, longitude: -89.52),
                CLLocationCoordinate2D(latitude: 38.22, longitude: -90.37),
                CLLocationCoordinate2D(latitude: 38.79, longitude: -90.17),
                CLLocationCoordinate2D(latitude: 39.36, longitude: -91.42),
                CLLocationCoordinate2D(latitude: 40.60, longitude: -91.51),
                CLLocationCoordinate2D(latitude: 42.51, longitude: -90.64)
            ]
        ),

        // INDIANA
        StateBoundary(
            code: "IN", name: "Indiana",
            boundingBox: (37.77, 41.76, -88.10, -84.78),
            polygon: [
                CLLocationCoordinate2D(latitude: 41.76, longitude: -87.52),
                CLLocationCoordinate2D(latitude: 41.76, longitude: -84.81),
                CLLocationCoordinate2D(latitude: 39.10, longitude: -84.82),
                CLLocationCoordinate2D(latitude: 37.80, longitude: -86.68),
                CLLocationCoordinate2D(latitude: 37.77, longitude: -88.03),
                CLLocationCoordinate2D(latitude: 39.35, longitude: -87.53),
                CLLocationCoordinate2D(latitude: 41.76, longitude: -87.52)
            ]
        ),

        // IOWA
        StateBoundary(
            code: "IA", name: "Iowa",
            boundingBox: (40.37, 43.50, -96.64, -90.14),
            polygon: [
                CLLocationCoordinate2D(latitude: 43.50, longitude: -96.45),
                CLLocationCoordinate2D(latitude: 43.50, longitude: -91.22),
                CLLocationCoordinate2D(latitude: 42.51, longitude: -90.14),
                CLLocationCoordinate2D(latitude: 40.60, longitude: -91.51),
                CLLocationCoordinate2D(latitude: 40.37, longitude: -95.77),
                CLLocationCoordinate2D(latitude: 42.48, longitude: -96.64),
                CLLocationCoordinate2D(latitude: 43.50, longitude: -96.45)
            ]
        ),

        // KANSAS
        StateBoundary(
            code: "KS", name: "Kansas",
            boundingBox: (36.99, 40.00, -102.05, -94.59),
            polygon: [
                CLLocationCoordinate2D(latitude: 40.00, longitude: -102.05),
                CLLocationCoordinate2D(latitude: 40.00, longitude: -94.61),
                CLLocationCoordinate2D(latitude: 37.00, longitude: -94.62),
                CLLocationCoordinate2D(latitude: 37.00, longitude: -102.05),
                CLLocationCoordinate2D(latitude: 40.00, longitude: -102.05)
            ]
        ),

        // KENTUCKY
        StateBoundary(
            code: "KY", name: "Kentucky",
            boundingBox: (36.50, 39.15, -89.57, -81.96),
            polygon: [
                CLLocationCoordinate2D(latitude: 39.15, longitude: -84.82),
                CLLocationCoordinate2D(latitude: 38.40, longitude: -82.60),
                CLLocationCoordinate2D(latitude: 37.54, longitude: -82.32),
                CLLocationCoordinate2D(latitude: 36.60, longitude: -83.69),
                CLLocationCoordinate2D(latitude: 36.60, longitude: -89.41),
                CLLocationCoordinate2D(latitude: 36.97, longitude: -89.57),
                CLLocationCoordinate2D(latitude: 37.00, longitude: -88.05),
                CLLocationCoordinate2D(latitude: 37.77, longitude: -87.89),
                CLLocationCoordinate2D(latitude: 37.93, longitude: -87.05),
                CLLocationCoordinate2D(latitude: 38.79, longitude: -84.85),
                CLLocationCoordinate2D(latitude: 39.15, longitude: -84.82)
            ]
        ),

        // LOUISIANA
        StateBoundary(
            code: "LA", name: "Louisiana",
            boundingBox: (28.93, 33.02, -94.04, -88.82),
            polygon: [
                CLLocationCoordinate2D(latitude: 33.02, longitude: -94.04),
                CLLocationCoordinate2D(latitude: 33.02, longitude: -91.17),
                CLLocationCoordinate2D(latitude: 31.00, longitude: -91.64),
                CLLocationCoordinate2D(latitude: 30.17, longitude: -89.73),
                CLLocationCoordinate2D(latitude: 29.58, longitude: -89.10),
                CLLocationCoordinate2D(latitude: 28.93, longitude: -89.45),
                CLLocationCoordinate2D(latitude: 29.26, longitude: -92.03),
                CLLocationCoordinate2D(latitude: 29.78, longitude: -93.89),
                CLLocationCoordinate2D(latitude: 31.00, longitude: -93.53),
                CLLocationCoordinate2D(latitude: 32.00, longitude: -94.04),
                CLLocationCoordinate2D(latitude: 33.02, longitude: -94.04)
            ]
        ),

        // MAINE
        StateBoundary(
            code: "ME", name: "Maine",
            boundingBox: (43.06, 47.46, -71.08, -66.95),
            polygon: [
                CLLocationCoordinate2D(latitude: 47.46, longitude: -69.23),
                CLLocationCoordinate2D(latitude: 47.28, longitude: -68.09),
                CLLocationCoordinate2D(latitude: 44.81, longitude: -66.95),
                CLLocationCoordinate2D(latitude: 43.06, longitude: -70.70),
                CLLocationCoordinate2D(latitude: 43.75, longitude: -70.55),
                CLLocationCoordinate2D(latitude: 45.30, longitude: -71.08),
                CLLocationCoordinate2D(latitude: 47.46, longitude: -69.23)
            ]
        ),

        // MARYLAND
        StateBoundary(
            code: "MD", name: "Maryland",
            boundingBox: (37.91, 39.72, -79.49, -75.05),
            polygon: [
                CLLocationCoordinate2D(latitude: 39.72, longitude: -79.48),
                CLLocationCoordinate2D(latitude: 39.72, longitude: -75.79),
                CLLocationCoordinate2D(latitude: 38.46, longitude: -75.69),
                CLLocationCoordinate2D(latitude: 38.02, longitude: -75.24),
                CLLocationCoordinate2D(latitude: 37.97, longitude: -76.24),
                CLLocationCoordinate2D(latitude: 38.30, longitude: -77.04),
                CLLocationCoordinate2D(latitude: 39.32, longitude: -77.72),
                CLLocationCoordinate2D(latitude: 39.53, longitude: -79.49),
                CLLocationCoordinate2D(latitude: 39.72, longitude: -79.48)
            ]
        ),

        // MASSACHUSETTS
        StateBoundary(
            code: "MA", name: "Massachusetts",
            boundingBox: (41.24, 42.89, -73.51, -69.93),
            polygon: [
                CLLocationCoordinate2D(latitude: 42.89, longitude: -73.27),
                CLLocationCoordinate2D(latitude: 42.86, longitude: -70.81),
                CLLocationCoordinate2D(latitude: 42.01, longitude: -70.00),
                CLLocationCoordinate2D(latitude: 41.24, longitude: -69.93),
                CLLocationCoordinate2D(latitude: 41.46, longitude: -71.12),
                CLLocationCoordinate2D(latitude: 42.01, longitude: -71.80),
                CLLocationCoordinate2D(latitude: 42.05, longitude: -73.51),
                CLLocationCoordinate2D(latitude: 42.89, longitude: -73.27)
            ]
        ),

        // MICHIGAN
        StateBoundary(
            code: "MI", name: "Michigan",
            boundingBox: (41.70, 48.19, -90.42, -82.41),
            polygon: [
                CLLocationCoordinate2D(latitude: 48.19, longitude: -88.99),
                CLLocationCoordinate2D(latitude: 46.54, longitude: -84.76),
                CLLocationCoordinate2D(latitude: 45.99, longitude: -84.12),
                CLLocationCoordinate2D(latitude: 43.50, longitude: -82.41),
                CLLocationCoordinate2D(latitude: 41.70, longitude: -83.45),
                CLLocationCoordinate2D(latitude: 41.73, longitude: -87.41),
                CLLocationCoordinate2D(latitude: 43.99, longitude: -87.41),
                CLLocationCoordinate2D(latitude: 45.80, longitude: -86.45),
                CLLocationCoordinate2D(latitude: 46.50, longitude: -90.42),
                CLLocationCoordinate2D(latitude: 48.19, longitude: -88.99)
            ]
        ),

        // MINNESOTA
        StateBoundary(
            code: "MN", name: "Minnesota",
            boundingBox: (43.50, 49.38, -97.24, -89.49),
            polygon: [
                CLLocationCoordinate2D(latitude: 49.38, longitude: -97.23),
                CLLocationCoordinate2D(latitude: 49.00, longitude: -95.15),
                CLLocationCoordinate2D(latitude: 49.00, longitude: -89.49),
                CLLocationCoordinate2D(latitude: 46.83, longitude: -92.01),
                CLLocationCoordinate2D(latitude: 43.50, longitude: -91.22),
                CLLocationCoordinate2D(latitude: 43.50, longitude: -96.45),
                CLLocationCoordinate2D(latitude: 45.94, longitude: -96.45),
                CLLocationCoordinate2D(latitude: 49.38, longitude: -97.23)
            ]
        ),

        // MISSISSIPPI
        StateBoundary(
            code: "MS", name: "Mississippi",
            boundingBox: (30.17, 35.00, -91.64, -88.10),
            polygon: [
                CLLocationCoordinate2D(latitude: 35.00, longitude: -90.31),
                CLLocationCoordinate2D(latitude: 35.00, longitude: -88.20),
                CLLocationCoordinate2D(latitude: 34.89, longitude: -88.10),
                CLLocationCoordinate2D(latitude: 30.99, longitude: -88.46),
                CLLocationCoordinate2D(latitude: 30.17, longitude: -89.18),
                CLLocationCoordinate2D(latitude: 31.00, longitude: -89.73),
                CLLocationCoordinate2D(latitude: 33.00, longitude: -91.06),
                CLLocationCoordinate2D(latitude: 35.00, longitude: -90.31)
            ]
        ),

        // MISSOURI
        StateBoundary(
            code: "MO", name: "Missouri",
            boundingBox: (35.99, 40.61, -95.77, -89.10),
            polygon: [
                CLLocationCoordinate2D(latitude: 40.61, longitude: -95.77),
                CLLocationCoordinate2D(latitude: 40.60, longitude: -91.41),
                CLLocationCoordinate2D(latitude: 39.36, longitude: -91.42),
                CLLocationCoordinate2D(latitude: 38.79, longitude: -90.17),
                CLLocationCoordinate2D(latitude: 38.22, longitude: -90.37),
                CLLocationCoordinate2D(latitude: 36.50, longitude: -89.52),
                CLLocationCoordinate2D(latitude: 35.99, longitude: -90.15),
                CLLocationCoordinate2D(latitude: 36.50, longitude: -94.62),
                CLLocationCoordinate2D(latitude: 40.00, longitude: -94.61),
                CLLocationCoordinate2D(latitude: 40.61, longitude: -95.77)
            ]
        ),

        // MONTANA
        StateBoundary(
            code: "MT", name: "Montana",
            boundingBox: (44.36, 49.00, -116.05, -104.04),
            polygon: [
                CLLocationCoordinate2D(latitude: 49.00, longitude: -116.05),
                CLLocationCoordinate2D(latitude: 49.00, longitude: -104.04),
                CLLocationCoordinate2D(latitude: 44.99, longitude: -104.04),
                CLLocationCoordinate2D(latitude: 44.99, longitude: -111.05),
                CLLocationCoordinate2D(latitude: 44.47, longitude: -111.05),
                CLLocationCoordinate2D(latitude: 45.00, longitude: -112.97),
                CLLocationCoordinate2D(latitude: 45.57, longitude: -114.57),
                CLLocationCoordinate2D(latitude: 46.63, longitude: -114.44),
                CLLocationCoordinate2D(latitude: 47.50, longitude: -115.75),
                CLLocationCoordinate2D(latitude: 48.99, longitude: -116.05),
                CLLocationCoordinate2D(latitude: 49.00, longitude: -116.05)
            ]
        ),

        // NEBRASKA
        StateBoundary(
            code: "NE", name: "Nebraska",
            boundingBox: (40.00, 43.00, -104.05, -95.31),
            polygon: [
                CLLocationCoordinate2D(latitude: 43.00, longitude: -104.05),
                CLLocationCoordinate2D(latitude: 43.00, longitude: -96.55),
                CLLocationCoordinate2D(latitude: 42.48, longitude: -96.64),
                CLLocationCoordinate2D(latitude: 40.00, longitude: -95.31),
                CLLocationCoordinate2D(latitude: 40.00, longitude: -102.05),
                CLLocationCoordinate2D(latitude: 41.00, longitude: -104.05),
                CLLocationCoordinate2D(latitude: 43.00, longitude: -104.05)
            ]
        ),

        // NEVADA
        StateBoundary(
            code: "NV", name: "Nevada",
            boundingBox: (35.00, 42.00, -120.01, -114.04),
            polygon: [
                CLLocationCoordinate2D(latitude: 42.00, longitude: -120.00),
                CLLocationCoordinate2D(latitude: 42.00, longitude: -117.03),
                CLLocationCoordinate2D(latitude: 41.00, longitude: -117.03),
                CLLocationCoordinate2D(latitude: 36.14, longitude: -114.05),
                CLLocationCoordinate2D(latitude: 36.00, longitude: -114.75),
                CLLocationCoordinate2D(latitude: 35.00, longitude: -114.63),
                CLLocationCoordinate2D(latitude: 39.00, longitude: -120.00),
                CLLocationCoordinate2D(latitude: 42.00, longitude: -120.00)
            ]
        ),

        // NEW HAMPSHIRE
        StateBoundary(
            code: "NH", name: "New Hampshire",
            boundingBox: (42.70, 45.31, -72.56, -70.70),
            polygon: [
                CLLocationCoordinate2D(latitude: 45.31, longitude: -71.50),
                CLLocationCoordinate2D(latitude: 43.57, longitude: -70.70),
                CLLocationCoordinate2D(latitude: 42.70, longitude: -70.82),
                CLLocationCoordinate2D(latitude: 42.86, longitude: -71.29),
                CLLocationCoordinate2D(latitude: 42.73, longitude: -72.46),
                CLLocationCoordinate2D(latitude: 45.00, longitude: -72.56),
                CLLocationCoordinate2D(latitude: 45.31, longitude: -71.50)
            ]
        ),

        // NEW JERSEY
        StateBoundary(
            code: "NJ", name: "New Jersey",
            boundingBox: (38.93, 41.36, -75.56, -73.89),
            polygon: [
                CLLocationCoordinate2D(latitude: 41.36, longitude: -74.70),
                CLLocationCoordinate2D(latitude: 40.99, longitude: -73.89),
                CLLocationCoordinate2D(latitude: 38.93, longitude: -74.86),
                CLLocationCoordinate2D(latitude: 39.36, longitude: -75.56),
                CLLocationCoordinate2D(latitude: 40.22, longitude: -74.74),
                CLLocationCoordinate2D(latitude: 41.36, longitude: -74.70)
            ]
        ),

        // NEW MEXICO
        StateBoundary(
            code: "NM", name: "New Mexico",
            boundingBox: (31.33, 37.00, -109.05, -103.00),
            polygon: [
                CLLocationCoordinate2D(latitude: 37.00, longitude: -109.05),
                CLLocationCoordinate2D(latitude: 37.00, longitude: -103.00),
                CLLocationCoordinate2D(latitude: 32.00, longitude: -103.00),
                CLLocationCoordinate2D(latitude: 32.00, longitude: -106.62),
                CLLocationCoordinate2D(latitude: 31.78, longitude: -106.53),
                CLLocationCoordinate2D(latitude: 31.33, longitude: -108.21),
                CLLocationCoordinate2D(latitude: 31.33, longitude: -109.05),
                CLLocationCoordinate2D(latitude: 37.00, longitude: -109.05)
            ]
        ),

        // NEW YORK
        StateBoundary(
            code: "NY", name: "New York",
            boundingBox: (40.50, 45.02, -79.76, -71.86),
            polygon: [
                CLLocationCoordinate2D(latitude: 45.02, longitude: -74.99),
                CLLocationCoordinate2D(latitude: 45.00, longitude: -73.34),
                CLLocationCoordinate2D(latitude: 42.73, longitude: -73.27),
                CLLocationCoordinate2D(latitude: 42.05, longitude: -73.51),
                CLLocationCoordinate2D(latitude: 41.21, longitude: -73.73),
                CLLocationCoordinate2D(latitude: 40.50, longitude: -74.26),
                CLLocationCoordinate2D(latitude: 40.50, longitude: -72.03),
                CLLocationCoordinate2D(latitude: 41.05, longitude: -71.86),
                CLLocationCoordinate2D(latitude: 41.36, longitude: -74.70),
                CLLocationCoordinate2D(latitude: 42.00, longitude: -79.76),
                CLLocationCoordinate2D(latitude: 43.63, longitude: -79.06),
                CLLocationCoordinate2D(latitude: 45.02, longitude: -74.99)
            ]
        ),

        // NORTH CAROLINA
        StateBoundary(
            code: "NC", name: "North Carolina",
            boundingBox: (33.84, 36.59, -84.32, -75.46),
            polygon: [
                CLLocationCoordinate2D(latitude: 36.59, longitude: -84.32),
                CLLocationCoordinate2D(latitude: 36.59, longitude: -75.87),
                CLLocationCoordinate2D(latitude: 35.26, longitude: -75.46),
                CLLocationCoordinate2D(latitude: 33.84, longitude: -78.54),
                CLLocationCoordinate2D(latitude: 34.82, longitude: -79.67),
                CLLocationCoordinate2D(latitude: 35.19, longitude: -80.93),
                CLLocationCoordinate2D(latitude: 35.00, longitude: -84.00),
                CLLocationCoordinate2D(latitude: 36.59, longitude: -84.32)
            ]
        ),

        // NORTH DAKOTA
        StateBoundary(
            code: "ND", name: "North Dakota",
            boundingBox: (45.93, 49.00, -104.05, -96.55),
            polygon: [
                CLLocationCoordinate2D(latitude: 49.00, longitude: -104.05),
                CLLocationCoordinate2D(latitude: 49.00, longitude: -97.23),
                CLLocationCoordinate2D(latitude: 45.94, longitude: -96.55),
                CLLocationCoordinate2D(latitude: 45.93, longitude: -104.05),
                CLLocationCoordinate2D(latitude: 49.00, longitude: -104.05)
            ]
        ),

        // OHIO
        StateBoundary(
            code: "OH", name: "Ohio",
            boundingBox: (38.40, 42.32, -84.82, -80.52),
            polygon: [
                CLLocationCoordinate2D(latitude: 41.98, longitude: -84.82),
                CLLocationCoordinate2D(latitude: 42.32, longitude: -80.52),
                CLLocationCoordinate2D(latitude: 39.27, longitude: -80.52),
                CLLocationCoordinate2D(latitude: 38.40, longitude: -82.60),
                CLLocationCoordinate2D(latitude: 39.10, longitude: -84.82),
                CLLocationCoordinate2D(latitude: 41.98, longitude: -84.82)
            ]
        ),

        // OKLAHOMA
        StateBoundary(
            code: "OK", name: "Oklahoma",
            boundingBox: (33.62, 37.00, -103.00, -94.43),
            polygon: [
                CLLocationCoordinate2D(latitude: 37.00, longitude: -103.00),
                CLLocationCoordinate2D(latitude: 37.00, longitude: -94.62),
                CLLocationCoordinate2D(latitude: 36.50, longitude: -94.62),
                CLLocationCoordinate2D(latitude: 33.68, longitude: -94.48),
                CLLocationCoordinate2D(latitude: 33.62, longitude: -96.37),
                CLLocationCoordinate2D(latitude: 34.00, longitude: -99.99),
                CLLocationCoordinate2D(latitude: 36.50, longitude: -100.00),
                CLLocationCoordinate2D(latitude: 36.50, longitude: -103.00),
                CLLocationCoordinate2D(latitude: 37.00, longitude: -103.00)
            ]
        ),

        // OREGON
        StateBoundary(
            code: "OR", name: "Oregon",
            boundingBox: (41.99, 46.29, -124.57, -116.46),
            polygon: [
                CLLocationCoordinate2D(latitude: 46.29, longitude: -124.05),
                CLLocationCoordinate2D(latitude: 46.29, longitude: -116.92),
                CLLocationCoordinate2D(latitude: 45.99, longitude: -117.00),
                CLLocationCoordinate2D(latitude: 44.39, longitude: -117.24),
                CLLocationCoordinate2D(latitude: 42.00, longitude: -117.03),
                CLLocationCoordinate2D(latitude: 42.00, longitude: -124.21),
                CLLocationCoordinate2D(latitude: 43.41, longitude: -124.57),
                CLLocationCoordinate2D(latitude: 46.29, longitude: -124.05)
            ]
        ),

        // PENNSYLVANIA
        StateBoundary(
            code: "PA", name: "Pennsylvania",
            boundingBox: (39.72, 42.27, -80.52, -74.69),
            polygon: [
                CLLocationCoordinate2D(latitude: 42.27, longitude: -80.52),
                CLLocationCoordinate2D(latitude: 42.00, longitude: -74.69),
                CLLocationCoordinate2D(latitude: 41.36, longitude: -74.70),
                CLLocationCoordinate2D(latitude: 40.22, longitude: -74.74),
                CLLocationCoordinate2D(latitude: 39.72, longitude: -75.79),
                CLLocationCoordinate2D(latitude: 39.72, longitude: -80.52),
                CLLocationCoordinate2D(latitude: 42.27, longitude: -80.52)
            ]
        ),

        // RHODE ISLAND
        StateBoundary(
            code: "RI", name: "Rhode Island",
            boundingBox: (41.15, 42.02, -71.86, -71.12),
            polygon: [
                CLLocationCoordinate2D(latitude: 42.02, longitude: -71.80),
                CLLocationCoordinate2D(latitude: 42.02, longitude: -71.12),
                CLLocationCoordinate2D(latitude: 41.15, longitude: -71.12),
                CLLocationCoordinate2D(latitude: 41.46, longitude: -71.86),
                CLLocationCoordinate2D(latitude: 42.02, longitude: -71.80)
            ]
        ),

        // SOUTH CAROLINA
        StateBoundary(
            code: "SC", name: "South Carolina",
            boundingBox: (32.03, 35.22, -83.35, -78.54),
            polygon: [
                CLLocationCoordinate2D(latitude: 35.22, longitude: -83.11),
                CLLocationCoordinate2D(latitude: 35.19, longitude: -80.93),
                CLLocationCoordinate2D(latitude: 34.82, longitude: -79.67),
                CLLocationCoordinate2D(latitude: 33.84, longitude: -78.54),
                CLLocationCoordinate2D(latitude: 32.03, longitude: -80.84),
                CLLocationCoordinate2D(latitude: 32.03, longitude: -81.11),
                CLLocationCoordinate2D(latitude: 33.96, longitude: -83.14),
                CLLocationCoordinate2D(latitude: 34.50, longitude: -83.35),
                CLLocationCoordinate2D(latitude: 35.22, longitude: -83.11)
            ]
        ),

        // SOUTH DAKOTA
        StateBoundary(
            code: "SD", name: "South Dakota",
            boundingBox: (42.48, 45.95, -104.06, -96.44),
            polygon: [
                CLLocationCoordinate2D(latitude: 45.95, longitude: -104.06),
                CLLocationCoordinate2D(latitude: 45.94, longitude: -96.55),
                CLLocationCoordinate2D(latitude: 43.50, longitude: -96.45),
                CLLocationCoordinate2D(latitude: 42.48, longitude: -96.64),
                CLLocationCoordinate2D(latitude: 43.00, longitude: -104.05),
                CLLocationCoordinate2D(latitude: 45.95, longitude: -104.06)
            ]
        ),

        // TENNESSEE
        StateBoundary(
            code: "TN", name: "Tennessee",
            boundingBox: (34.98, 36.68, -90.31, -81.65),
            polygon: [
                CLLocationCoordinate2D(latitude: 36.68, longitude: -89.52),
                CLLocationCoordinate2D(latitude: 36.59, longitude: -83.69),
                CLLocationCoordinate2D(latitude: 36.59, longitude: -81.65),
                CLLocationCoordinate2D(latitude: 35.00, longitude: -84.00),
                CLLocationCoordinate2D(latitude: 35.00, longitude: -90.31),
                CLLocationCoordinate2D(latitude: 35.99, longitude: -90.15),
                CLLocationCoordinate2D(latitude: 36.50, longitude: -89.52),
                CLLocationCoordinate2D(latitude: 36.68, longitude: -89.52)
            ]
        ),

        // TEXAS
        StateBoundary(
            code: "TX", name: "Texas",
            boundingBox: (25.84, 36.50, -106.65, -93.51),
            polygon: [
                CLLocationCoordinate2D(latitude: 36.50, longitude: -103.00),
                CLLocationCoordinate2D(latitude: 36.50, longitude: -100.00),
                CLLocationCoordinate2D(latitude: 34.00, longitude: -99.99),
                CLLocationCoordinate2D(latitude: 33.62, longitude: -96.37),
                CLLocationCoordinate2D(latitude: 33.68, longitude: -94.48),
                CLLocationCoordinate2D(latitude: 33.00, longitude: -94.04),
                CLLocationCoordinate2D(latitude: 29.78, longitude: -93.89),
                CLLocationCoordinate2D(latitude: 29.55, longitude: -94.69),
                CLLocationCoordinate2D(latitude: 28.64, longitude: -96.02),
                CLLocationCoordinate2D(latitude: 26.17, longitude: -97.15),
                CLLocationCoordinate2D(latitude: 25.84, longitude: -97.40),
                CLLocationCoordinate2D(latitude: 26.06, longitude: -98.21),
                CLLocationCoordinate2D(latitude: 29.02, longitude: -100.75),
                CLLocationCoordinate2D(latitude: 29.77, longitude: -101.40),
                CLLocationCoordinate2D(latitude: 29.78, longitude: -103.12),
                CLLocationCoordinate2D(latitude: 31.00, longitude: -104.02),
                CLLocationCoordinate2D(latitude: 31.78, longitude: -106.53),
                CLLocationCoordinate2D(latitude: 32.00, longitude: -106.62),
                CLLocationCoordinate2D(latitude: 32.00, longitude: -103.00),
                CLLocationCoordinate2D(latitude: 36.50, longitude: -103.00)
            ]
        ),

        // UTAH
        StateBoundary(
            code: "UT", name: "Utah",
            boundingBox: (36.99, 42.00, -114.05, -109.04),
            polygon: [
                CLLocationCoordinate2D(latitude: 42.00, longitude: -114.05),
                CLLocationCoordinate2D(latitude: 42.00, longitude: -111.05),
                CLLocationCoordinate2D(latitude: 41.00, longitude: -111.05),
                CLLocationCoordinate2D(latitude: 41.00, longitude: -109.05),
                CLLocationCoordinate2D(latitude: 37.00, longitude: -109.05),
                CLLocationCoordinate2D(latitude: 37.00, longitude: -114.05),
                CLLocationCoordinate2D(latitude: 42.00, longitude: -114.05)
            ]
        ),

        // VERMONT
        StateBoundary(
            code: "VT", name: "Vermont",
            boundingBox: (42.73, 45.02, -73.44, -71.50),
            polygon: [
                CLLocationCoordinate2D(latitude: 45.02, longitude: -73.34),
                CLLocationCoordinate2D(latitude: 45.01, longitude: -71.50),
                CLLocationCoordinate2D(latitude: 45.00, longitude: -72.56),
                CLLocationCoordinate2D(latitude: 42.73, longitude: -72.46),
                CLLocationCoordinate2D(latitude: 42.73, longitude: -73.27),
                CLLocationCoordinate2D(latitude: 45.02, longitude: -73.34)
            ]
        ),

        // VIRGINIA
        StateBoundary(
            code: "VA", name: "Virginia",
            boundingBox: (36.54, 39.47, -83.68, -75.24),
            polygon: [
                CLLocationCoordinate2D(latitude: 39.47, longitude: -77.72),
                CLLocationCoordinate2D(latitude: 38.30, longitude: -77.04),
                CLLocationCoordinate2D(latitude: 37.97, longitude: -76.24),
                CLLocationCoordinate2D(latitude: 36.55, longitude: -75.87),
                CLLocationCoordinate2D(latitude: 36.55, longitude: -76.92),
                CLLocationCoordinate2D(latitude: 36.60, longitude: -83.68),
                CLLocationCoordinate2D(latitude: 37.54, longitude: -82.32),
                CLLocationCoordinate2D(latitude: 38.40, longitude: -82.03),
                CLLocationCoordinate2D(latitude: 39.27, longitude: -80.52),
                CLLocationCoordinate2D(latitude: 39.47, longitude: -77.72)
            ]
        ),

        // WASHINGTON
        StateBoundary(
            code: "WA", name: "Washington",
            boundingBox: (45.54, 49.00, -124.73, -116.92),
            polygon: [
                CLLocationCoordinate2D(latitude: 49.00, longitude: -123.32),
                CLLocationCoordinate2D(latitude: 49.00, longitude: -117.03),
                CLLocationCoordinate2D(latitude: 46.29, longitude: -116.92),
                CLLocationCoordinate2D(latitude: 46.29, longitude: -124.05),
                CLLocationCoordinate2D(latitude: 46.73, longitude: -124.08),
                CLLocationCoordinate2D(latitude: 48.30, longitude: -124.73),
                CLLocationCoordinate2D(latitude: 49.00, longitude: -123.32)
            ]
        ),

        // WEST VIRGINIA
        StateBoundary(
            code: "WV", name: "West Virginia",
            boundingBox: (37.20, 40.64, -82.64, -77.72),
            polygon: [
                CLLocationCoordinate2D(latitude: 40.64, longitude: -80.52),
                CLLocationCoordinate2D(latitude: 39.72, longitude: -79.48),
                CLLocationCoordinate2D(latitude: 39.32, longitude: -77.72),
                CLLocationCoordinate2D(latitude: 38.30, longitude: -77.04),
                CLLocationCoordinate2D(latitude: 37.51, longitude: -78.34),
                CLLocationCoordinate2D(latitude: 37.20, longitude: -81.23),
                CLLocationCoordinate2D(latitude: 37.54, longitude: -82.32),
                CLLocationCoordinate2D(latitude: 38.40, longitude: -82.60),
                CLLocationCoordinate2D(latitude: 39.27, longitude: -80.52),
                CLLocationCoordinate2D(latitude: 40.64, longitude: -80.52)
            ]
        ),

        // WISCONSIN
        StateBoundary(
            code: "WI", name: "Wisconsin",
            boundingBox: (42.49, 47.08, -92.89, -86.25),
            polygon: [
                CLLocationCoordinate2D(latitude: 47.08, longitude: -90.78),
                CLLocationCoordinate2D(latitude: 46.59, longitude: -86.25),
                CLLocationCoordinate2D(latitude: 44.76, longitude: -86.93),
                CLLocationCoordinate2D(latitude: 43.99, longitude: -87.79),
                CLLocationCoordinate2D(latitude: 42.51, longitude: -87.79),
                CLLocationCoordinate2D(latitude: 42.49, longitude: -90.64),
                CLLocationCoordinate2D(latitude: 43.38, longitude: -90.43),
                CLLocationCoordinate2D(latitude: 45.38, longitude: -92.89),
                CLLocationCoordinate2D(latitude: 46.16, longitude: -92.29),
                CLLocationCoordinate2D(latitude: 47.08, longitude: -90.78)
            ]
        ),

        // WYOMING
        StateBoundary(
            code: "WY", name: "Wyoming",
            boundingBox: (40.99, 45.01, -111.06, -104.05),
            polygon: [
                CLLocationCoordinate2D(latitude: 45.00, longitude: -111.05),
                CLLocationCoordinate2D(latitude: 45.00, longitude: -104.05),
                CLLocationCoordinate2D(latitude: 41.00, longitude: -104.05),
                CLLocationCoordinate2D(latitude: 41.00, longitude: -111.05),
                CLLocationCoordinate2D(latitude: 45.00, longitude: -111.05)
            ]
        )
    ]
}
