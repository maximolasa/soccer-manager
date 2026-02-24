import Foundation

@Observable
class MailMessage: Identifiable {
    let id: UUID
    let date: Date
    let subject: String
    let body: String
    let category: MailCategory
    var isRead: Bool

    init(date: Date, subject: String, body: String, category: MailCategory = .general, isRead: Bool = false) {
        self.id = UUID()
        self.date = date
        self.subject = subject
        self.body = body
        self.category = category
        self.isRead = isRead
    }
}

nonisolated enum MailCategory: String, CaseIterable, Sendable {
    case general = "General"
    case transfer = "Transfer"
    case injury = "Injury"
    case youth = "Youth Academy"
    case match = "Match"
    case board = "Board"

    var icon: String {
        switch self {
        case .general:  return "envelope.fill"
        case .transfer: return "arrow.left.arrow.right"
        case .injury:   return "cross.case.fill"
        case .youth:    return "graduationcap.fill"
        case .match:    return "sportscourt.fill"
        case .board:    return "building.2.fill"
        }
    }
}
