import Foundation

enum Formatting {
    static let time: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    static func glasses(_ value: Double) -> String {
        if value == floor(value) {
            return "\(Int(value)) glass\(value == 1 ? "" : "es")"
        }
        return String(format: "%.1f glasses", value)
    }

    static func mg(_ value: Double) -> String {
        "\(Int(value.rounded())) mg"
    }

    static func mg1(_ value: Double) -> String {
        String(format: "%.1f mg", value)
    }

    static var usesMetric: Bool {
        Locale.current.measurementSystem == .metric
    }

    static var weightUnit: UnitMass { usesMetric ? .kilograms : .pounds }
    static var waistUnit: UnitLength { usesMetric ? .centimeters : .inches }

    private static let measurementFormatter: MeasurementFormatter = {
        let f = MeasurementFormatter()
        f.unitOptions = [.providedUnit]
        f.unitStyle = .medium
        f.numberFormatter.maximumFractionDigits = 1
        f.numberFormatter.minimumFractionDigits = 1
        return f
    }()

    static func weight(kg: Double) -> String {
        let m = Measurement(value: kg, unit: UnitMass.kilograms).converted(to: weightUnit)
        return measurementFormatter.string(from: m)
    }

    static func waist(cm: Double) -> String {
        let m = Measurement(value: cm, unit: UnitLength.centimeters).converted(to: waistUnit)
        return measurementFormatter.string(from: m)
    }

    static func kg(fromDisplay value: Double) -> Double {
        Measurement(value: value, unit: weightUnit).converted(to: .kilograms).value
    }

    static func cm(fromDisplay value: Double) -> Double {
        Measurement(value: value, unit: waistUnit).converted(to: .centimeters).value
    }

    static func display(fromKg kg: Double) -> Double {
        Measurement(value: kg, unit: UnitMass.kilograms).converted(to: weightUnit).value
    }

    static func display(fromCm cm: Double) -> Double {
        Measurement(value: cm, unit: UnitLength.centimeters).converted(to: waistUnit).value
    }
}
