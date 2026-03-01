import Foundation

struct SeasonObjective: Identifiable {
    let id = UUID()
    let description: String
    let type: ObjectiveType
    let target: Int               // e.g. finish position 3, or goals 40
    var achieved: Bool = false

    enum ObjectiveType {
        case leaguePosition       // Finish in top N
        case minPoints            // Get at least N points
        case cupRun               // Reach at least round N (1 = R16, 2 = QF, 3 = SF, 4 = Final, 5 = Win)
        case goalsScored          // Score at least N league goals
    }
}
