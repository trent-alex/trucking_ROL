# Truck Route Cost Calculator

An iOS app for truck drivers to quickly calculate the total cost of moving a load, including fuel, tolls, and overnight stays.

## Features

- **Route Calculation**: Enter origin and destination with Google Places autocomplete
- **Weight-Based Fuel Costs**: Fuel efficiency decreases as load weight increases
- **Toll Estimates**: Automatic toll cost estimates via Google Maps Routes API
- **Overnight Stays**: Auto-calculated based on Hours of Service regulations with manual override
- **Cost Summary**: Total cost breakdown with per-mile cost
- **Share Quote**: Share cost estimates via text, email, or other apps

## Setup Instructions

### 1. Google Maps API Key Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - **Routes API** (for route calculation and toll info)
   - **Places API** (for address autocomplete)
4. Go to **Credentials** → **Create Credentials** → **API Key**
5. Restrict your API key:
   - Application restriction: **iOS apps**
   - Add your app's bundle identifier (e.g., `com.yourcompany.TruckRouteCalculator`)
   - API restrictions: Select **Routes API** and **Places API**
6. Copy the API key

### 2. Configure the App

1. Open `Utilities/Constants.swift`
2. Replace the placeholder API key:
   ```swift
   static let googleMapsAPIKey = "YOUR_GOOGLE_MAPS_API_KEY"
   ```

### 3. Create Xcode Project

1. Open Xcode and create a new iOS App project
2. Product Name: `TruckRouteCalculator`
3. Interface: **SwiftUI**
4. Language: **Swift**
5. Copy all source files into the project maintaining the folder structure

### 4. Build and Run

1. Select your target device or simulator (iOS 15.0+)
2. Build and run the app

## Project Structure

```
TruckRouteCalculator/
├── TruckRouteCalculatorApp.swift    # App entry point
├── Models/
│   ├── Route.swift                  # Route and toll data models
│   ├── LoadConfig.swift             # Load weight configuration
│   └── CostBreakdown.swift          # Cost calculation results
├── Views/
│   ├── ContentView.swift            # Main app view
│   ├── RouteInputView.swift         # Origin/destination input
│   ├── LoadConfigView.swift         # Weight configuration
│   ├── CostSummaryView.swift        # Cost breakdown display
│   └── SettingsView.swift           # App settings
├── ViewModels/
│   └── RouteCalculatorViewModel.swift  # Main business logic
├── Services/
│   ├── GoogleMapsService.swift      # Google Maps API integration
│   └── CostCalculator.swift         # Cost calculation logic
└── Utilities/
    └── Constants.swift              # App configuration
```

## Calculation Formulas

### Fuel Efficiency (MPG)
```
effectiveMPG = baseMPG - (totalWeight - 30,000) × 0.00003
```
- Base MPG: 7.0 (configurable)
- Example: 80,000 lb truck = 7.0 - (50,000 × 0.00003) = 5.5 MPG

### Overnight Stays
```
nights = ceil(distance / 550) - 1
```
- Based on DOT Hours of Service: 11-hour driving limit
- ~550 miles/day at 50 mph average
- Can be manually adjusted

## Configurable Settings

| Setting | Default | Description |
|---------|---------|-------------|
| Base MPG | 7.0 | Empty truck fuel efficiency |
| Fuel Price | $3.50/gal | Current fuel price |
| Empty Weight | 30,000 lbs | Truck weight without load |
| Nightly Rate | $150 | Overnight stay cost |

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Google Maps API key with Routes API and Places API enabled

## API Costs

Google Maps API pricing (as of 2024):
- Routes API: $5.00 per 1,000 requests
- Places API Autocomplete: $2.83 per 1,000 requests

Consider implementing caching and request throttling for production use.

## License

MIT License
