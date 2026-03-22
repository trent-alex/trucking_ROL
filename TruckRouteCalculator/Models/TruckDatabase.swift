import Foundation

// MARK: - Truck Make

enum TruckMake: String, Codable, CaseIterable, Identifiable {
    case freightliner = "Freightliner"
    case peterbilt = "Peterbilt"
    case kenworth = "Kenworth"
    case volvo = "Volvo"
    case mack = "Mack"
    case international = "International"
    case westernStar = "Western Star"
    case custom = "Other"

    var id: String { rawValue }
}

// MARK: - Truck Spec

struct TruckSpec: Identifiable, Codable, Hashable {
    let id: String
    let make: TruckMake
    let model: String
    let type: TruckType
    let yearStart: Int
    let yearEnd: Int?
    let baseMPG: Double
    let emptyWeight: Double

    var displayName: String {
        "\(make.rawValue) \(model)"
    }

    var yearRange: String {
        if let end = yearEnd {
            return "\(yearStart)-\(end)"
        }
        return "\(yearStart)+"
    }

    func isValidForYear(_ year: Int) -> Bool {
        year >= yearStart && (yearEnd == nil || year <= yearEnd!)
    }
}

// MARK: - Truck Database

struct TruckDatabase {

    static let trucks: [TruckSpec] = [
        // MARK: Freightliner
        TruckSpec(id: "fl-cascadia-sleeper", make: .freightliner, model: "Cascadia", type: .sleeperCab,
                  yearStart: 2017, yearEnd: nil, baseMPG: 7.5, emptyWeight: 19500),
        TruckSpec(id: "fl-cascadia-day", make: .freightliner, model: "Cascadia Day Cab", type: .dayCab,
                  yearStart: 2017, yearEnd: nil, baseMPG: 8.2, emptyWeight: 16500),
        TruckSpec(id: "fl-cascadia-old", make: .freightliner, model: "Cascadia (Legacy)", type: .sleeperCab,
                  yearStart: 2008, yearEnd: 2016, baseMPG: 6.8, emptyWeight: 20000),
        TruckSpec(id: "fl-columbia", make: .freightliner, model: "Columbia", type: .sleeperCab,
                  yearStart: 2000, yearEnd: 2014, baseMPG: 6.5, emptyWeight: 20500),
        TruckSpec(id: "fl-m2-106", make: .freightliner, model: "M2 106", type: .dayCab,
                  yearStart: 2004, yearEnd: nil, baseMPG: 8.5, emptyWeight: 14000),
        TruckSpec(id: "fl-m2-112", make: .freightliner, model: "M2 112", type: .dayCab,
                  yearStart: 2004, yearEnd: nil, baseMPG: 7.8, emptyWeight: 15500),

        // MARK: Peterbilt
        TruckSpec(id: "pb-579-sleeper", make: .peterbilt, model: "579", type: .sleeperCab,
                  yearStart: 2012, yearEnd: nil, baseMPG: 7.2, emptyWeight: 19000),
        TruckSpec(id: "pb-579-day", make: .peterbilt, model: "579 Day Cab", type: .dayCab,
                  yearStart: 2012, yearEnd: nil, baseMPG: 7.8, emptyWeight: 16000),
        TruckSpec(id: "pb-389-sleeper", make: .peterbilt, model: "389", type: .sleeperCab,
                  yearStart: 2007, yearEnd: nil, baseMPG: 6.5, emptyWeight: 20500),
        TruckSpec(id: "pb-389-day", make: .peterbilt, model: "389 Day Cab", type: .dayCab,
                  yearStart: 2007, yearEnd: nil, baseMPG: 7.0, emptyWeight: 17500),
        TruckSpec(id: "pb-567", make: .peterbilt, model: "567", type: .dayCab,
                  yearStart: 2014, yearEnd: nil, baseMPG: 7.5, emptyWeight: 16500),
        TruckSpec(id: "pb-520", make: .peterbilt, model: "520", type: .dayCab,
                  yearStart: 2016, yearEnd: nil, baseMPG: 8.0, emptyWeight: 15000),

        // MARK: Kenworth
        TruckSpec(id: "kw-t680-sleeper", make: .kenworth, model: "T680", type: .sleeperCab,
                  yearStart: 2013, yearEnd: nil, baseMPG: 7.4, emptyWeight: 19000),
        TruckSpec(id: "kw-t680-day", make: .kenworth, model: "T680 Day Cab", type: .dayCab,
                  yearStart: 2013, yearEnd: nil, baseMPG: 8.0, emptyWeight: 16000),
        TruckSpec(id: "kw-w900-sleeper", make: .kenworth, model: "W900", type: .sleeperCab,
                  yearStart: 1990, yearEnd: nil, baseMPG: 6.2, emptyWeight: 21000),
        TruckSpec(id: "kw-w900-day", make: .kenworth, model: "W900 Day Cab", type: .dayCab,
                  yearStart: 1990, yearEnd: nil, baseMPG: 6.8, emptyWeight: 18000),
        TruckSpec(id: "kw-t880", make: .kenworth, model: "T880", type: .dayCab,
                  yearStart: 2014, yearEnd: nil, baseMPG: 7.2, emptyWeight: 17000),
        TruckSpec(id: "kw-t370", make: .kenworth, model: "T370", type: .dayCab,
                  yearStart: 2010, yearEnd: nil, baseMPG: 8.5, emptyWeight: 13500),

        // MARK: Volvo
        TruckSpec(id: "volvo-vnl860", make: .volvo, model: "VNL 860", type: .sleeperCab,
                  yearStart: 2018, yearEnd: nil, baseMPG: 7.8, emptyWeight: 18500),
        TruckSpec(id: "volvo-vnl760", make: .volvo, model: "VNL 760", type: .sleeperCab,
                  yearStart: 2018, yearEnd: nil, baseMPG: 7.6, emptyWeight: 19000),
        TruckSpec(id: "volvo-vnl300", make: .volvo, model: "VNL 300", type: .dayCab,
                  yearStart: 2018, yearEnd: nil, baseMPG: 8.2, emptyWeight: 15500),
        TruckSpec(id: "volvo-vnl-legacy", make: .volvo, model: "VNL (Legacy)", type: .sleeperCab,
                  yearStart: 2004, yearEnd: 2017, baseMPG: 7.0, emptyWeight: 19500),
        TruckSpec(id: "volvo-vnr", make: .volvo, model: "VNR", type: .dayCab,
                  yearStart: 2018, yearEnd: nil, baseMPG: 8.0, emptyWeight: 16000),

        // MARK: Mack
        TruckSpec(id: "mack-anthem-sleeper", make: .mack, model: "Anthem", type: .sleeperCab,
                  yearStart: 2017, yearEnd: nil, baseMPG: 7.3, emptyWeight: 19500),
        TruckSpec(id: "mack-anthem-day", make: .mack, model: "Anthem Day Cab", type: .dayCab,
                  yearStart: 2017, yearEnd: nil, baseMPG: 7.9, emptyWeight: 16500),
        TruckSpec(id: "mack-pinnacle-sleeper", make: .mack, model: "Pinnacle", type: .sleeperCab,
                  yearStart: 2006, yearEnd: 2019, baseMPG: 6.8, emptyWeight: 20000),
        TruckSpec(id: "mack-granite", make: .mack, model: "Granite", type: .dayCab,
                  yearStart: 2002, yearEnd: nil, baseMPG: 6.5, emptyWeight: 18000),

        // MARK: International
        TruckSpec(id: "intl-lt-sleeper", make: .international, model: "LT", type: .sleeperCab,
                  yearStart: 2017, yearEnd: nil, baseMPG: 7.4, emptyWeight: 18500),
        TruckSpec(id: "intl-lt-day", make: .international, model: "LT Day Cab", type: .dayCab,
                  yearStart: 2017, yearEnd: nil, baseMPG: 8.0, emptyWeight: 15500),
        TruckSpec(id: "intl-lonestar", make: .international, model: "LoneStar", type: .sleeperCab,
                  yearStart: 2010, yearEnd: 2017, baseMPG: 6.8, emptyWeight: 20000),
        TruckSpec(id: "intl-prostar", make: .international, model: "ProStar", type: .sleeperCab,
                  yearStart: 2007, yearEnd: 2017, baseMPG: 6.9, emptyWeight: 19500),
        TruckSpec(id: "intl-hx", make: .international, model: "HX", type: .dayCab,
                  yearStart: 2016, yearEnd: nil, baseMPG: 6.8, emptyWeight: 17500),

        // MARK: Western Star
        TruckSpec(id: "ws-5700xe", make: .westernStar, model: "5700XE", type: .sleeperCab,
                  yearStart: 2016, yearEnd: nil, baseMPG: 7.0, emptyWeight: 19500),
        TruckSpec(id: "ws-4900", make: .westernStar, model: "4900", type: .sleeperCab,
                  yearStart: 2008, yearEnd: nil, baseMPG: 6.5, emptyWeight: 20500),
        TruckSpec(id: "ws-4700", make: .westernStar, model: "4700", type: .dayCab,
                  yearStart: 2011, yearEnd: nil, baseMPG: 7.2, emptyWeight: 16500),
        TruckSpec(id: "ws-49x", make: .westernStar, model: "49X", type: .dayCab,
                  yearStart: 2020, yearEnd: nil, baseMPG: 6.8, emptyWeight: 18000),
    ]

    // MARK: - Query Methods

    static func makes() -> [TruckMake] {
        TruckMake.allCases
    }

    static func models(for make: TruckMake) -> [TruckSpec] {
        trucks.filter { $0.make == make }
    }

    static func models(for make: TruckMake, year: Int) -> [TruckSpec] {
        trucks.filter { $0.make == make && $0.isValidForYear(year) }
    }

    static func spec(id: String) -> TruckSpec? {
        trucks.first { $0.id == id }
    }

    static func spec(make: TruckMake, model: String) -> TruckSpec? {
        trucks.first { $0.make == make && $0.model == model }
    }
}

// MARK: - Custom Truck

struct CustomTruck: Codable, Equatable {
    var makeName: String
    var modelName: String
    var type: TruckType
    var baseMPG: Double
    var emptyWeight: Double

    static var `default`: CustomTruck {
        CustomTruck(makeName: "", modelName: "", type: .sleeperCab, baseMPG: 7.0, emptyWeight: 20000)
    }
}
