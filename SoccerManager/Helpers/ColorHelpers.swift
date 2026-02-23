import SwiftUI

enum ColorHelpers {
    static func statColor(_ value: Int) -> Color {
        if value >= 85 { return .green }
        if value >= 70 { return .yellow }
        if value >= 55 { return .orange }
        return .red
    }

    static func positionColor(_ pos: PlayerPosition) -> Color {
        if pos == .goalkeeper { return .yellow }
        if pos.isDefender { return .blue }
        if pos.isMidfielder { return .green }
        return .red
    }
}
