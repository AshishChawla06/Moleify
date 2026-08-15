import SwiftUI

public struct UpdaterView: View {
    @EnvironmentObject private var updater: AutoUpdaterService
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto Updater (tw93/mole Releases)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.white.opacity(0.98))
                        Text("mo update • Check for official Mole releases on GitHub (https://github.com/tw93/mole)")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.75))
                    }
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await updater.checkForUpdates()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text(updater.isChecking ? "Checking..." : "Check for Updates")
                        }
                        .font(.headline.weight(.bold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#0284C7"))
                    .disabled(updater.isChecking)
                }
                
                // Current Version Info Card
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CURRENT INSTALLED ENGINE VERSION")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color.white.opacity(0.7))
                            Text("v\(updater.currentVersion) (Moleify Native)")
                                .font(.title2.weight(.bold).monospacedDigit())
                                .foregroundStyle(Color(hex: "#38BDF8"))
                        }
                        Spacer()
                        
                        if let release = updater.latestRelease {
                            GlassBadge(updater.isUpdateAvailable ? "New Release Available (\(release.tagName))" : "Up to Date (\(release.tagName))", color: updater.isUpdateAvailable ? Color(hex: "#F97316") : Color(hex: "#10B981"))
                        }
                    }
                }
                
                if !updater.errorMessage.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color(hex: "#F97316"))
                        Text(updater.errorMessage)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.white.opacity(0.9))
                        Spacer()
                    }
                    .padding(14)
                    .background(Color(hex: "#F97316").opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                }
                
                // Latest Release Card
                if let release = updater.latestRelease {
                    GlassCard {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(release.name.isEmpty ? release.tagName : release.name)
                                        .font(.title3.weight(.bold))
                                        .foregroundStyle(Color.white.opacity(0.95))
                                    Text("Published on GitHub: \(release.publishedAt)")
                                        .font(.caption)
                                        .foregroundStyle(Color.white.opacity(0.6))
                                }
                                Spacer()
                                
                                Button(action: {
                                    updater.openReleasePage()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "safari")
                                        Text("Open Release on GitHub")
                                    }
                                    .font(.headline.weight(.bold))
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color(hex: "#10B981"))
                            }
                            
                            Divider().background(Color.white.opacity(0.12))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Release Notes:")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color.white.opacity(0.7))
                                
                                Text(release.body)
                                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                                    .foregroundStyle(Color.white.opacity(0.85))
                                    .padding(12)
                                    .background(Color.black.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                } else {
                    GlassCard {
                        VStack(spacing: 12) {
                            Image(systemName: "arrow.down.circle")
                                .font(.system(size: 44))
                                .foregroundStyle(Color(hex: "#38BDF8"))
                            Text("Click 'Check for Updates' to query latest releases from tw93/mole.")
                                .font(.subheadline)
                                .foregroundStyle(Color.white.opacity(0.75))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
            }
            .padding(24)
        }
    }
}
