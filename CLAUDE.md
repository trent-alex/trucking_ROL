# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS app (SwiftUI) for truck drivers to calculate the total cost of moving a load — fuel, tolls, and overnight stays. Integrates with Google Maps Routes API v2 and Places API for real-time route and toll data.

**Requirements:** iOS 15.0+, Xcode 14.0+, Google Maps API key (Routes API + Places API enabled).

## Build & Run

This is a Swift/SwiftUI project without an .xcodeproj checked in. To build:
1. Create an Xcode iOS App project (SwiftUI, Swift)
2. Copy all files from `TruckRouteCalculator/` maintaining folder structure
3. Set the Google Maps API key in `TruckRouteCalculator/Utilities/Constants.swift`
4. Build and run targeting iOS 15.0+

No external package dependencies — only Apple standard frameworks (Foundation, SwiftUI).

No test suite or CI/CD configuration exists in this repo.

## Architecture

**Pattern:** MVVM (Model-View-ViewModel)

**Data flow:** Views observe a single `RouteCalculatorViewModel` which coordinates two services:
- `GoogleMapsService` — handles Routes API (POST to `computeRoutes`) and Places Autocomplete API (GET) calls
- `CostCalculator` — pure calculation logic for fuel costs, overnight stays, and cost breakdowns

All views are children of `ContentView` and share the same ViewModel instance:
```
ContentView
  ├── RouteInputView      (origin/destination with autocomplete)
  ├── LoadConfigView      (truck + load weight)
  ├── CostSummaryView     (results breakdown)
  └── SettingsView         (modal sheet for configurable defaults)
```

**Models** (`Route`, `TollInfo`, `TollSegment`, `LoadConfig`, `CostBreakdown`) are pure data structs with no business logic.

## Key Domain Logic

**Fuel efficiency formula:**
```
effectiveMPG = baseMPG - (totalWeight - 30,000) × 0.00003
```
Floor enforced at 4.0 MPG (`Constants.minimumMPG`).

**Overnight stays:** `ceil(distance / 550) - 1` based on DOT Hours of Service 11-hour driving limit (~550 mi/day at 50 mph). Users can manually override.

**Federal weight limit:** 80,000 lbs — UI shows a warning when exceeded.

**Search debouncing:** ViewModel debounces autocomplete queries by 300ms to limit API calls.

## Configuration Defaults (Constants.swift)

| Constant | Value |
|----------|-------|
| baseMPG | 7.0 |
| fuelPrice | $3.50/gal |
| baseWeight | 30,000 lbs |
| nightlyRate | $150/night |
| milesPerDay | 550 |
| maxLegalWeight | 80,000 lbs |

All defaults are user-configurable at runtime via SettingsView.

## Source Layout

All source lives under `TruckRouteCalculator/`:
- `Models/` — data structs
- `Services/` — API integration and calculation engine
- `ViewModels/` — single ViewModel orchestrating state
- `Views/` — SwiftUI views
- `Utilities/` — constants and configuration
