import SwiftUI

enum CafeineXWhatsNew {
    static let completionKey = "cafeinex.whatsNew.pilot.completed"
}

struct WhatsNewView: View {
    let onContinue: () -> Void

    @State private var visibleRows = 0

    private let features = [
        Feature(
            title: "Sleep stages timeline",
            message: "See recorded sleep stages in a simple timeline alongside your recent context.",
            symbol: "moon.stars.fill",
            tint: CXTheme.healthAccent
        ),
        Feature(
            title: "Quick Add",
            message: "Log caffeine or nicotine in seconds from the top-right button.",
            symbol: "plus.circle.fill",
            tint: CXTheme.caffeineAccent
        ),
        Feature(
            title: "Cigarette intelligence",
            message: "Keep cigarette timing, patterns, and sleep-window context in one place.",
            symbol: "smoke.fill",
            tint: CXTheme.nicotineAccent
        ),
        Feature(
            title: "Local privacy",
            message: "Your entries stay on this device. Review or delete your data anytime.",
            symbol: "lock.shield.fill",
            tint: CXTheme.healthAccent
        ),
        Feature(
            title: "Apple Health integration",
            message: "Optionally import sleep and sync dietary caffeine with separate permissions.",
            symbol: "heart.fill",
            tint: CXTheme.healthAccent
        ),
    ]

    var body: some View {
        ZStack {
            CXBackgroundView()

            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(CXTheme.healthAccent)
                            .padding(.bottom, 4)

                        Text("WHAT'S NEW")
                            .font(.caption.weight(.bold))
                            .tracking(1.5)
                            .foregroundStyle(CXTheme.caffeineAccent)

                        Text("A clearer way to notice your day")
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .multilineTextAlignment(.center)

                        Text("Here are a few features to help you get more from CafeineX.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 10) {
                        ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                            featureRow(feature)
                                .opacity(index < visibleRows ? 1 : 0)
                                .offset(y: index < visibleRows ? 0 : 12)
                        }
                    }

                    Button(action: onContinue) {
                        Text("Continue to CafeineX")
                            .font(.headline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CXTheme.healthAccent)
                    .accessibilityIdentifier("whats-new-continue-button")
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 24)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityIdentifier("whats-new-screen")
        .task {
            for index in 1...features.count {
                try? await Task.sleep(for: .milliseconds(100))
                withAnimation(.easeOut(duration: 0.35)) {
                    visibleRows = index
                }
            }
        }
    }

    private func featureRow(_ feature: Feature) -> some View {
        HStack(spacing: 14) {
            Image(systemName: feature.symbol)
                .font(.title3.weight(.semibold))
                .foregroundStyle(feature.tint)
                .frame(width: 34, height: 34)
                .background(feature.tint.opacity(0.12), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(feature.title)
                    .font(.subheadline.weight(.semibold))
                Text(feature.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private struct Feature: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let symbol: String
        let tint: Color
    }
}
