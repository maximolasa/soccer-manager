import SwiftUI

/// 2-step negotiation: 1) agree fee with selling club  2) agree contract with player
struct ClubNegotiationView: View {
    let player: Player
    @State var viewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss

    enum Step { case fee, wage, done }

    @State private var step: Step = .fee
    @State private var offeredFee: Double = 0
    @State private var feeResult: Bool? = nil       // nil = pending
    @State private var offeredWage: Int = 0
    @State private var offeredYears: Int = 3
    @State private var wageResult: Bool? = nil
    @State private var errorMsg: String?

    private var sellingClubName: String {
        if let cid = player.clubId { return viewModel.clubName(for: cid) }
        return "Club"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                Text(step == .fee ? "TRANSFER NEGOTIATION" : step == .wage ? "PERSONAL TERMS" : "DEAL COMPLETE")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white)
                    .tracking(2)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(Color(white: 0.08))

            // Player summary
            playerSummaryBar
                .background(Color(white: 0.06))

            Divider().background(Color.white.opacity(0.1))

            // Step content
            switch step {
            case .fee:  feeStep
            case .wage: wageStep
            case .done: doneStep
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.06, green: 0.07, blue: 0.09).ignoresSafeArea())
        .onAppear {
            offeredFee = Double(player.marketValue)
            offeredWage = player.wage
        }
    }

    // MARK: - Player Summary

    private var playerSummaryBar: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(ColorHelpers.statColor(player.overall).opacity(0.3))
                    .frame(width: 36, height: 36)
                Text("\(player.overall)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(player.fullName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                HStack(spacing: 4) {
                    Text(player.position.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.cyan)
                    Text("· Age \(player.age)")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("· \(sellingClubName)")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Value: \(viewModel.formatCurrency(player.marketValue))")
                    .font(.system(size: 9))
                    .foregroundStyle(.green)
                Text("Wage: \(viewModel.formatCurrency(player.wage))/wk")
                    .font(.system(size: 9))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Step 1: Fee Negotiation

    private var feeStep: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 4)

            // Budget info
            HStack {
                Label("Your Budget", systemImage: "banknote")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                Text(viewModel.formatCurrency(viewModel.selectedClub?.budget ?? 0))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 14)

            // Fee slider
            VStack(spacing: 4) {
                HStack {
                    Text("Transfer Fee Offer")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text(viewModel.formatCurrency(Int(offeredFee)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.green)
                }
                Slider(value: $offeredFee, in: feeRange, step: Double(feeSliderStep))
                    .tint(.green)
                HStack {
                    Text(viewModel.formatCurrency(Int(feeRange.lowerBound)))
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.3))
                    Spacer()
                    Text(viewModel.formatCurrency(Int(feeRange.upperBound)))
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 14)

            // Likelihood
            HStack {
                Text("Club acceptance")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                Text(feeAcceptanceLabel)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(feeAcceptanceColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(feeAcceptanceColor.opacity(0.06))
            .clipShape(.rect(cornerRadius: 6))
            .padding(.horizontal, 14)

            // Transfer-listed hint
            if player.isTransferListed {
                HStack(spacing: 4) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 9))
                    Text("Player is transfer-listed — club more willing to sell")
                        .font(.system(size: 9))
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 14)
            }

            // Result / error
            if let feeResult {
                resultBanner(accepted: feeResult, message: feeResult ? "Fee accepted by \(sellingClubName)!" : "\(sellingClubName) rejected your offer.")
                    .padding(.horizontal, 14)
            }
            if let errorMsg {
                Text(errorMsg)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 14)
            }

            Spacer(minLength: 4)

            // Buttons
            HStack(spacing: 10) {
                if feeResult == true {
                    actionButton("Negotiate Contract →", color: .cyan) {
                        step = .wage
                    }
                } else if feeResult == false {
                    actionButton("Revise Offer", color: .orange) {
                        feeResult = nil
                        errorMsg = nil
                    }
                } else {
                    actionButton("Submit Offer", color: .green) {
                        submitFeeOffer()
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
    }

    // MARK: - Step 2: Wage Negotiation

    private var wageStep: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 4)

            Text("Agreed fee: \(viewModel.formatCurrency(Int(offeredFee)))")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.green)
                .padding(.horizontal, 14)

            // Wage slider
            VStack(spacing: 4) {
                HStack {
                    Text("Offered Wage")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Text("\(viewModel.formatCurrency(offeredWage))/wk")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.orange)
                }
                Slider(
                    value: Binding(
                        get: { Double(offeredWage) },
                        set: { offeredWage = Int($0) }
                    ),
                    in: Double(wageMin)...Double(wageMax),
                    step: Double(wageSliderStep)
                )
                .tint(.orange)
                HStack {
                    Text(viewModel.formatCurrency(wageMin))
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.3))
                    Spacer()
                    Text(viewModel.formatCurrency(wageMax))
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .padding(.horizontal, 14)

            // Years stepper
            HStack {
                Text("Contract Length")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                HStack(spacing: 10) {
                    Button { if offeredYears > 1 { offeredYears -= 1 } } label: {
                        Image(systemName: "minus.circle.fill").font(.system(size: 18)).foregroundStyle(.white.opacity(0.4))
                    }.buttonStyle(.plain)
                    Text("\(offeredYears)yr")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40)
                    Button { if offeredYears < 5 { offeredYears += 1 } } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundStyle(.white.opacity(0.4))
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)

            // Likelihood
            HStack {
                Text("Player acceptance")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                Text(wageAcceptanceLabel)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(wageAcceptanceColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(wageAcceptanceColor.opacity(0.06))
            .clipShape(.rect(cornerRadius: 6))
            .padding(.horizontal, 14)

            if let wageResult {
                resultBanner(accepted: wageResult, message: wageResult ? "\(player.fullName) accepted the contract!" : "\(player.fullName) rejected your terms.")
                    .padding(.horizontal, 14)
            }
            if let errorMsg {
                Text(errorMsg)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 14)
            }

            Spacer(minLength: 4)

            HStack(spacing: 10) {
                if wageResult == true {
                    actionButton("Complete Transfer", color: .green) {
                        completeTransfer()
                    }
                } else if wageResult == false {
                    actionButton("Revise Terms", color: .orange) {
                        wageResult = nil
                        errorMsg = nil
                    }
                } else {
                    actionButton("Submit Terms", color: .cyan) {
                        submitWageOffer()
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
    }

    // MARK: - Done Step

    private var doneStep: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            Text("Transfer Complete!")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
            VStack(spacing: 4) {
                Text("Fee: \(viewModel.formatCurrency(Int(offeredFee)))")
                    .font(.system(size: 11))
                    .foregroundStyle(.green)
                Text("Wage: \(viewModel.formatCurrency(offeredWage))/wk · \(offeredYears)-year contract")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
            }
            Spacer()
            actionButton("Done", color: .green) {
                dismiss()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
    }

    // MARK: - Fee Logic

    private var feeRange: ClosedRange<Double> {
        let mv = Double(max(50_000, player.marketValue))
        return (mv * 0.3)...(mv * 2.5)
    }

    private var feeSliderStep: Int {
        max(10_000, player.marketValue / 40)
    }

    private var feeAcceptanceScore: Double {
        let ratio = offeredFee / Double(max(1, player.marketValue))
        var score = ratio
        // Transfer-listed: club is eager
        if player.isTransferListed { score += 0.3 }
        // Short contract: club has less leverage
        if player.contractYearsLeft <= 1 { score += 0.25 }
        else if player.contractYearsLeft <= 2 { score += 0.1 }
        // Long contract: club demands more
        if player.contractYearsLeft >= 4 { score -= 0.15 }
        return score
    }

    private var feeAcceptanceLabel: String {
        let s = feeAcceptanceScore
        if s >= 1.3 { return "Very Likely" }
        if s >= 1.0 { return "Likely" }
        if s >= 0.75 { return "Uncertain" }
        return "Unlikely"
    }

    private var feeAcceptanceColor: Color {
        let s = feeAcceptanceScore
        if s >= 1.3 { return .green }
        if s >= 1.0 { return .yellow }
        if s >= 0.75 { return .orange }
        return .red
    }

    private func submitFeeOffer() {
        let budget = viewModel.selectedClub?.budget ?? 0
        if Int(offeredFee) > budget {
            errorMsg = "Insufficient budget!"
            return
        }
        let score = feeAcceptanceScore
        let chance = min(0.95, max(0.05, (score - 0.4) / 1.0))
        let roll = Double.random(in: 0...1)
        feeResult = roll < chance
    }

    // MARK: - Wage Logic

    private var wageMin: Int { max(500, player.wage / 2) }
    private var wageMax: Int { player.wage * 3 }
    private var wageSliderStep: Int { max(500, player.wage / 20) }

    private var wageAcceptanceScore: Double {
        let ratio = Double(offeredWage) / Double(max(1, player.wage))
        let yearsFactor = player.age >= 30 ? 1.0 + Double(offeredYears) * 0.05 : 1.0 - Double(5 - offeredYears) * 0.03
        return ratio * yearsFactor
    }

    private var wageAcceptanceLabel: String {
        let s = wageAcceptanceScore
        if s >= 1.3 { return "Very Likely" }
        if s >= 1.0 { return "Likely" }
        if s >= 0.8 { return "Uncertain" }
        return "Unlikely"
    }

    private var wageAcceptanceColor: Color {
        let s = wageAcceptanceScore
        if s >= 1.3 { return .green }
        if s >= 1.0 { return .yellow }
        if s >= 0.8 { return .orange }
        return .red
    }

    private func submitWageOffer() {
        let score = wageAcceptanceScore
        let chance = min(0.95, max(0.05, (score - 0.5) / 1.0))
        let roll = Double.random(in: 0...1)
        wageResult = roll < chance
    }

    private func completeTransfer() {
        let success = viewModel.buyPlayerNegotiated(
            player,
            fee: Int(offeredFee),
            wage: offeredWage,
            years: offeredYears
        )
        if success {
            step = .done
        } else {
            errorMsg = "Transfer failed — check your budget."
        }
    }

    // MARK: - Helpers

    private func resultBanner(accepted: Bool, message: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: accepted ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(accepted ? .green : .red)
            Text(message)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(accepted ? .green : .red)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background((accepted ? Color.green : Color.red).opacity(0.08))
        .clipShape(.rect(cornerRadius: 6))
    }

    private func actionButton(_ label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color == .red ? .white : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(color)
                .clipShape(.rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
