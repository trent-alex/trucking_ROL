# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS app (SwiftUI) for truck drivers to calculate the total cost and profitability of moving loads — fuel, tolls, and overnight stays. Uses Apple Maps for routing and EIA API for regional diesel pricing.

**Requirements:** iOS 17.0+, Xcode 15.0+

**Bundle Identifier:** `com.pivotallift.TruckRouteCalculator`

## Build & Run

```bash
# Build and run in simulator
xcodebuild -project TruckRouteCalculator.xcodeproj -scheme TruckRouteCalculator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Install and launch
xcrun simctl install booted <path-to-app>
xcrun simctl launch booted com.pivotallift.TruckRouteCalculator
```

No external package dependencies — only Apple standard frameworks (Foundation, SwiftUI, SwiftData).

**Fastlane:** CI/CD configured for App Store deployment (`fastlane/`).

## Architecture

**Pattern:** MVVM (Model-View-ViewModel)

**Data flow:** Views observe ViewModels which coordinate services:
- `AppleMapService` — handles Apple Maps routing and Places autocomplete
- `FuelPriceService` — fetches regional diesel prices from EIA API (24hr cache)
- `CostCalculator` — pure calculation logic for fuel costs, overnight stays, and cost breakdowns

**ViewModels:**
- `RouteCalculatorViewModel` — single-route calculations
- `ScenarioCalculatorViewModel` — multi-segment load profitability analysis

All views are children of `ContentView`:
```
ContentView
  ├── ProfileSetupView        (first-run truck selection/onboarding)
  ├── ScenarioInputView       (multi-drop load entry)
  ├── ScenarioResultsView     (profitability breakdown + comparison)
  ├── RouteInputView          (origin/destination with autocomplete)
  ├── CostSummaryView         (results breakdown)
  └── SettingsView            (modal sheet for configurable defaults)
```

**Models** (pure data structs):
- Core: `Route`, `TollInfo`, `TollSegment`, `LoadConfig`, `CostBreakdown`
- Scenario: `LoadScenario`, `RouteSegment`, `SegmentType`, `DropLocation`
- Profile: `DriverProfile`, `TruckDatabase` (30+ real truck specs)

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
- `ViewModels/` — ViewModels orchestrating state
- `Views/` — SwiftUI views
- `Utilities/` — constants and configuration
