import SwiftUI
import SwiftData

@main
struct TruckRouteCalculatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: SavedRoute.self)
    }
}
