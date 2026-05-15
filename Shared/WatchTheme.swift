import SwiftUI

enum WatchTheme {
    enum Color {
        static let water    = SwiftUI.Color(red: 0.12, green: 0.92, blue: 0.94) // #1EEAEF
        static let caffeine = SwiftUI.Color(red: 1.00, green: 0.62, blue: 0.04) // #FF9F0A
        static let fullness = SwiftUI.Color(red: 0.57, green: 0.91, blue: 0.16) // #92E82A
        static let weight   = SwiftUI.Color(red: 0.98, green: 0.07, blue: 0.31) // #FA114F
        static let waist    = SwiftUI.Color(red: 0.75, green: 0.35, blue: 0.95) // #BF5AF2
        static let track    = SwiftUI.Color.white.opacity(0.12)
    }

    enum Spacing {
        static let pageH: CGFloat = 6
        static let stack: CGFloat = 8
        static let chipGap: CGFloat = 6
    }

    enum Radius {
        static let chip: CGFloat = 14
        static let tile: CGFloat = 12
    }

    enum Stroke {
        static let heroRing: CGFloat = 10
        static let miniRing: CGFloat = 3
    }
}
