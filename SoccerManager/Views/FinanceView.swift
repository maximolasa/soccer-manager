import SwiftUI

struct FinanceView: View {
    @State var viewModel: GameViewModel
    @State private var transferAmount: String = ""
    @State private var showingTransferToSalary: Bool = false
    @State private var showingSalaryToTransfer: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            ScrollView {
                VStack(spacing: 12) {
                    overviewSection
                    budgetBreakdownSection
                    wageListSection
                    budgetAllocationSection
                }
                .padding(16)
            }
        }
        .background(Color(red: 0.06, green: 0.08, blue: 0.1), ignoresSafeAreaEdges: .all)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button {
                viewModel.currentScreen = .dashboard
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.caption)
                .foregroundStyle(.green)
            }

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "banknote.fill")
                    .foregroundStyle(.green)
                Text("FINANCES")
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundStyle(.white)
                    .tracking(2)
            }

            Spacer()
            Color.clear.frame(width: 50)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(white: 0.1))
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Overview

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("FINANCIAL OVERVIEW", icon: "chart.bar.fill", color: .green)

            if let club = viewModel.selectedClub {
                let totalBudget = club.budget + club.wageBudget
                HStack(spacing: 0) {
                    statCard("Total Funds", viewModel.formatCurrency(totalBudget), .white)
                    statCard("Transfer Budget", viewModel.formatCurrency(club.budget), .cyan)
                    statCard("Salary Budget", viewModel.formatCurrency(club.wageBudget), salaryColor(club))
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
    }

    // MARK: - Budget Breakdown

    private var budgetBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("SALARY BREAKDOWN", icon: "person.2.fill", color: .orange)

            if let club = viewModel.selectedClub {
                HStack(spacing: 0) {
                    statCard("Weekly Wages", viewModel.formatCurrency(viewModel.totalWeeklyWages), .orange)
                    statCard("Salary Remaining", viewModel.formatCurrency(viewModel.remainingSalaryBudget), viewModel.remainingSalaryBudget > 0 ? .green : .red)
                    statCard("Weeks Covered", weeksRemaining(club), weeksRemainingColor(club))
                }

                // Budget health bar
                let usageRatio = club.wageBudget > 0 ? min(1.0, Double(viewModel.totalWeeklyWages) / Double(club.wageBudget) * 10.0) : 1.0
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Wage Usage")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                        Spacer()
                        Text("\(Int(usageRatio * 100))% of budget per 10 weeks")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(usageRatio > 0.8 ? Color.red : (usageRatio > 0.6 ? Color.orange : Color.green))
                                .frame(width: geo.size.width * usageRatio, height: 6)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
    }

    // MARK: - Wage List

    private var wageListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("WAGE BILL", icon: "list.bullet", color: .cyan)

            let squad = viewModel.myPlayers.sorted { $0.wage > $1.wage }

            if squad.isEmpty {
                Text("No players in squad")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            } else {
                // Header row
                HStack {
                    Text("Player")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Pos")
                        .frame(width: 30)
                    Text("OVR")
                        .frame(width: 30)
                    Text("Wage/wk")
                        .frame(width: 60, alignment: .trailing)
                }
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.bottom, 2)

                ForEach(squad) { player in
                    HStack {
                        Text(player.fullName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text(player.position.rawValue)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(width: 30)

                        Text("\(player.stats.overall)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(.green)
                            .frame(width: 30)

                        Text(viewModel.formatCurrency(player.wage))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.orange)
                            .frame(width: 60, alignment: .trailing)
                    }
                    .padding(.vertical, 2)
                }

                Divider().overlay(Color.white.opacity(0.1))

                HStack {
                    Text("TOTAL")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(viewModel.formatCurrency(viewModel.totalWeeklyWages) + "/wk")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
    }

    // MARK: - Budget Allocation

    private var budgetAllocationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("BUDGET ALLOCATION", icon: "arrow.left.arrow.right", color: .purple)

            Text("Transfer funds between your transfer and salary budgets. Conversion is 1:1.")
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.4))

            if let club = viewModel.selectedClub {
                // Quick transfer buttons
                VStack(spacing: 8) {
                    // Transfer → Salary
                    HStack(spacing: 8) {
                        Text("Transfer → Salary")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 110, alignment: .leading)

                        ForEach(quickAmounts(from: club.budget), id: \.self) { amount in
                            Button {
                                _ = viewModel.transferToSalary(amount: amount)
                            } label: {
                                Text(viewModel.formatCurrency(amount))
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.cyan)
                                    .clipShape(.rect(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()
                    }

                    // Salary → Transfer
                    HStack(spacing: 8) {
                        Text("Salary → Transfer")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .frame(width: 110, alignment: .leading)

                        ForEach(quickAmounts(from: club.wageBudget), id: \.self) { amount in
                            Button {
                                _ = viewModel.salaryToTransfer(amount: amount)
                            } label: {
                                Text(viewModel.formatCurrency(amount))
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.orange)
                                    .clipShape(.rect(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
    }

    // MARK: - Helpers

    private func quickAmounts(from available: Int) -> [Int] {
        let options = [1_000_000, 5_000_000, 10_000_000, 25_000_000]
        return options.filter { $0 <= available }
    }

    private func weeksRemaining(_ club: Club) -> String {
        let wages = viewModel.totalWeeklyWages
        guard wages > 0 else { return "∞" }
        let weeks = club.wageBudget / wages
        return "\(weeks)"
    }

    private func weeksRemainingColor(_ club: Club) -> Color {
        let wages = viewModel.totalWeeklyWages
        guard wages > 0 else { return .green }
        let weeks = club.wageBudget / wages
        if weeks > 20 { return .green }
        if weeks > 10 { return .yellow }
        return .red
    }

    private func salaryColor(_ club: Club) -> Color {
        if club.wageBudget < 0 { return .red }
        if viewModel.remainingSalaryBudget < 0 { return .orange }
        return .green
    }

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(color)
                .tracking(1)
        }
    }

    private func statCard(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
