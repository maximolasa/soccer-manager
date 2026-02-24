import SwiftUI

struct MailView: View {
    @State var viewModel: GameViewModel
    @State private var selectedMail: MailMessage?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            headerBar

            HStack(spacing: 0) {
                // Left: Mail list
                mailList
                    .frame(maxWidth: .infinity)

                // Right: Mail detail
                mailDetail
                    .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.06, green: 0.08, blue: 0.1).ignoresSafeArea())
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
                Image(systemName: "envelope.fill")
                    .foregroundStyle(.orange)
                Text("INBOX")
                    .font(.headline)
                    .fontWeight(.black)
                    .foregroundStyle(.white)
                    .tracking(2)
                if viewModel.unreadMailCount > 0 {
                    Text("\(viewModel.unreadMailCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(.capsule)
                }
            }

            Spacer()

            // Mark all read
            if viewModel.unreadMailCount > 0 {
                Button {
                    for mail in viewModel.mailMessages {
                        mail.isRead = true
                    }
                } label: {
                    Text("Mark All Read")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.orange)
                }
            } else {
                Color.clear.frame(width: 80)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(white: 0.1))
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Mail List

    private var mailList: some View {
        ScrollView {
            if viewModel.mailMessages.isEmpty {
                VStack(spacing: 12) {
                    Spacer().frame(height: 60)
                    Image(systemName: "tray")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.1))
                    Text("No mail yet")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.3))
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.mailMessages) { mail in
                        mailRow(mail)
                    }
                }
            }
        }
        .background(Color(white: 0.05))
    }

    @ViewBuilder
    private func mailRow(_ mail: MailMessage) -> some View {
        Button {
            selectedMail = mail
            mail.isRead = true
        } label: {
            HStack(spacing: 10) {
                // Unread dot
                Circle()
                    .fill(mail.isRead ? Color.clear : Color.orange)
                    .frame(width: 7, height: 7)

                // Category icon
                Image(systemName: mail.category.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(categoryColor(mail.category))
                    .frame(width: 20)

                // Subject + date
                VStack(alignment: .leading, spacing: 2) {
                    Text(mail.subject)
                        .font(.system(size: 11, weight: mail.isRead ? .medium : .bold))
                        .foregroundStyle(mail.isRead ? .white.opacity(0.45) : .white)
                        .lineLimit(1)

                    Text(dateFormatter.string(from: mail.date))
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.3))
                }

                Spacer()

                // Category label
                Text(mail.category.rawValue)
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(categoryColor(mail.category).opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(categoryColor(mail.category).opacity(0.1))
                    .clipShape(.capsule)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                selectedMail?.id == mail.id
                    ? Color.orange.opacity(0.1)
                    : (mail.isRead ? Color.clear : Color.white.opacity(0.02))
            )
        }
        .buttonStyle(.plain)

        Divider().overlay(Color.white.opacity(0.06)).padding(.leading, 40)
    }

    // MARK: - Mail Detail

    private var mailDetail: some View {
        VStack {
            if let mail = selectedMail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(categoryColor(mail.category).opacity(0.2))
                                    .frame(width: 40, height: 40)
                                Image(systemName: mail.category.icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(categoryColor(mail.category))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(mail.subject)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)

                                HStack(spacing: 6) {
                                    Text(mail.category.rawValue)
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(categoryColor(mail.category))
                                    Text("•")
                                        .foregroundStyle(.white.opacity(0.2))
                                    Text(dateFormatter.string(from: mail.date))
                                        .font(.system(size: 9))
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                            }

                            Spacer()
                        }

                        Divider().overlay(Color.white.opacity(0.1))

                        // Body
                        Text(mail.body)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.8))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                    .padding(20)
                }
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "envelope.open")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.08))
                    Text("Select a mail to read")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.25))
                    Spacer()
                }
            }
        }
        .background(Color(white: 0.07))
    }

    // MARK: - Helpers

    private func categoryColor(_ category: MailCategory) -> Color {
        switch category {
        case .general:  return .gray
        case .transfer: return .orange
        case .injury:   return .red
        case .youth:    return .purple
        case .match:    return .green
        case .board:    return .blue
        }
    }
}
