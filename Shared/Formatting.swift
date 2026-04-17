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
}
