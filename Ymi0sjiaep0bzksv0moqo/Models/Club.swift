import Foundation
import SwiftUI

nonisolated enum AcademyUpgrade: String, CaseIterable, Sendable {
    case recruiting
    case quality
    case training
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
    var academyRecruitingLevel: Int
    var academyQualityLevel: Int
    var academyTrainingLevel: Int
    var leagueTitles: Int
    var cupWins: Int
    var primaryColor: String
    var secondaryColor: String
    var countryEmoji: String
    var mentality: String
    var tempo: String
    var pressing: String
    var playWidth: String

    var playersPerYear: Int { 1 + academyRecruitingLevel }
    var academyBaseQuality: Int { 30 + (academyQualityLevel * 8) }
    var trainingBoost: Double { 1.0 + Double(academyTrainingLevel) * 0.15 }

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
        self.academyRecruitingLevel = 1
        self.academyQualityLevel = 1
        self.academyTrainingLevel = 1
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

    func upgradeAcademy(_ type: AcademyUpgrade) -> Bool {
        let cost: Int
        let currentLevel: Int
        switch type {
        case .recruiting:
            currentLevel = academyRecruitingLevel
            cost = currentLevel * 2_000_000
        case .quality:
            currentLevel = academyQualityLevel
            cost = currentLevel * 3_000_000
        case .training:
            currentLevel = academyTrainingLevel
            cost = currentLevel * 2_500_000
        }
        guard currentLevel < 10, budget >= cost else { return false }
        budget -= cost
        switch type {
        case .recruiting: academyRecruitingLevel += 1
        case .quality: academyQualityLevel += 1
        case .training: academyTrainingLevel += 1
        }
        return true
    }
}
