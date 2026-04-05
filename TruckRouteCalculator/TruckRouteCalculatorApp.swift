import SwiftUI
import SwiftData

@main
struct TruckRouteCalculatorApp: App {
    @State private var storeManager = StoreManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeManager)
        }
        .modelContainer(for: SavedRoute.self)
    }
}
