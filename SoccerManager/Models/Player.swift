import Foundation

nonisolated struct PlayerStats: Codable, Sendable, Equatable {
    var overall: Int
    var offensive: Int
    var defensive: Int
    var physical: Int
}

nonisolated enum PlayerPosition: String, Codable, Sendable, CaseIterable, Identifiable {
    case goalkeeper = "GK"
    case centerBack = "CB"
    case leftBack = "LB"
    case rightBack = "RB"
    case defensiveMidfield = "CDM"
    case centralMidfield = "CM"
    case attackingMidfield = "CAM"
    case leftWing = "LW"
    case rightWing = "RW"
    case striker = "ST"

    var id: String { rawValue }

    var isDefender: Bool {
        self == .centerBack || self == .leftBack || self == .rightBack
    }

    var isMidfielder: Bool {
        self == .defensiveMidfield || self == .centralMidfield || self == .attackingMidfield
    }

    var isForward: Bool {
        self == .leftWing || self == .rightWing || self == .striker
    }

    var fullName: String {
        switch self {
        case .goalkeeper: return "Goalkeeper"
        case .centerBack: return "Center Back"
        case .leftBack: return "Left Back"
        case .rightBack: return "Right Back"
        case .defensiveMidfield: return "Def. Midfield"
        case .centralMidfield: return "Central Midfield"
        case .attackingMidfield: return "Att. Midfield"
        case .leftWing: return "Left Wing"
        case .rightWing: return "Right Wing"
        case .striker: return "Striker"
        }
    }
}

@Observable
class Player: Identifiable {
    let id: UUID
    var firstName: String
    var lastName: String
    var age: Int
    var position: PlayerPosition
    var stats: PlayerStats
    var wage: Int
    var marketValue: Int
    var clubId: UUID?
    var contractYearsLeft: Int
    var isOnLoan: Bool
    var loanedFromClubId: UUID?
    var morale: Int
    var isInjured: Bool
    var injuryWeeksLeft: Int
    var yellowCards: Int
    var redCards: Int
    var goals: Int
    var assists: Int
    var matchesPlayed: Int
    var potentialPeak: Int

    var fullName: String { "\(firstName) \(lastName)" }

    init(
        firstName: String,
        lastName: String,
        age: Int,
        position: PlayerPosition,
        stats: PlayerStats,
        wage: Int = 5000,
        marketValue: Int = 500000,
        clubId: UUID? = nil,
        contractYearsLeft: Int = 3,
        potentialPeak: Int = 0
    ) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.age = age
        self.position = position
        self.stats = stats
        self.wage = wage
        self.marketValue = marketValue
        self.clubId = clubId
        self.contractYearsLeft = contractYearsLeft
        self.isOnLoan = false
        self.loanedFromClubId = nil
        self.morale = 70
        self.isInjured = false
        self.injuryWeeksLeft = 0
        self.yellowCards = 0
        self.redCards = 0
        self.goals = 0
        self.assists = 0
        self.matchesPlayed = 0
        self.potentialPeak = potentialPeak > 0 ? potentialPeak : min(99, stats.overall + Int.random(in: 5...20))
    }

    func applyAgeProgression() {
        if age < 24 {
            let growthChance = Double.random(in: 0...1)
            if growthChance < 0.6 && stats.overall < potentialPeak {
                let growth = Int.random(in: 1...3)
                stats.overall = min(potentialPeak, stats.overall + growth)
                stats.offensive = min(99, stats.offensive + Int.random(in: 0...growth))
                stats.defensive = min(99, stats.defensive + Int.random(in: 0...growth))
                stats.physical = min(99, stats.physical + Int.random(in: 0...growth))
            }
        } else if age >= 32 {
            let declineChance = Double.random(in: 0...1)
            let ageFactor = Double(age - 31) * 0.15
            if declineChance < ageFactor {
                let decline = Int.random(in: 1...3)
                stats.overall = max(20, stats.overall - decline)
                stats.physical = max(15, stats.physical - Int.random(in: 1...decline + 1))
                stats.offensive = max(15, stats.offensive - Int.random(in: 0...decline))
                stats.defensive = max(15, stats.defensive - Int.random(in: 0...decline))
            }
        }
        marketValue = calculateMarketValue()
    }

    func calculateMarketValue() -> Int {
        let baseValue = stats.overall * stats.overall * 500
        let ageFactor: Double
        if age <= 23 { ageFactor = 1.5 }
        else if age <= 28 { ageFactor = 1.3 }
        else if age <= 31 { ageFactor = 1.0 }
        else if age <= 34 { ageFactor = 0.6 }
        else { ageFactor = 0.3 }
        return Int(Double(baseValue) * ageFactor)
    }
}
