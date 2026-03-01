import Foundation
import SwiftUI

nonisolated enum AcademyFacility: String, CaseIterable, Sendable {
    case scouting = "Scouting"
    case coaching = "Coaching"
    case facilities = "Facilities"

    var icon: String {
        switch self {
        case .scouting:   return "binoculars.fill"
        case .coaching:   return "star.fill"
        case .facilities: return "building.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .scouting:   return .green
        case .coaching:   return .yellow
        case .facilities: return .cyan
        }
    }

    var description: String {
        switch self {
        case .scouting:   return "More prospects discovered each year"
        case .coaching:   return "Higher base quality of new prospects"
        case .facilities: return "Faster stat growth while in academy"
        }
    }

    /// Fixed upgrade costs: same for all clubs — significant investment
    static let upgradeCosts: [Int] = [20_000_000, 35_000_000, 50_000_000, 75_000_000]  // Lv1→2, 2→3, 3→4, 4→5

    /// Construction time in days for each upgrade level
    static let upgradeDays: [Int] = [14, 30, 45, 60]  // Lv1→2, 2→3, 3→4, 4→5
}

@Observable
class Club: Identifiable {
    let id: UUID
    var name: String
    var shortName: String
    var leagueId: UUID
    var rating: Int
    var budget: Int
    var wageBudget: Int
    var stadiumName: String
    var stadiumCapacity: Int
    var formation: String
    var academyScoutingLevel: Int
    var academyCoachingLevel: Int
    var academyFacilitiesLevel: Int
    var academyUpgradeInProgress: AcademyFacility?
    var academyUpgradeDaysLeft: Int = 0
    var leagueTitles: Int
    var cupWins: Int
    var primaryColor: String
    var secondaryColor: String
    var countryEmoji: String
    var mentality: String
    var tempo: String
    var pressing: String
    var playWidth: String

    /// True when a construction is in progress
    var isAcademyUpgrading: Bool { academyUpgradeInProgress != nil && academyUpgradeDaysLeft > 0 }

    // MARK: - Academy Computed Props

    /// How many prospects can be generated per spawn cycle (1-3)
    var academyProspectsPerCycle: Int { min(3, academyScoutingLevel) }

    /// Base OVR for spawned academy players
    var academyBaseOVR: Int { 25 + (academyCoachingLevel * 7) }

    /// Growth multiplier applied to academy training
    var academyGrowthMultiplier: Double { 0.6 + Double(academyFacilitiesLevel) * 0.2 }

    var primarySwiftUIColor: Color {
        Club.colorFromString(primaryColor)
    }

    var secondarySwiftUIColor: Color {
        Club.colorFromString(secondaryColor)
    }

    static func colorFromString(_ name: String) -> Color {
        switch name.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "white": return .white
        case "black": return Color(white: 0.15)
        case "navy": return Color(red: 0.0, green: 0.0, blue: 0.5)
        case "skyblue": return Color(red: 0.53, green: 0.81, blue: 0.92)
        case "claret", "maroon": return Color(red: 0.5, green: 0.0, blue: 0.13)
        case "cyan": return .cyan
        case "pink": return Color(red: 0.96, green: 0.46, blue: 0.64)
        case "gold": return Color(red: 0.85, green: 0.65, blue: 0.13)
        default: return .gray
        }
    }

    var totalWages: Int = 0

    init(
        name: String,
        shortName: String,
        leagueId: UUID,
        rating: Int,
        budget: Int,
        wageBudget: Int,
        stadiumName: String,
        stadiumCapacity: Int,
        formation: String = "4-4-2",
        primaryColor: String = "blue",
        secondaryColor: String = "white",
        countryEmoji: String = "🏴󠁧󠁢󠁥󠁮󠁧󠁿"
    ) {
        self.id = UUID()
        self.name = name
        self.shortName = shortName
        self.leagueId = leagueId
        self.rating = rating
        self.budget = budget
        self.wageBudget = wageBudget
        self.stadiumName = stadiumName
        self.stadiumCapacity = stadiumCapacity
        self.formation = formation
        self.academyScoutingLevel = 1
        self.academyCoachingLevel = 1
        self.academyFacilitiesLevel = 1
        self.leagueTitles = 0
        self.cupWins = 0
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.countryEmoji = countryEmoji
        self.mentality = "Balanced"
        self.tempo = "Normal"
        self.pressing = "Medium"
        self.playWidth = "Normal"
    }

    /// Set academy levels based on club rating
    func initAcademyLevels() {
        if rating >= 85 {
            academyScoutingLevel = 3
            academyCoachingLevel = 3
            academyFacilitiesLevel = 3
        } else if rating >= 70 {
            academyScoutingLevel = 2
            academyCoachingLevel = 2
            academyFacilitiesLevel = 2
        } else {
            academyScoutingLevel = 1
            academyCoachingLevel = 1
            academyFacilitiesLevel = 1
        }
    }

    /// Start an academy upgrade — pays cost and begins construction timer
    func upgradeAcademy(_ facility: AcademyFacility) -> Bool {
        guard !isAcademyUpgrading else { return false }  // one at a time

        let currentLevel: Int
        switch facility {
        case .scouting:   currentLevel = academyScoutingLevel
        case .coaching:   currentLevel = academyCoachingLevel
        case .facilities: currentLevel = academyFacilitiesLevel
        }

        guard currentLevel < 5 else { return false }
        let cost = AcademyFacility.upgradeCosts[currentLevel - 1]
        guard budget >= cost else { return false }

        budget -= cost
        academyUpgradeInProgress = facility
        academyUpgradeDaysLeft = AcademyFacility.upgradeDays[currentLevel - 1]
        return true
    }

    /// Called daily from advanceDay — ticks down the construction timer
    func tickAcademyUpgrade() {
        guard isAcademyUpgrading else { return }
        academyUpgradeDaysLeft -= 1
        if academyUpgradeDaysLeft <= 0 {
            completeAcademyUpgrade()
        }
    }

    /// Apply the level bump when construction finishes
    func completeAcademyUpgrade() {
        guard let facility = academyUpgradeInProgress else { return }
        switch facility {
        case .scouting:   academyScoutingLevel += 1
        case .coaching:   academyCoachingLevel += 1
        case .facilities: academyFacilitiesLevel += 1
        }
        academyUpgradeInProgress = nil
        academyUpgradeDaysLeft = 0
    }

    func academyUpgradeCost(_ facility: AcademyFacility) -> Int? {
        let currentLevel = academyLevel(for: facility)
        guard currentLevel < 5 else { return nil }
        return AcademyFacility.upgradeCosts[currentLevel - 1]
    }

    func academyUpgradeDuration(_ facility: AcademyFacility) -> Int? {
        let currentLevel = academyLevel(for: facility)
        guard currentLevel < 5 else { return nil }
        return AcademyFacility.upgradeDays[currentLevel - 1]
    }

    func academyLevel(for facility: AcademyFacility) -> Int {
        switch facility {
        case .scouting:   return academyScoutingLevel
        case .coaching:   return academyCoachingLevel
        case .facilities: return academyFacilitiesLevel
        }
    }
}
