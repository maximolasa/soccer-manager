import SwiftUI

struct ContentView: View {
    @State private var viewModel = GameViewModel()

    var body: some View {
        Group {
            switch viewModel.currentScreen {
            case .mainMenu:
                MainMenuView(viewModel: viewModel)
            case .teamSelection:
                TeamSelectionView(viewModel: viewModel)
            case .dashboard:
                MainDashboardView(viewModel: viewModel)
            case .squad:
                SquadView(viewModel: viewModel)
            case .match:
                MatchView(viewModel: viewModel)
            case .matchResult:
                MatchResultView(viewModel: viewModel)
            case .transfers:
                TransferMarketView(viewModel: viewModel)
            case .calendar:
                CalendarView(viewModel: viewModel)
            case .standings:
                StandingsView(viewModel: viewModel)
            case .youthAcademy:
                YouthAcademyView(viewModel: viewModel)
            case .tactics:
                TacticsView(viewModel: viewModel)
            case .clubInfo:
                MainDashboardView(viewModel: viewModel)
            case .rivalSquad:
                RivalSquadView(viewModel: viewModel)
            case .managerStats:
                ManagerStatsView(viewModel: viewModel)
            case .mail:
                MailView(viewModel: viewModel)
            case .finance:
                FinanceView(viewModel: viewModel)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.initializeGame()
        }
    }
}
