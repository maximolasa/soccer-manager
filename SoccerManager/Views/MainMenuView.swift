import SwiftUI

struct MainMenuView: View {
    @State var viewModel: GameViewModel

    // Ambient animation
    @State private var glowPhase: Bool = false
    @State private var ballRotation: Double = 0

    var body: some View {
        HStack(spacing: 0) {
            // Left side — branding
            ZStack {
                pitchBackground
                    .opacity(0.04)
                brandingSide
            }
            .frame(maxWidth: .infinity)

            // Divider line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, Color.green.opacity(0.3), .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 1)

            // Right side — menu options
            menuSide
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.04, green: 0.06, blue: 0.09).ignoresSafeArea())
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                glowPhase = true
            }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                ballRotation = 360
            }
        }
    }

    // MARK: - Branding Side

    private var brandingSide: some View {
        VStack(spacing: 20) {
            Spacer()

            // Ball icon with glow
            ZStack {
                // Glow
                Circle()
                    .fill(Color.green.opacity(glowPhase ? 0.12 : 0.04))
                    .frame(width: 140, height: 140)
                    .blur(radius: 40)

                // Ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.green.opacity(0.6), .green.opacity(0.05), .green.opacity(0.3), .green.opacity(0.05), .green.opacity(0.6)],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(ballRotation))

                // Inner icon
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .green.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                    )
            }

            VStack(spacing: 6) {
                Text("SOCCER")
                    .font(.system(size: 34, weight: .black))
                    .tracking(8)
                    .foregroundStyle(.white)

                Text("MANAGER")
                    .font(.system(size: 34, weight: .black))
                    .tracking(8)
                    .foregroundStyle(
                        LinearGradient(colors: [.green, .green.opacity(0.7)], startPoint: .leading, endPoint: .trailing)
                    )
            }

            Text("Season 2025/26")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.3))
                .tracking(3)

            Spacer()
        }
    }

    // MARK: - Menu Side

    private var menuSide: some View {
        VStack(spacing: 10) {
            Spacer()

            // Main menu buttons
            menuButton(
                title: "New Career",
                subtitle: "Start a new managerial journey",
                icon: "plus.circle.fill",
                color: .green,
                isPrimary: true
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    viewModel.currentScreen = .teamSelection
                }
            }

            menuButton(
                title: "Continue Career",
                subtitle: "No saved career found",
                icon: "arrow.clockwise.circle.fill",
                color: .cyan,
                isDisabled: true
            ) { }

            menuButton(
                title: "Load Career",
                subtitle: "No saved career found",
                icon: "folder.circle.fill",
                color: .orange,
                isDisabled: true
            ) { }

            Spacer().frame(height: 8)

            // Secondary options
            Divider()
                .overlay(Color.white.opacity(0.06))
                .padding(.horizontal, 40)

            Spacer().frame(height: 8)

            menuButtonCompact(
                title: "Settings",
                icon: "gearshape.fill",
                color: .gray
            ) { }

            menuButtonCompact(
                title: "Language",
                icon: "globe",
                color: .gray
            ) { }

            menuButtonCompact(
                title: "About",
                icon: "info.circle",
                color: .gray
            ) { }

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Menu Buttons

    private func menuButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        isPrimary: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isDisabled ? color.opacity(0.3) : color)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isDisabled ? .white.opacity(0.25) : .white)

                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(isDisabled ? .white.opacity(0.12) : .white.opacity(0.4))
                }

                Spacer()

                if !isDisabled {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.3))
                }


            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isPrimary ? color.opacity(0.1) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isPrimary ? color.opacity(0.3) : Color.white.opacity(0.06),
                        lineWidth: isPrimary ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }

    private func menuButtonCompact(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color.opacity(0.5))
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.15))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.white.opacity(0.02))
            .clipShape(.rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pitch Background

    private var pitchBackground: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Center circle
                Circle()
                    .stroke(Color.green, lineWidth: 1)
                    .frame(width: h * 0.5, height: h * 0.5)
                    .position(x: w * 0.5, y: h * 0.5)

                // Center line
                Rectangle()
                    .fill(Color.green)
                    .frame(width: 1, height: h)
                    .position(x: w * 0.5, y: h * 0.5)

                // Outer border
                Rectangle()
                    .stroke(Color.green, lineWidth: 1)
                    .padding(20)
            }
        }
    }
}
