import SwiftUI

struct FinanceView: View {
    @State var viewModel: GameViewModel
    @State private var sliderValue: Double = 0.5

    /// Total pool: both are cash pools, combined 1:1
    private var totalPool: Double {
        guard let club = viewModel.selectedClub else { return 0 }
        return Double(club.budget) + Double(club.wageBudget)
    }

    /// Minimum wage budget = current weekly obligations (can't cut wages below actual spend)
    private var minWageBudget: Int {
        viewModel.totalWeeklyWages
    }

    /// Maximum slider position: can't push salary below minWageBudget
    private var maxSliderValue: Double {
        let total = totalPool
        guard total > 0 else { return 1.0 }
        return max(0, min(1.0, (total - Double(minWageBudget)) / total))
    }

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.08, blue: 0.1).ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar

                ScrollView {
                    VStack(spacing: 12) {
                        overviewSection
                        budgetAllocationSection
                        budgetBreakdownSection
                        wageListSection
                    }
                    .padding(16)
                }
            }
        }
        .onAppear {
            initSlider()
        }
    }

    private func initSlider() {
        guard let club = viewModel.selectedClub else { return }
        let total = Double(club.budget) + Double(club.wageBudget)
        guard total > 0 else { sliderValue = 0.5; return }
        sliderValue = min(maxSliderValue, Double(club.budget) / total)
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
                HStack(spacing: 0) {
                    statCard("Transfer Budget", viewModel.formatCurrency(club.budget), .cyan)
                    statCard("Salary Budget", viewModel.formatCurrency(club.wageBudget), salaryColor(club))
                    statCard("Weekly Wages", viewModel.formatCurrency(viewModel.totalWeeklyWages), .orange)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
    }

    // MARK: - Budget Allocation Slider

    private var budgetAllocationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("BUDGET ALLOCATION", icon: "slider.horizontal.3", color: .purple)

            HStack {
                Text("Drag to reallocate funds between transfer and salary pools")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
            }

            if let club = viewModel.selectedClub {
                let clampedSlider = min(sliderValue, maxSliderValue)
                let newTransfer = Int(totalPool * clampedSlider)
                let newSalary = max(minWageBudget, Int(totalPool * (1.0 - clampedSlider)))

                // Labels above bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TRANSFER")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.cyan)
                            .tracking(1)
                        Text(viewModel.formatCurrency(newTransfer))
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundStyle(.cyan)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("SALARY")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.orange)
                            .tracking(1)
                        Text(viewModel.formatCurrency(newSalary))
                            .font(.system(size: 18, weight: .black, design: .monospaced))
                            .foregroundStyle(.orange)
                    }
                }

                // The allocation bar
                GeometryReader { geo in
                    let barWidth = geo.size.width
                    let thumbX = barWidth * sliderValue

                    ZStack(alignment: .leading) {
                        // Background bar
                        HStack(spacing: 0) {
                            // Transfer side (left)
                            Rectangle()
                                .fill(Color.cyan.opacity(0.3))
                                .frame(width: max(0, thumbX))

                            // Salary side (right)
                            Rectangle()
                                .fill(Color.orange.opacity(0.3))
                        }
                        .frame(height: 32)
                        .clipShape(.rect(cornerRadius: 8))

                        // Thumb
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: 6, height: 40)
                            .shadow(color: .black.opacity(0.5), radius: 4)
                            .offset(x: max(0, min(barWidth - 6, thumbX - 3)))
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let newValue = max(0.0, min(maxSliderValue, value.location.x / barWidth))
                                        sliderValue = newValue
                                    }
                                    .onEnded { _ in
                                        applyAllocation()
                                    }
                            )
                    }
                }
                .frame(height: 40)

                // Percentage labels
                HStack {
                    Text("\(Int(sliderValue * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.cyan.opacity(0.6))
                    Spacer()
                    Text("\(Int((1.0 - sliderValue) * 100))%")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.orange.opacity(0.6))
                }

                // Apply button
                Button {
                    applyAllocation()
                } label: {
                    Text("Apply Allocation")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .clipShape(.rect(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                // Change indicator
                let transferDiff = newTransfer - club.budget
                let salaryDiff = newSalary - club.wageBudget
                if transferDiff != 0 || salaryDiff != 0 {
                    HStack {
                        Label(
                            "\(transferDiff >= 0 ? "+" : "")\(viewModel.formatCurrency(transferDiff))",
                            systemImage: transferDiff >= 0 ? "arrow.up.right" : "arrow.down.right"
                        )
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(transferDiff >= 0 ? .green : .red)

                        Spacer()

                        Label(
                            "\(salaryDiff >= 0 ? "+" : "")\(viewModel.formatCurrency(salaryDiff))",
                            systemImage: salaryDiff >= 0 ? "arrow.up.right" : "arrow.down.right"
                        )
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(salaryDiff >= 0 ? .green : .red)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(.rect(cornerRadius: 12))
    }

    private func applyAllocation() {
        guard let club = viewModel.selectedClub else { return }
        let clamped = min(sliderValue, maxSliderValue)
        let newTransfer = Int(totalPool * clamped)
        let newSalary = max(minWageBudget, Int(totalPool * (1.0 - clamped)))
        club.budget = newTransfer
        club.wageBudget = newSalary
    }

    // MARK: - Budget Breakdown

    private var budgetBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("SALARY STATUS", icon: "person.2.fill", color: .orange)

            if let club = viewModel.selectedClub {
                HStack(spacing: 0) {
                    statCard("Available/wk", viewModel.formatCurrency(viewModel.remainingSalaryBudget), viewModel.remainingSalaryBudget > 0 ? .green : .red)
                    statCard("Weeks Covered", weeksRemaining(club), weeksRemainingColor(club))
                    statCard("Squad Size", "\(viewModel.myPlayers.count)", .white)
                }

                // Budget health bar
                let wages = viewModel.totalWeeklyWages
                let budget = club.wageBudget
                let usageRatio = budget > 0 ? min(1.0, Double(wages) / Double(budget) * 10.0) : 1.0
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Wage Consumption")
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

    // MARK: - Helpers

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
